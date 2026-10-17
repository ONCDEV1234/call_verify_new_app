import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:flutter/services.dart';
import 'package:flutter/widgets.dart';
import 'package:get/get.dart';

import '../../../../core/route/app_routes.dart';

class CallLog extends GetxService with WidgetsBindingObserver {
  static const MethodChannel _methodChannel =
  MethodChannel('verify_call/call_tracking');

  static const EventChannel _eventChannel =
  EventChannel('verify_call/call_tracking_events');

  // MainActivity.kt must implement these MethodChannel methods:
  // makeCall, getPersistedCallState, and clearPersistedCallState.
  // The EventChannel should emit: connected, ended, and unanswered.

  StreamSubscription<dynamic>? _callStateSubscription;

  // Call state
  final isCallInProgress = false.obs;
  final isCallConnected = false.obs;
  final isCallEnded = false.obs;

  final currentResponseId = 0.obs;
  final currentPhoneNumber = ''.obs;

  final callDurationSeconds = 0.obs;
  final processDurationSeconds = 0.obs;

  final callStartAt = Rxn<DateTime>();
  final callEndAt = Rxn<DateTime>();
  final processStartedAt = Rxn<DateTime>();

  final errorMessage = ''.obs;

  Timer? _durationTimer;
  Timer? _processTimer;

  DateTime? _connectedAt;
  DateTime? _endedAt;

  bool _nativeTrackingAvailable = false;
  bool _postCallOpened = false;
  bool _recoveringNativeState = false;

  @override
  void onInit() {
    super.onInit();

    WidgetsBinding.instance.addObserver(this);
    _listenToNativeCallEvents();

    // Check whether Android retained a call session from before
    // Flutter started or was recreated.
    unawaited(_restorePersistedCallState());
  }

  // ---------------------------------------------------------------------------
  // Flutter lifecycle
  // ---------------------------------------------------------------------------

  @override
  void didChangeAppLifecycleState(AppLifecycleState state) {
    if (state == AppLifecycleState.resumed) {
      // The user may have returned from the system phone app, or Android may
      // have recreated our Flutter Activity/process.
      unawaited(_restorePersistedCallState());
    }
  }

  // ---------------------------------------------------------------------------
  // Native call event stream
  // ---------------------------------------------------------------------------

  void _listenToNativeCallEvents() {
    _callStateSubscription =
        _eventChannel.receiveBroadcastStream().listen(
              (dynamic event) {
            if (event is! Map) return;

            final eventName = event['event']?.toString();

            switch (eventName) {
              case 'connected':
                _handleCallConnected();
                break;

              case 'ended':
                _handleCallEnded();
                break;

              case 'unanswered':
                _handleCallUnanswered();
                break;
            }
          },
          onError: (Object error) {
            _nativeTrackingAvailable = false;

            if (kDebugMode) {
              debugPrint('[CallLog] Native tracking stream error: $error');
            }
          },
        );
  }

  // ---------------------------------------------------------------------------
  // Start a call
  // ---------------------------------------------------------------------------

  Future<bool> startCall({
    required int responseId,
    required String phoneNumber,
  }) async {
    if (isCallInProgress.value || _postCallOpened) {
      Get.snackbar(
        'Call in progress',
        'Finish the current call verification before starting another.',
      );
      return false;
    }

    final phone = phoneNumber.trim();

    if (responseId <= 0 || phone.isEmpty) {
      errorMessage.value = 'Invalid response ID or phone number.';
      return false;
    }

    _resetCallState();

    currentResponseId.value = responseId;
    currentPhoneNumber.value = phone;

    final now = DateTime.now();

    processStartedAt.value = now;
    processDurationSeconds.value = 0;

    // This timestamp is the call attempt time, not necessarily the time
    // the other party answered.
    isCallInProgress.value = true;
    _startProcessTimer();

    try {
      final launched = await _methodChannel.invokeMethod<bool>(
        'makeCall',
        {
          'response_id': responseId,
          'phone_number': phone,
        },
      );

      if (launched != true) {
        _stopProcessTimer();
        isCallInProgress.value = false;
        isCallConnected.value = false;
        isCallEnded.value = false;

        errorMessage.value =
        'Call could not be started. Check phone permissions and try again.';

        if (kDebugMode) {
          debugPrint('[CallLog] Native makeCall returned false.');
        }

        return false;
      }

      _nativeTrackingAvailable = true;

      if (kDebugMode) {
        debugPrint('[CallLog] Response ID: $responseId');
        debugPrint('[CallLog] Phone: $phone');
        debugPrint('[CallLog] Process started: ${processStartedAt.value}');
        debugPrint('[CallLog] Native tracking: $_nativeTrackingAvailable');
      }

      return true;
    } on MissingPluginException catch (e) {
      _stopProcessTimer();
      isCallInProgress.value = false;

      errorMessage.value =
      'Native call support is missing. Update MainActivity.kt and rebuild.';

      if (kDebugMode) {
        debugPrint('[CallLog] Native makeCall method is missing: $e');
      }

      return false;
    } on PlatformException catch (e) {
      _stopProcessTimer();
      isCallInProgress.value = false;
      errorMessage.value = e.message ?? 'Unable to start the call.';

      if (kDebugMode) {
        debugPrint('[CallLog] Native call error: ${e.code}: ${e.message}');
      }

      return false;
    } catch (e) {
      _stopProcessTimer();
      isCallInProgress.value = false;
      errorMessage.value = 'Unable to start call: $e';

      if (kDebugMode) {
        debugPrint('[CallLog] Start call error: $e');
      }

      return false;
    }
  }

  // ---------------------------------------------------------------------------
  // Restore call state saved by Android
  // ---------------------------------------------------------------------------

  Future<void> _restorePersistedCallState() async {
    if (_recoveringNativeState || _postCallOpened) return;

    _recoveringNativeState = true;

    try {
      final rawState =
      await _methodChannel.invokeMethod<dynamic>('getPersistedCallState');

      if (rawState is! Map) return;

      final state = Map<dynamic, dynamic>.from(rawState);

      final responseId = _asInt(state['response_id']);
      final phone = state['phone_number']?.toString().trim() ?? '';
      final status = state['status']?.toString().toLowerCase() ?? '';

      if (responseId <= 0 || phone.isEmpty) {
        if (kDebugMode) {
          debugPrint(
            '[CallLog] Saved native call state lacks response_id or phone. '
                'The native persistence code needs to save response_id.',
          );
        }
        return;
      }

      // Only open the form when Android says this saved call has ended.
      // A pending/connected call may still be in progress.
      if (status != 'ended') {
        if (status == 'pending' || status == 'connected') {
          currentResponseId.value = responseId;
          currentPhoneNumber.value = phone;
          isCallInProgress.value = true;
          isCallConnected.value = status == 'connected';

          final attemptTime = _dateFromMillis(state['attempt_time_ms']);
          processStartedAt.value = attemptTime ?? DateTime.now();

          if (_processTimer == null) {
            _startProcessTimer();
          }
        }

        return;
      }

      // If the live event already completed the call, don't process the
      // persisted copy a second time.
      if (isCallEnded.value) return;

      _durationTimer?.cancel();
      _processTimer?.cancel();

      currentResponseId.value = responseId;
      currentPhoneNumber.value = phone;

      final attemptTime = _dateFromMillis(state['attempt_time_ms']);
      final nativeStart = _dateFromMillis(state['call_start_ms']);
      final nativeEnd = _dateFromMillis(state['call_end_ms']);

      processStartedAt.value = attemptTime ?? DateTime.now();
      callStartAt.value = nativeStart;
      callEndAt.value = nativeEnd;

      _connectedAt = nativeStart;
      _endedAt = nativeEnd;

      isCallConnected.value =
          state['connected'] == true || nativeStart != null;

      isCallEnded.value = true;
      isCallInProgress.value = false;

      final savedDuration = _asInt(state['duration_seconds']);

      if (savedDuration > 0) {
        callDurationSeconds.value = savedDuration;
      } else if (nativeStart != null && nativeEnd != null) {
        callDurationSeconds.value =
            nativeEnd.difference(nativeStart).inSeconds.clamp(0, 1 << 31);
      } else {
        callDurationSeconds.value = 0;
      }

      _updateProcessDuration();
      _openPostCallForm();
    } on MissingPluginException {
      // This may happen before the native side is rebuilt with recovery APIs.
      if (kDebugMode) {
        debugPrint(
          '[CallLog] getPersistedCallState is not implemented in MainActivity.',
        );
      }
    } on PlatformException catch (e) {
      if (kDebugMode) {
        debugPrint('[CallLog] Could not restore native call state: $e');
      }
    } catch (e) {
      if (kDebugMode) {
        debugPrint('[CallLog] Restore call state error: $e');
      }
    } finally {
      _recoveringNativeState = false;
    }
  }

  int _asInt(dynamic value) {
    if (value is int) return value;
    if (value is num) return value.toInt();
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  DateTime? _dateFromMillis(dynamic value) {
    final millis = _asInt(value);
    if (millis <= 0) return null;

    try {
      return DateTime.fromMillisecondsSinceEpoch(millis);
    } catch (_) {
      return null;
    }
  }

  // ---------------------------------------------------------------------------
  // Call connected
  // ---------------------------------------------------------------------------

  void _handleCallConnected() {
    // If this event arrives before Flutter has restored its in-memory state,
    // ask Android for the persisted session instead of silently losing it.
    if (!isCallInProgress.value) {
      unawaited(_restorePersistedCallState());
      return;
    }
    if (isCallEnded.value || isCallConnected.value) return;

    _connectedAt = DateTime.now();

    callStartAt.value = _connectedAt;
    isCallConnected.value = true;

    _startConnectedDurationTimer();

    if (kDebugMode) {
      debugPrint('[CallLog] Call connected: $_connectedAt');
    }
  }

  // ---------------------------------------------------------------------------
  // Call ended / unanswered
  // ---------------------------------------------------------------------------

  void _handleCallEnded() {
    // Android may deliver this event after the Flutter process was recreated.
    // Recover the persisted session in that case.
    if (!isCallInProgress.value) {
      unawaited(_restorePersistedCallState());
      return;
    }
    if (isCallEnded.value) return;

    _endedAt = DateTime.now();
    callEndAt.value = _endedAt;

    if (isCallConnected.value && _connectedAt != null) {
      callDurationSeconds.value = _endedAt!
          .difference(_connectedAt!)
          .inSeconds
          .clamp(0, 1 << 31);
    } else {
      callDurationSeconds.value = 0;
    }

    _finishCall();
  }

  void _handleCallUnanswered() {
    if (!isCallInProgress.value) {
      unawaited(_restorePersistedCallState());
      return;
    }
    if (isCallEnded.value) return;

    callDurationSeconds.value = 0;

    _endedAt = DateTime.now();
    callEndAt.value = _endedAt;

    _finishCall();
  }

  void _finishCall() {
    _durationTimer?.cancel();

    isCallEnded.value = true;
    isCallInProgress.value = false;

    _updateProcessDuration();

    if (kDebugMode) {
      debugPrint(
        '[CallLog] Call duration: ${callDurationSeconds.value} seconds',
      );
      debugPrint('[CallLog] Call ended: ${callEndAt.value}');
    }

    _openPostCallForm();
  }

  // ---------------------------------------------------------------------------
  // Timers
  // ---------------------------------------------------------------------------

  void _startConnectedDurationTimer() {
    _durationTimer?.cancel();

    _durationTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) {
        final connectedAt = _connectedAt;

        if (connectedAt == null || !isCallConnected.value) return;

        callDurationSeconds.value =
            DateTime.now().difference(connectedAt).inSeconds;
      },
    );
  }

  void _startProcessTimer() {
    _processTimer?.cancel();

    _updateProcessDuration();

    _processTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => _updateProcessDuration(),
    );
  }

  void _updateProcessDuration() {
    final startedAt = processStartedAt.value;
    if (startedAt == null) return;

    final seconds = DateTime.now().difference(startedAt).inSeconds;

    processDurationSeconds.value = seconds < 0 ? 0 : seconds;
  }

  void _stopProcessTimer() {
    _processTimer?.cancel();
    _updateProcessDuration();
  }

  // ---------------------------------------------------------------------------
  // Open post-call form
  // ---------------------------------------------------------------------------

  void _openPostCallForm() {
    if (_postCallOpened) return;

    final attemptStartedAt = processStartedAt.value;

    if (attemptStartedAt == null) {
      errorMessage.value = 'Call attempt start time is missing.';
      return;
    }

    _postCallOpened = true;

    Get.toNamed(
      AppRoutes.POST_CALL,
      arguments: {
        'response_id': currentResponseId.value,
        'phone_dialed': currentPhoneNumber.value,
        'process_started_at': attemptStartedAt,
        'call_start_at': callStartAt.value,
        'call_end_at': callEndAt.value,
        'call_duration': callDurationSeconds.value,
      },
    )?.then((result) async {
      if (result == true) {
        _stopProcessTimer();

        // Clear Android's recovery session only after the post-call flow
        // reports successful submission.
        try {
          await _methodChannel.invokeMethod<void>(
            'clearPersistedCallState',
          );
        } on PlatformException catch (e) {
          if (kDebugMode) {
            debugPrint('[CallLog] Could not clear saved call state: $e');
          }
        } on MissingPluginException {
          if (kDebugMode) {
            debugPrint(
              '[CallLog] clearPersistedCallState is not implemented natively.',
            );
          }
        }

        _postCallOpened = false;
        isCallEnded.value = false;
        isCallConnected.value = false;
        currentResponseId.value = 0;
        currentPhoneNumber.value = '';
        callDurationSeconds.value = 0;
        callStartAt.value = null;
        callEndAt.value = null;
        processStartedAt.value = null;
        _connectedAt = null;
        _endedAt = null;
      } else {
        // Keep the native saved session. If the form was cancelled or the
        // app was interrupted, it can be restored when the app resumes.
        _postCallOpened = false;
      }
    });
  }

  // ---------------------------------------------------------------------------
  // Reset for next call
  // ---------------------------------------------------------------------------

  void _resetCallState() {
    _durationTimer?.cancel();
    _processTimer?.cancel();

    isCallInProgress.value = false;
    isCallConnected.value = false;
    isCallEnded.value = false;

    callDurationSeconds.value = 0;
    processDurationSeconds.value = 0;

    callStartAt.value = null;
    callEndAt.value = null;
    processStartedAt.value = null;

    _connectedAt = null;
    _endedAt = null;
    _postCallOpened = false;
    _nativeTrackingAvailable = false;

    errorMessage.value = '';
  }

  // ---------------------------------------------------------------------------
  // Cleanup
  // ---------------------------------------------------------------------------

  @override
  void onClose() {
    WidgetsBinding.instance.removeObserver(this);

    _durationTimer?.cancel();
    _processTimer?.cancel();
    _callStateSubscription?.cancel();

    super.onClose();
  }
}
