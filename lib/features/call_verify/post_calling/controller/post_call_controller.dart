
import 'dart:async';
import 'dart:io';

import 'package:file_picker/file_picker.dart';
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

  // =========================================================
  // OBSERVABLE STATE
  // =========================================================

  final selectedStatus = RxnString();

  final isSubmitting = false.obs;
  final isPickingAudio = false.obs;
  final errorMessage = ''.obs;

  final responseId = 0.obs;
  final phoneDialed = ''.obs;

  final callDuration = 0.obs;
  final callStartAt = Rxn<DateTime>();
  final callEndAt = Rxn<DateTime>();

  final elapsedProcessDuration = 0.obs;

  // =========================================================
  // AUDIO ATTACHMENT
  // =========================================================

  /// Selected audio file from device storage.
  final selectedAudioFile = Rxn<File>();

  /// Original audio filename for displaying in the UI.
  final selectedAudioName = RxnString();

  /// Select one audio file from device storage.
  Future<void> pickAudioFile() async {
    if (isPickingAudio.value || isSubmitting.value) return;

    try {
      isPickingAudio.value = true;
      errorMessage.value = '';

      final result = await FilePicker.platform.pickFiles(
        type: FileType.audio,
        allowMultiple: false,
      );

      if (result == null || result.files.isEmpty) {
        return;
      }

      final pickedFile = result.files.single;

      final filePath = pickedFile.path;

      if (filePath == null || filePath.trim().isEmpty) {
        errorMessage.value =
        'Unable to access the selected audio file.';
        return;
      }

      final audioFile = File(filePath);

      if (!await audioFile.exists()) {
        errorMessage.value =
        'Selected audio file does not exist.';
        return;
      }

      final fileSize = await audioFile.length();

      if (fileSize <= 0) {
        errorMessage.value =
        'Selected audio file is empty.';
        return;
      }

      selectedAudioFile.value = audioFile;
      selectedAudioName.value = pickedFile.name;

      if (kDebugMode) {
        debugPrint(
          '[PostCall] Audio selected: ${pickedFile.name}',
        );
        debugPrint(
          '[PostCall] Audio size: $fileSize bytes',
        );
      }
    } catch (e) {
      errorMessage.value =
      'Unable to select audio file: $e';

      if (kDebugMode) {
        debugPrint('[PostCall] Audio picker error: $e');
      }
    } finally {
      isPickingAudio.value = false;
    }
  }

  /// Remove the currently selected audio attachment.
  void removeAudioFile() {
    selectedAudioFile.value = null;
    selectedAudioName.value = null;

    errorMessage.value = '';

    if (kDebugMode) {
      debugPrint('[PostCall] Audio attachment removed');
    }
  }

  // =========================================================
  // PROCESS TIMER
  // =========================================================

  Timer? _processTimer;

  bool _processTimerStarted = false;
  bool _processDurationFrozen = false;
  bool _submissionSucceeded = false;

  late DateTime processStartedAt;

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

  // =========================================================
  // CALL DETAILS
  // =========================================================

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

  // =========================================================
  // STATUS
  // =========================================================

  void setStatus(String? value) {
    selectedStatus.value = value;
    errorMessage.value = '';
  }

  // =========================================================
  // SUBMIT CALL LOG
  // =========================================================

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

      final frozenProcessDuration =
          elapsedProcessDuration.value;

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
        debugPrint(
          '[PostCall] Request: ${model.toMultipartFields()}',
        );
        debugPrint(
          '[PostCall] Audio attached: '
              '${selectedAudioFile.value != null}',
        );
      }

      // Submit using multipart/form-data.
      // Audio attachment is optional.
      final result = await _api.postMultipart(
        _endpoint,
        model.toMultipartFields(),
        file: selectedAudioFile.value,
        fileField: 'file',
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
      errorMessage.value =
      'Unable to submit call log: $e';

      if (kDebugMode) {
        debugPrint('[PostCall] Error: $e');
      }

      return false;
    } finally {
      isSubmitting.value = false;
    }
  }

  // =========================================================
  // CLEANUP
  // =========================================================

  @override
  void onClose() {
    _processTimer?.cancel();
    super.onClose();
  }
}
