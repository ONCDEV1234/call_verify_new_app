import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/post_call_controller.dart';

class PostCallFormScreen extends StatefulWidget {
  const PostCallFormScreen({super.key});

  @override
  State<PostCallFormScreen> createState() =>
      _PostCallFormScreenState();
}

class _PostCallFormScreenState
    extends State<PostCallFormScreen> {
  late final PostCallController controller;
  late final bool _ownsController;
  final TextEditingController remarksController =
  TextEditingController();

  @override
  void initState() {
    super.initState();

    // Reuse a controller if the route already registered one. Only remove
    // the controller here when this screen created it.
    _ownsController = !Get.isRegistered<PostCallController>();
    controller = _ownsController
        ? Get.put(PostCallController())
        : Get.find<PostCallController>();
  }

  @override
  void dispose() {
    remarksController.dispose();

    if (_ownsController && Get.isRegistered<PostCallController>()) {
      Get.delete<PostCallController>();
    }

    super.dispose();
  }

  String formatDuration(int seconds) {
    final duration = Duration(seconds: seconds);
    final minutes = duration.inMinutes;
    final remainingSeconds = duration.inSeconds % 60;

    return '${minutes.toString().padLeft(2, '0')}:'
        '${remainingSeconds.toString().padLeft(2, '0')}';
  }

  Future<void> handleSubmit() async {
    FocusScope.of(context).unfocus();

    // The controller also disables the submit button while submitting.
    // This local guard prevents rapid repeated taps before the UI rebuilds.
    if (controller.isSubmitting.value) return;

    final success = await controller.submitCallLog(
      remarks: remarksController.text.trim(),
    );

    if (!success || !mounted) return;

    // Show confirmation only after the API submission succeeds.
    await Get.dialog<void>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(16),
        ),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const Icon(
              Icons.check_circle,
              color: Colors.green,
              size: 58,
            ),
            const SizedBox(height: 12),
            const Text(
              'Submitted Successfully',
              textAlign: TextAlign.center,
              style: TextStyle(
                fontSize: 19,
                fontWeight: FontWeight.bold,
              ),
            ),
            const SizedBox(height: 8),
            Text(
              'Call log for ${controller.phoneDialed.value} '
                  'has been submitted successfully.',
              textAlign: TextAlign.center,
              style: const TextStyle(fontSize: 14),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back<void>(),
            child: const Text(
              'OK',
              style: TextStyle(
                color: Color(0xFFD50000),
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    // The dialog has closed; return to the existing project detail screen.
    if (mounted) {
      Get.back(result: true);
    }
  }

  @override
  Widget build(BuildContext context) {
    const primaryRed = Color(0xFFD50000);

    return Scaffold(
      backgroundColor: const Color(0xFFF7F7F7),
      appBar: AppBar(
        title: const Text(
          'Post Call Verification',
          style: TextStyle(
            fontWeight: FontWeight.w600,
            color: Colors.white,
          ),
        ),
        backgroundColor: primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
      ),
      body: SafeArea(
        child: Obx(
              () => Form(
            child: ListView(
              padding: const EdgeInsets.all(16),
              children: [
                // RESPONSE DETAILS
                _sectionCard(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Call Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailRow(
                        icon: Icons.assignment_outlined,
                        label: 'Response ID',
                        value: controller.responseId.value
                            .toString(),
                      ),
                      const Divider(height: 24),
                      _detailRow(
                        icon: Icons.phone_android,
                        label: 'Phone Number',
                        value: controller.phoneDialed.value,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // STATUS DROPDOWN
                _sectionCard(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Verification Result *',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      DropdownButtonFormField<String>(
                        value: controller.selectedStatus.value,
                        isExpanded: true,
                        decoration: InputDecoration(
                          hintText: 'Select call status',
                          prefixIcon:
                          const Icon(Icons.fact_check),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                          enabledBorder: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                            borderSide: const BorderSide(
                              color: Color(0xFFDDDDDD),
                            ),
                          ),
                        ),
                        items: PostCallController.statusOptions
                            .map(
                              (status) =>
                              DropdownMenuItem<String>(
                                value: status,
                                child: Text(
                                  status,
                                  maxLines: 2,
                                  overflow: TextOverflow.ellipsis,
                                ),
                              ),
                        )
                            .toList(),
                        onChanged: controller.setStatus,
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // REMARKS
                _sectionCard(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Remarks',
                        style: TextStyle(
                          fontSize: 16,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                      const SizedBox(height: 10),
                      TextField(
                        controller: remarksController,
                        maxLines: 4,
                        textCapitalization:
                        TextCapitalization.sentences,
                        decoration: InputDecoration(
                          hintText:
                          'Enter remarks (optional)',
                          alignLabelWithHint: true,
                          prefixIcon: const Padding(
                            padding: EdgeInsets.only(bottom: 58),
                            child: Icon(Icons.notes),
                          ),
                          filled: true,
                          fillColor: Colors.white,
                          border: OutlineInputBorder(
                            borderRadius:
                            BorderRadius.circular(12),
                          ),
                        ),
                      ),
                    ],
                  ),
                ),

                const SizedBox(height: 16),

                // DURATION DETAILS
                _sectionCard(
                  child: Column(
                    crossAxisAlignment:
                    CrossAxisAlignment.start,
                    children: [
                      const Text(
                        'Duration Details',
                        style: TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 16),
                      _detailRow(
                        icon: Icons.timer_outlined,
                        label: 'Connected Call Duration',
                        value: formatDuration(
                          controller.callDuration.value,
                        ),
                      ),
                      const Divider(height: 24),
                      _detailRow(
                        icon: Icons.hourglass_bottom,
                        label: 'Total Process Duration',
                        value: formatDuration(
                          controller
                              .elapsedProcessDuration.value,
                        ),
                      ),
                      const SizedBox(height: 8),
                      const Text(
                        'Call duration will be updated by the '
                            'separate call-tracking module.',
                        style: TextStyle(
                          fontSize: 12,
                          color: Colors.black54,
                        ),
                      ),
                    ],
                  ),
                ),

                if (controller.errorMessage.value.isNotEmpty) ...[
                  const SizedBox(height: 12),
                  Container(
                    padding: const EdgeInsets.all(12),
                    decoration: BoxDecoration(
                      color: Colors.red.shade50,
                      borderRadius: BorderRadius.circular(10),
                      border: Border.all(
                        color: Colors.red.shade200,
                      ),
                    ),
                    child: Text(
                      controller.errorMessage.value,
                      style: TextStyle(
                        color: Colors.red.shade800,
                      ),
                    ),
                  ),
                ],

                const SizedBox(height: 24),

                SizedBox(
                  height: 52,
                  child: ElevatedButton(
                    onPressed: controller.isSubmitting.value
                        ? null
                        : handleSubmit,
                    style: ElevatedButton.styleFrom(
                      backgroundColor: primaryRed,
                      foregroundColor: Colors.white,
                      disabledBackgroundColor:
                      Colors.grey.shade400,
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                    child: controller.isSubmitting.value
                        ? const SizedBox(
                      width: 24,
                      height: 24,
                      child: CircularProgressIndicator(
                        color: Colors.white,
                        strokeWidth: 2,
                      ),
                    )
                        : const Row(
                      mainAxisAlignment:
                      MainAxisAlignment.center,
                      children: [
                        Icon(Icons.cloud_upload_outlined),
                        SizedBox(width: 8),
                        Text(
                          'Submit Call Log',
                          style: TextStyle(
                            fontSize: 16,
                            fontWeight: FontWeight.bold,
                          ),
                        ),
                      ],
                    ),
                  ),
                ),

                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _sectionCard({required Widget child}) {
    return Container(
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: child,
    );
  }

  Widget _detailRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Row(
      children: [
        Icon(icon, color: const Color(0xFFD50000)),
        const SizedBox(width: 12),
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                label,
                style: const TextStyle(
                  fontSize: 12,
                  color: Colors.black54,
                ),
              ),
              const SizedBox(height: 4),
              Text(
                value.isEmpty ? 'Not available' : value,
                style: const TextStyle(
                  fontSize: 15,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ],
          ),
        ),
      ],
    );
  }
}
