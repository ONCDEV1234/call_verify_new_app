import 'dart:async';

import 'package:flutter/foundation.dart';
import 'package:get/get.dart';

import '../../../../core/network/api_provider.dart';
import '../model/post_call_model.dart';

class PostCallController extends GetxController {
  final ApiProvider _api = Get.find<ApiProvider>();

  static const String _endpoint =
      '${ApiProvider.apiPrefix}/calling-app/logs';

  static const List<String> statusOptions = [
    'Response',
    'Correct',
    'Positive',
    'Negative',
    'Not Response',
    'Not Decide',
    'Busy',
    'Call Not Pick',
    'Out of Coverage',
    'Switch Off',
    'No Incoming Call',
    'Invalid No',
    'Wrong No',
    'Calender Not Receive',
    'Area Wrong',
    'Meet Family Member',
    'mobile number is correct but not visited',
    'Meet but not ask question',
  ];

  final selectedStatus = RxnString();
  final isSubmitting = false.obs;
  final errorMessage = ''.obs;

  final responseId = 0.obs;
  final phoneDialed = ''.obs;

  final callDuration = 0.obs;
  final callStartAt = Rxn<DateTime>();
  final callEndAt = Rxn<DateTime>();

  late DateTime processStartedAt;

  final elapsedProcessDuration = 0.obs;

  Timer? _processTimer;

  bool _processTimerStarted = false;
  bool _processDurationFrozen = false;
  bool _submissionSucceeded = false;

  @override
  void onInit() {
    super.onInit();

    final args = Get.arguments;

    if (args is! Map) {
      errorMessage.value =
      'Missing call details. Please open this screen from a response.';
      return;
    }

    final id = args['response_id'] ?? args['responseId'];
    final phone = args['phone_dialed'] ?? args['phone'];

    responseId.value = _toInt(id);
    phoneDialed.value = phone?.toString() ?? '';

    processStartedAt =
        _parseDateTime(args['process_started_at']) ??
            DateTime.now();

    callStartAt.value = _parseDateTime(
      args['call_start_at'] ?? args['callStartAt'],
    );

    callEndAt.value = _parseDateTime(
      args['call_end_at'] ?? args['callEndAt'],
    );

    callDuration.value = _toInt(
      args['call_duration'] ?? args['callDuration'],
    );

    if (responseId.value <= 0) {
      errorMessage.value = 'Invalid response ID.';
    } else if (phoneDialed.value.trim().isEmpty) {
      errorMessage.value = 'Phone number is missing.';
    }

    _startProcessTimer();
  }

  DateTime? _parseDateTime(dynamic value) {
    if (value == null) return null;
    if (value is DateTime) return value;

    return DateTime.tryParse(value.toString());
  }

  int _toInt(dynamic value) {
    if (value is int) return value;
    return int.tryParse(value?.toString() ?? '') ?? 0;
  }

  void _startProcessTimer() {
    _processTimer?.cancel();

    _processTimerStarted = true;
    _processDurationFrozen = false;

    void updateElapsed() {
      if (_processDurationFrozen) return;

      final seconds =
          DateTime.now().difference(processStartedAt).inSeconds;

      elapsedProcessDuration.value =
      seconds < 0 ? 0 : seconds;
    }

    updateElapsed();

    _processTimer = Timer.periodic(
      const Duration(seconds: 1),
          (_) => updateElapsed(),
    );
  }

  void freezeProcessDuration() {
    if (!_processTimerStarted || _processDurationFrozen) return;

    final seconds =
        DateTime.now().difference(processStartedAt).inSeconds;

    elapsedProcessDuration.value =
    seconds < 0 ? 0 : seconds;

    _processDurationFrozen = true;
    _processTimer?.cancel();
    _processTimer = null;

    if (kDebugMode) {
      debugPrint(
        '[PostCall] Process duration frozen: '
            '${elapsedProcessDuration.value} seconds',
      );
    }
  }

  void updateCallDetails({
    required DateTime startedAt,
    required DateTime endedAt,
    required int durationSeconds,
  }) {
    callStartAt.value = startedAt;
    callEndAt.value = endedAt;
    callDuration.value =
    durationSeconds < 0 ? 0 : durationSeconds;
  }

  void setStatus(String? value) {
    selectedStatus.value = value;
    errorMessage.value = '';
  }

  Future<bool> submitCallLog({
    required String remarks,
  }) async {
    if (isSubmitting.value || _submissionSucceeded) {
      return false;
    }

    freezeProcessDuration();

    if (responseId.value <= 0) {
      errorMessage.value = 'Invalid response ID.';
      return false;
    }

    if (phoneDialed.value.trim().isEmpty) {
      errorMessage.value = 'Phone number is missing.';
      return false;
    }

    if (selectedStatus.value == null ||
        selectedStatus.value!.trim().isEmpty) {
      errorMessage.value = 'Please select a call status.';
      return false;
    }

    isSubmitting.value = true;
    errorMessage.value = '';

    try {
      final now = DateTime.now();

      final startedAt = callStartAt.value ?? processStartedAt;
      final endedAt = callEndAt.value ?? now;

      final frozenProcessDuration = elapsedProcessDuration.value;

      final model = PostCallModel(
        responseId: responseId.value,
        phoneDialed: phoneDialed.value.trim(),
        status: selectedStatus.value!,
        remarks: remarks.trim(),
        callDuration: callDuration.value,
        callStartAt: startedAt,
        callEndAt: endedAt,
        processDuration: frozenProcessDuration,
        source: 'mobile_app',
      );

      if (kDebugMode) {
        debugPrint('[PostCall] Endpoint: $_endpoint');
        debugPrint('[PostCall] Request: ${model.toJson()}');
      }

      final result = await _api.post(
        _endpoint,
        model.toJson(),
      );

      if (kDebugMode) {
        debugPrint('[PostCall] Response: $result');
      }

      _submissionSucceeded = true;
      return true;
    } on ApiException catch (e) {
      errorMessage.value = e.message;

      Get.snackbar(
        'Submission failed',
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 4),
      );

      return false;
    } on TimeoutException {
      errorMessage.value =
      'Request timed out. Please try again.';
      return false;
    } catch (e) {
      errorMessage.value = 'Unable to submit call log: $e';

      if (kDebugMode) {
        debugPrint('[PostCall] Error: $e');
      }

      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  @override
  void onClose() {
    _processTimer?.cancel();
    super.onClose();
  }
}