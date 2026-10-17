package com.example.calling_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.provider.CallLog
import android.telephony.PhoneNumberUtils
import android.util.Log
import androidx.core.content.ContextCompat

/**
 * Finds a recent outgoing call-log entry matching the app's call attempt.
 *
 * Returns null when permission is missing, no suitable record is found,
 * or the provider cannot be queried.
 */
object CallLogHelper {

    private const val TAG = "CallLogHelper"

    // Allow a small clock/launch delay, but never search several minutes back.
    // A five-minute lookback can incorrectly match a previous call to the same number.
    private const val ATTEMPT_TIME_TOLERANCE_MILLIS = 10_000L

    data class CallLogMatch(
        val number: String,
        val dateMillis: Long,
        val durationSeconds: Long,
        val callType: Int
    ) {
        val connected: Boolean
            get() = durationSeconds > 0L
    }

    fun findMatchingOutgoingCall(
        context: Context,
        phoneNumber: String,
        attemptTimeMillis: Long,
        lookBackMillis: Long = 5 * 60 * 1000L
    ): CallLogMatch? {
        val permissionGranted =
            ContextCompat.checkSelfPermission(
                context,
                Manifest.permission.READ_CALL_LOG
            ) == PackageManager.PERMISSION_GRANTED

        if (!permissionGranted) {
            Log.w(TAG, "READ_CALL_LOG permission not granted")
            return null
        }

        val targetNumber = normalizeNumber(phoneNumber)
        if (targetNumber.isBlank() || attemptTimeMillis <= 0L) return null

        // Ignore the old broad lookback for matching. Only accept a record whose
        // timestamp is close to this call attempt, so a previous call to the same
        // number cannot be reused for the current session.
        val earliestAllowedDate =
            attemptTimeMillis - minOf(ATTEMPT_TIME_TOLERANCE_MILLIS, lookBackMillis)

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.TYPE
        )

        val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(
            CallLog.Calls.OUTGOING_TYPE.toString(),
            earliestAllowedDate.toString()
        )

        val sortOrder = "${CallLog.Calls.DATE} DESC"
        var cursor: Cursor? = null

        return try {
            cursor = context.contentResolver.query(
                CallLog.Calls.CONTENT_URI,
                projection,
                selection,
                selectionArgs,
                sortOrder
            )

            if (cursor == null) return null

            val numberIndex = cursor.getColumnIndex(CallLog.Calls.NUMBER)
            val dateIndex = cursor.getColumnIndex(CallLog.Calls.DATE)
            val durationIndex = cursor.getColumnIndex(CallLog.Calls.DURATION)
            val typeIndex = cursor.getColumnIndex(CallLog.Calls.TYPE)

            if (
                numberIndex < 0 ||
                dateIndex < 0 ||
                durationIndex < 0 ||
                typeIndex < 0
            ) {
                return null
            }

            val now = System.currentTimeMillis()

            while (cursor.moveToNext()) {
                val loggedNumber = cursor.getString(numberIndex).orEmpty()
                val dateMillis = cursor.getLong(dateIndex)
                val durationSeconds = cursor.getLong(durationIndex)
                val callType = cursor.getInt(typeIndex)

                // Match the target number and the current attempt's time window.
                if (
                    numbersMatch(targetNumber, normalizeNumber(loggedNumber)) &&
                    dateMillis >= earliestAllowedDate &&
                    dateMillis <= now + 30_000L
                ) {
                    Log.d(
                        TAG,
                        "Matched current call: date=$dateMillis, " +
                                "duration=$durationSeconds, attempt=$attemptTimeMillis"
                    )
                    return CallLogMatch(
                        number = loggedNumber,
                        dateMillis = dateMillis,
                        durationSeconds = durationSeconds,
                        callType = callType
                    )
                }
            }

            Log.w(
                TAG,
                "No call-log match for current attempt. phone=$phoneNumber, " +
                        "attempt=$attemptTimeMillis, earliestAllowed=$earliestAllowedDate"
            )
            null
        } catch (e: SecurityException) {
            Log.e(TAG, "Call-log access denied", e)
            null
        } catch (e: Exception) {
            Log.e(TAG, "Call-log query failed", e)
            null
        } finally {
            cursor?.close()
        }
    }

    private fun normalizeNumber(number: String): String {
        return PhoneNumberUtils.normalizeNumber(number)
            .orEmpty()
            .filter { it.isDigit() }
    }

    private fun numbersMatch(
        expected: String,
        actual: String
    ): Boolean {
        if (expected.isBlank() || actual.isBlank()) return false
        if (expected == actual) return true

        // Allows local-vs-country-code representation differences.
        // Require at least the final 10 digits to match.
        val expectedTail = expected.takeLast(10)
        val actualTail = actual.takeLast(10)

        return expectedTail.length >= 10 &&
                actualTail.length >= 10 &&
                expectedTail == actualTail
    }
}
