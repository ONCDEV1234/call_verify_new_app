package com.example.calling_app

import android.Manifest
import android.content.Intent
import android.content.SharedPreferences
import android.content.pm.PackageManager
import android.net.Uri
import android.os.Bundle
import android.os.Handler
import android.os.Looper
import android.telephony.PhoneStateListener
import android.telephony.TelephonyManager
import android.util.Log
import androidx.core.content.ContextCompat
import io.flutter.embedding.android.FlutterActivity
import io.flutter.embedding.engine.FlutterEngine
import io.flutter.plugin.common.EventChannel
import io.flutter.plugin.common.MethodCall
import io.flutter.plugin.common.MethodChannel
import org.json.JSONObject

class MainActivity : FlutterActivity() {

    companion object {
        private const val METHOD_CHANNEL = "verify_call/call_tracking"
        private const val EVENT_CHANNEL = "verify_call/call_tracking_events"
        private const val REQUEST_CALL_PERMISSIONS = 8401

        private const val PREFS_NAME = "verify_call_recovery"
        private const val KEY_SESSION = "pending_call_session"

        private const val TAG = "CallTracking"
        // Try to resolve the completed call quickly, then retry briefly if
        // Android has not written the call-log entry yet.
        private const val CALL_LOG_INITIAL_DELAY_MS = 200L
        private const val CALL_LOG_RETRY_DELAY_MS = 250L
        private const val CALL_LOG_MAX_WAIT_MS = 2500L
    }

    private val mainHandler = Handler(Looper.getMainLooper())

    private var eventSink: EventChannel.EventSink? = null
    private var telephonyManager: TelephonyManager? = null
    private var phoneStateListener: PhoneStateListener? = null

    private var lastCallState = TelephonyManager.CALL_STATE_IDLE
    private var trackingStarted = false

    private var pendingPhoneNumber: String? = null
    private var pendingResponseId: Int? = null
    private var pendingCallResult: MethodChannel.Result? = null

    private var callEndResolutionScheduled = false
    private var callEndResolutionStartedAt = 0L
    private val pendingEvents = mutableListOf<Map<String, String>>()

    private val recoveryPrefs: SharedPreferences
        get() = getSharedPreferences(PREFS_NAME, MODE_PRIVATE)

    override fun configureFlutterEngine(flutterEngine: FlutterEngine) {
        super.configureFlutterEngine(flutterEngine)

        MethodChannel(flutterEngine.dartExecutor.binaryMessenger, METHOD_CHANNEL)
            .setMethodCallHandler { call, result ->
                when (call.method) {
                    "startTracking" -> result.success(startCallTracking())
                    "makeCall" -> handleMakeCall(call, result)
                    "getPersistedCallState" -> result.success(readPersistedCallState())
                    "clearPersistedCallState" -> {
                        clearPersistedCallState()
                        CallForegroundService.stop(this)
                        result.success(true)
                    }
                    "stopTracking" -> {
                        stopCallTracking()
                        CallForegroundService.stop(this)
                        result.success(true)
                    }
                    else -> result.notImplemented()
                }
            }

        EventChannel(flutterEngine.dartExecutor.binaryMessenger, EVENT_CHANNEL)
            .setStreamHandler(object : EventChannel.StreamHandler {
                override fun onListen(
                    arguments: Any?,
                    events: EventChannel.EventSink?
                ) {
                    eventSink = events
                    pendingEvents.forEach { event -> eventSink?.success(event) }
                    pendingEvents.clear()
                }

                override fun onCancel(arguments: Any?) {
                    eventSink = null
                }
            })
    }

    override fun onResume() {
        super.onResume()
        if (hasPhoneStatePermission()) startCallTracking()
    }

    private fun handleMakeCall(call: MethodCall, result: MethodChannel.Result) {
        val phone = call.argument<String>("phone_number")?.trim().orEmpty()
        val responseId = call.argument<Int>("response_id")

        if (phone.isBlank()) {
            result.error("INVALID_PHONE", "A phone number is required.", null)
            return
        }
        if (responseId == null || responseId <= 0) {
            result.error("INVALID_RESPONSE_ID", "A valid response_id is required.", null)
            return
        }
        if (pendingCallResult != null) {
            result.error("CALL_PENDING", "A call request is already being processed.", null)
            return
        }

        pendingPhoneNumber = phone
        pendingResponseId = responseId
        pendingCallResult = result

        val requiredPermissions = arrayOf(
            Manifest.permission.CALL_PHONE,
            Manifest.permission.READ_PHONE_STATE,
            Manifest.permission.READ_CALL_LOG
        )
        val missingPermissions = requiredPermissions.filter {
            ContextCompat.checkSelfPermission(this, it) != PackageManager.PERMISSION_GRANTED
        }

        if (missingPermissions.isNotEmpty()) {
            requestPermissions(missingPermissions.toTypedArray(), REQUEST_CALL_PERMISSIONS)
        } else {
            placeDirectCall()
        }
    }

    @Deprecated("Deprecated Android callback retained for compatibility")
    override fun onRequestPermissionsResult(
        requestCode: Int,
        permissions: Array<out String>,
        grantResults: IntArray
    ) {
        super.onRequestPermissionsResult(requestCode, permissions, grantResults)
        if (requestCode != REQUEST_CALL_PERMISSIONS) return

        val callPermissionGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.CALL_PHONE) ==
                    PackageManager.PERMISSION_GRANTED
        val phoneStatePermissionGranted = hasPhoneStatePermission()
        val callLogPermissionGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) ==
                    PackageManager.PERMISSION_GRANTED

        if (!callPermissionGranted || !phoneStatePermissionGranted || !callLogPermissionGranted) {
            pendingCallResult?.error(
                "PERMISSION_DENIED",
                "Allow Phone, Phone State, and Call Log permissions to track answered-call duration accurately.",
                null
            )
            clearPendingCall()
            return
        }
        placeDirectCall()
    }

    private fun placeDirectCall() {
        val phone = pendingPhoneNumber
        val responseId = pendingResponseId
        val result = pendingCallResult
        if (phone.isNullOrBlank() || responseId == null || result == null) return

        try {
            if (!startCallTracking()) {
                result.error(
                    "TRACKING_UNAVAILABLE",
                    "Phone-state tracking could not be started. Check Phone State permission.",
                    null
                )
                clearPendingCall()
                return
            }

            // Save the call session before launching the phone app.
            persistCallAttempt(responseId, phone)

            // Requires a correctly configured service declaration/FGS type in the manifest.
            CallForegroundService.start(this)

            val intent = Intent(Intent.ACTION_CALL).apply {
                data = Uri.parse("tel:${Uri.encode(phone)}")
            }

            if (intent.resolveActivity(packageManager) == null) {
                markCallFailed("NO_CALL_HANDLER")
                CallForegroundService.stop(this)
                result.error("NO_CALL_HANDLER", "No app can place this phone call.", null)
                clearPendingCall()
                return
            }

            startActivity(intent)
            result.success(true)
            clearPendingCall(keepPhone = true)
        } catch (e: SecurityException) {
            markCallFailed("CALL_PERMISSION_DENIED")
            CallForegroundService.stop(this)
            result.error("CALL_PERMISSION_DENIED", "Permission to place calls was denied.", e.message)
            clearPendingCall()
        } catch (e: Exception) {
            markCallFailed("CALL_FAILED")
            CallForegroundService.stop(this)
            result.error("CALL_FAILED", e.message ?: "Could not start the call.", null)
            clearPendingCall()
        }
    }

    private fun hasPhoneStatePermission(): Boolean =
        ContextCompat.checkSelfPermission(
            this,
            Manifest.permission.READ_PHONE_STATE
        ) == PackageManager.PERMISSION_GRANTED

    private fun startCallTracking(): Boolean {
        if (trackingStarted) return true
        if (!hasPhoneStatePermission()) {
            Log.w(TAG, "READ_PHONE_STATE permission is not granted")
            return false
        }

        return try {
            val manager = getSystemService(TELEPHONY_SERVICE) as TelephonyManager
            telephonyManager = manager

            val listener = object : PhoneStateListener() {
                override fun onCallStateChanged(state: Int, phoneNumber: String?) {
                    val savedState = readPersistedCallState()
                    val previousState = lastCallState

                    when (state) {
                        TelephonyManager.CALL_STATE_OFFHOOK -> {
                            if (previousState != TelephonyManager.CALL_STATE_OFFHOOK) {
                                persistCallConnected()
                                sendCallEvent("connected")
                            }
                        }
                        TelephonyManager.CALL_STATE_IDLE -> {
                            val hasSavedSession = savedState != null &&
                                    savedState["status"] != "ended" &&
                                    savedState["status"] != "failed"
                            val callWasActive =
                                previousState != TelephonyManager.CALL_STATE_IDLE ||
                                        savedState?.get("connected") == true ||
                                        savedState?.get("status") == "connected"

                            if (hasSavedSession && callWasActive) scheduleCallEndResolution()
                        }
                        TelephonyManager.CALL_STATE_RINGING -> {
                            // This app initiates outgoing calls.
                        }
                    }
                    lastCallState = state
                }
            }

            phoneStateListener = listener
            @Suppress("DEPRECATION")
            manager.listen(listener, PhoneStateListener.LISTEN_CALL_STATE)
            trackingStarted = true
            true
        } catch (e: SecurityException) {
            Log.e(TAG, "Permission denied while starting call tracking", e)
            false
        } catch (e: Exception) {
            Log.e(TAG, "Could not start call tracking", e)
            false
        }
    }

    private fun scheduleCallEndResolution() {
        if (callEndResolutionScheduled) return

        callEndResolutionScheduled = true
        callEndResolutionStartedAt = System.currentTimeMillis()

        mainHandler.postDelayed({
            callEndResolutionScheduled = false
            resolveCallEnd()
        }, CALL_LOG_INITIAL_DELAY_MS)
    }

    private fun resolveCallEnd() {
        val session = readPersistedCallStateJson() ?: run {
            CallForegroundService.stop(this)
            return
        }

        val status = session.optString("status", "pending")
        if (status == "ended" || status == "failed") {
            CallForegroundService.stop(this)
            return
        }

        val phone = session.optString("phone_number", "")
        val attemptTime = session.optLong("attempt_time_ms", 0L)

        val callLogPermissionGranted =
            ContextCompat.checkSelfPermission(this, Manifest.permission.READ_CALL_LOG) ==
                    PackageManager.PERMISSION_GRANTED

        val match = if (callLogPermissionGranted) {
            CallLogHelper.findMatchingOutgoingCall(
                context = this,
                phoneNumber = phone,
                attemptTimeMillis = attemptTime
            )
        } else {
            null
        }

        if (match != null) {
            // A matching call-log entry is the source of truth. Its duration
            // excludes ringing time, so navigate as soon as this entry is available.
            if (match.durationSeconds > 0L) {
                val callEnd = match.dateMillis
                val callStart = callEnd - match.durationSeconds * 1000L
                persistCallEnded(
                    connected = true,
                    startMillis = callStart,
                    endMillis = callEnd,
                    durationSeconds = match.durationSeconds
                )
            } else {
                persistCallEnded(
                    connected = false,
                    startMillis = 0L,
                    endMillis = match.dateMillis,
                    durationSeconds = 0L
                )
            }

            sendCallEvent("ended")
            mainHandler.postDelayed({ CallForegroundService.stop(this) }, 10_000L)
            callEndResolutionStartedAt = 0L
            return
        }

        // Some Android devices write the call-log entry shortly after the call
        // state becomes IDLE. Retry briefly rather than immediately saving an
        // incorrect zero duration. Once the retry window expires, finish safely.
        val elapsed = System.currentTimeMillis() - callEndResolutionStartedAt
        if (elapsed < CALL_LOG_MAX_WAIT_MS) {
            callEndResolutionScheduled = true
            mainHandler.postDelayed({
                callEndResolutionScheduled = false
                resolveCallEnd()
            }, CALL_LOG_RETRY_DELAY_MS)
            return
        }

        persistCallEnded(
            connected = false,
            startMillis = 0L,
            endMillis = System.currentTimeMillis(),
            durationSeconds = 0L
        )
        sendCallEvent("ended")
        mainHandler.postDelayed({ CallForegroundService.stop(this) }, 10_000L)
        callEndResolutionStartedAt = 0L
    }

    private fun persistCallAttempt(responseId: Int, phone: String) {
        val now = System.currentTimeMillis()
        val session = JSONObject().apply {
            put("response_id", responseId)
            put("phone_number", phone)
            put("session_id", "${now}_$phone")
            put("status", "pending")
            put("connected", false)
            put("attempt_time_ms", now)
            put("call_start_ms", JSONObject.NULL)
            put("call_end_ms", JSONObject.NULL)
            put("duration_seconds", 0)
            put("failure_reason", JSONObject.NULL)
        }
        savePersistedCallState(session)
    }

    private fun persistCallConnected() {
        val session = readPersistedCallStateJson() ?: return
        val now = System.currentTimeMillis()
        val start = session.optLong("call_start_ms", 0L)
        session.put("status", "connected")
        session.put("connected", true)
        if (start <= 0L) session.put("call_start_ms", now)
        savePersistedCallState(session)
    }

    private fun persistCallEnded(
        connected: Boolean? = null,
        startMillis: Long? = null,
        endMillis: Long? = null,
        durationSeconds: Long? = null
    ) {
        val session = readPersistedCallStateJson() ?: return
        val end = endMillis ?: System.currentTimeMillis()
        val savedStart = session.optLong("call_start_ms", 0L)
        val start = startMillis ?: savedStart

        session.put("status", "ended")
        session.put("call_end_ms", end)
        if (connected != null) session.put("connected", connected)
        if (startMillis != null) {
            if (startMillis > 0L) {
                session.put("call_start_ms", startMillis)
            } else {
                session.put("call_start_ms", JSONObject.NULL)
            }
        } else if (start > 0L) {
            session.put("call_start_ms", start)
        }

        val duration = durationSeconds ?: if (start > 0L && end >= start) {
            (end - start) / 1000L
        } else {
            0L
        }
        session.put("duration_seconds", duration)
        savePersistedCallState(session)
    }

    private fun markCallFailed(reason: String) {
        val session = readPersistedCallStateJson() ?: return
        session.put("status", "failed")
        session.put("failure_reason", reason)
        session.put("call_end_ms", System.currentTimeMillis())
        savePersistedCallState(session)
    }

    private fun savePersistedCallState(session: JSONObject) {
        recoveryPrefs.edit().putString(KEY_SESSION, session.toString()).commit()
    }

    private fun readPersistedCallStateJson(): JSONObject? {
        val raw = recoveryPrefs.getString(KEY_SESSION, null) ?: return null
        return try {
            JSONObject(raw)
        } catch (e: Exception) {
            Log.e(TAG, "Saved call state was invalid", e)
            null
        }
    }

    private fun readPersistedCallState(): Map<String, Any?>? {
        val session = readPersistedCallStateJson() ?: return null
        return mapOf(
            "response_id" to session.optInt("response_id", 0),
            "phone_number" to session.optString("phone_number", ""),
            "session_id" to session.optString("session_id", ""),
            "status" to session.optString("status", "pending"),
            "connected" to session.optBoolean("connected", false),
            "attempt_time_ms" to session.optLong("attempt_time_ms", 0L),
            "call_start_ms" to session.optLong("call_start_ms", 0L),
            "call_end_ms" to session.optLong("call_end_ms", 0L),
            "duration_seconds" to session.optLong("duration_seconds", 0L),
            "failure_reason" to session.optString("failure_reason", "")
        )
    }

    private fun clearPersistedCallState() {
        recoveryPrefs.edit().remove(KEY_SESSION).commit()
    }

    private fun sendCallEvent(event: String) {
        runOnUiThread {
            val payload = mapOf("event" to event)
            val sink = eventSink
            if (sink != null) {
                sink.success(payload)
            } else {
                if (pendingEvents.size >= 8) pendingEvents.removeAt(0)
                pendingEvents.add(payload)
            }
        }
    }

    private fun clearPendingCall(keepPhone: Boolean = false) {
        pendingCallResult = null
        pendingResponseId = null
        if (!keepPhone) pendingPhoneNumber = null
    }

    private fun stopCallTracking() {
        try {
            phoneStateListener?.let { listener ->
                @Suppress("DEPRECATION")
                telephonyManager?.listen(listener, PhoneStateListener.LISTEN_NONE)
            }
        } catch (e: Exception) {
            Log.e(TAG, "Error stopping call tracking", e)
        }

        phoneStateListener = null
        telephonyManager = null
        trackingStarted = false
        lastCallState = TelephonyManager.CALL_STATE_IDLE
    }

    override fun onDestroy() {
        mainHandler.removeCallbacksAndMessages(null)
        stopCallTracking()
        super.onDestroy()
    }
}
