
package com.example.calling_app

import android.Manifest
import android.content.Context
import android.content.pm.PackageManager
import android.database.Cursor
import android.net.Uri
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
        if (targetNumber.isBlank()) return null

        val projection = arrayOf(
            CallLog.Calls.NUMBER,
            CallLog.Calls.DATE,
            CallLog.Calls.DURATION,
            CallLog.Calls.TYPE
        )

        val selection = "${CallLog.Calls.TYPE} = ? AND ${CallLog.Calls.DATE} >= ?"
        val selectionArgs = arrayOf(
            CallLog.Calls.OUTGOING_TYPE.toString(),
            (attemptTimeMillis - lookBackMillis).toString()
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

            while (cursor.moveToNext()) {
                val loggedNumber =
                    cursor.getString(numberIndex).orEmpty()

                val dateMillis = cursor.getLong(dateIndex)
                val durationSeconds = cursor.getLong(durationIndex)
                val callType = cursor.getInt(typeIndex)

                // Avoid accidentally matching a different outgoing call.
                if (
                    numbersMatch(targetNumber, normalizeNumber(loggedNumber)) &&
                    dateMillis >= attemptTimeMillis - lookBackMillis &&
                    dateMillis <= System.currentTimeMillis() + 30_000L
                ) {
                    return CallLogMatch(
                        number = loggedNumber,
                        dateMillis = dateMillis,
                        durationSeconds = durationSeconds,
                        callType = callType
                    )
                }
            }

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
