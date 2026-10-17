import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../call_log/call_log.dart';
import '../model/project_model.dart';

class ProjectDetailScreen extends StatelessWidget {
  const ProjectDetailScreen({super.key});

  // ── Colors ────────────────────────────────────────────────
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE2E2E2);

  static const Color _green = Color(0xFF16A34A);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _red = Color(0xFFDC2626);

  @override
  Widget build(BuildContext context) {
    // Survey arrives via Get.arguments
    final Survey? survey = Get.arguments as Survey?;

    if (survey == null) {
      return const Scaffold(
        backgroundColor: _bg,
        body: Center(child: Text('No survey data.')),
      );
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: Text(
          survey.surveyTitle.isEmpty ? 'Survey' : survey.surveyTitle,
          style: const TextStyle(fontSize: 16, fontWeight: FontWeight.w700),
          overflow: TextOverflow.ellipsis,
        ),
      ),
      body: SafeArea(
        child: SingleChildScrollView(
          key: UniqueKey(), // Reset scroll position when this screen rebuilds.
          padding: const EdgeInsets.fromLTRB(16, 16, 16, 24),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _buildSurveyHeader(survey),
              const SizedBox(height: 20),
              Row(
                children: [
                  const Text(
                    'Responses',
                    style: TextStyle(
                      fontSize: 15,
                      fontWeight: FontWeight.w700,
                      color: _textBlack,
                    ),
                  ),
                  const SizedBox(width: 8),
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 8,
                      vertical: 2,
                    ),
                    decoration: BoxDecoration(
                      color: _primaryRed.withOpacity(0.10),
                      borderRadius: BorderRadius.circular(20),
                    ),
                    child: Text(
                      '${survey.responses.length}',
                      style: const TextStyle(
                        fontSize: 11,
                        fontWeight: FontWeight.w700,
                        color: _primaryRed,
                      ),
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 12),
              if (survey.responses.isEmpty)
                _buildEmptyState()
              else
                ...survey.responses.map(
                      (r) => Padding(
                    padding: const EdgeInsets.only(bottom: 10),
                    child: _buildResponseCard(r),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }


  // SURVEY HEADER

  Widget _buildSurveyHeader(Survey s) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 5),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Container(
                width: 44,
                height: 44,
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.10),
                  borderRadius: BorderRadius.circular(12),
                ),
                child: const Icon(
                  Icons.assignment_rounded,
                  size: 22,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  s.surveyTitle.isEmpty ? 'Untitled' : s.surveyTitle,
                  style: const TextStyle(
                    fontSize: 16,
                    fontWeight: FontWeight.w700,
                    color: _textBlack,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 14),
          _infoLine('Survey ID', s.surveyId),
          if (s.mobileFieldName.isNotEmpty)
            _infoLine('Mobile field', s.mobileFieldName),
          _infoLine('Responses', '${s.responses.length}'),
          if (s.fields.isNotEmpty) ...[
            const SizedBox(height: 6),
            const Text(
              'Fields',
              style: TextStyle(
                fontSize: 11,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 6),
            Wrap(
              spacing: 6,
              runSpacing: 6,
              children: s.fields
                  .map(
                    (f) => Container(
                  padding: const EdgeInsets.symmetric(
                    horizontal: 8,
                    vertical: 3,
                  ),
                  decoration: BoxDecoration(
                    color: _bg,
                    borderRadius: BorderRadius.circular(20),
                    border: Border.all(color: _borderGrey, width: 1),
                  ),
                  child: Text(
                    f,
                    style: const TextStyle(
                      fontSize: 10,
                      color: _textGrey,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                ),
              )
                  .toList(),
            ),
          ],
        ],
      ),
    );
  }

  Widget _infoLine(String label, String value) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(
            width: 90,
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 11.5,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: const TextStyle(
                fontSize: 11.5,
                color: _textBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Future<void> _startCall(SurveyResponse response) async {
    final phone = response.phone.trim();

    if (phone.isEmpty) {
      Get.snackbar(
        'Phone number unavailable',
        'This response does not have a phone number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    // Ask for confirmation before starting the call.
    final confirmed = await Get.dialog<bool>(
      AlertDialog(
        shape: RoundedRectangleBorder(
          borderRadius: BorderRadius.circular(18),
        ),
        title: const Row(
          children: [
            Icon(Icons.phone_in_talk_rounded, color: _primaryRed),
            SizedBox(width: 10),
            Expanded(child: Text('Make a call?')),
          ],
        ),
        content: Text(
          'Do you want to call this number?\n\n$phone',
          style: const TextStyle(fontSize: 15, height: 1.4),
        ),
        actionsPadding: const EdgeInsets.fromLTRB(16, 0, 16, 14),
        actions: [
          OutlinedButton(
            onPressed: () => Get.back<bool>(result: false),
            style: OutlinedButton.styleFrom(
              foregroundColor: _textBlack,
              side: const BorderSide(color: _borderGrey),
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
            child: const Text('Cancel'),
          ),
          ElevatedButton.icon(
            onPressed: () => Get.back<bool>(result: true),
            icon: const Icon(Icons.call_rounded, size: 18),
            label: const Text('Make Call'),
            style: ElevatedButton.styleFrom(
              backgroundColor: _primaryRed,
              foregroundColor: Colors.white,
              elevation: 0,
              shape: RoundedRectangleBorder(
                borderRadius: BorderRadius.circular(10),
              ),
            ),
          ),
        ],
      ),
      barrierDismissible: false,
    );

    // Cancel or dismiss means no call is placed.
    if (confirmed != true) return;

    if (!Get.isRegistered<CallLog>()) {
      Get.snackbar(
        'Call service unavailable',
        'Call tracking has not been initialized. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    try {
      final callLog = Get.find<CallLog>();
      final started = await callLog.startCall(
        responseId: response.responseId,
        phoneNumber: phone,
      );

      if (!started) {
        Get.snackbar(
          'Unable to start call',
          'The call could not be started. Check phone-call permissions and try again.',
          snackPosition: SnackPosition.BOTTOM,
        );
      }
    } catch (e) {
      Get.snackbar(
        'Call error',
        'Unable to start this call. Please try again.',
        snackPosition: SnackPosition.BOTTOM,
      );
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RESPONSE CARD
  // ═══════════════════════════════════════════════════════════
  Widget _buildResponseCard(SurveyResponse r) {
    final hasPhone = r.phone.isNotEmpty;

    return Container(
      padding: const EdgeInsets.all(14),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          // ── Top row: phone + response id ─────────────────
          Row(
            children: [
              Container(
                width: 36,
                height: 36,
                decoration: BoxDecoration(
                  color: hasPhone
                      ? _primaryRed.withOpacity(0.10)
                      : _textGrey.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: Icon(
                  Icons.phone_rounded,
                  size: 17,
                  color: hasPhone ? _primaryRed : _textGrey,
                ),
              ),
              const SizedBox(width: 10),
              Expanded(
                child: InkWell(
                  onTap: hasPhone ? () => _startCall(r) : null,
                  borderRadius: BorderRadius.circular(6),
                  child: Padding(
                    padding: const EdgeInsets.symmetric(vertical: 8),
                    child: Row(
                      children: [
                        Expanded(
                          child: Text(
                            hasPhone ? r.phone : 'No phone number',
                            style: TextStyle(
                              fontSize: 13,
                              fontWeight: FontWeight.w700,
                              color: hasPhone ? _primaryRed : _textGrey,
                              fontStyle: hasPhone
                                  ? FontStyle.normal
                                  : FontStyle.italic,
                              decoration: hasPhone
                                  ? TextDecoration.underline
                                  : TextDecoration.none,
                            ),
                          ),
                        ),
                        if (hasPhone) ...[
                          const SizedBox(width: 6),
                          const Icon(
                            Icons.call_rounded,
                            size: 16,
                            color: _primaryRed,
                          ),
                        ],
                      ],
                    ),
                  ),
                ),
              ),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 3,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(20),
                  border: Border.all(color: _borderGrey, width: 1),
                ),
                child: Text(
                  '#${r.responseId}',
                  style: const TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w600,
                    color: _textGrey,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 12),

          // ── Answers ──────────────────────────────────────
          if (r.answers.isNotEmpty) ...[
            const Text(
              'Answers',
              style: TextStyle(
                fontSize: 11,
                color: _textGrey,
                fontWeight: FontWeight.w600,
              ),
            ),
            const SizedBox(height: 6),
            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: Column(
                children: r.answers.entries.map((e) {
                  return Padding(
                    padding: const EdgeInsets.symmetric(vertical: 2),
                    child: Row(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        SizedBox(
                          width: 100,
                          child: Text(
                            e.key,
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _textGrey,
                              fontWeight: FontWeight.w500,
                            ),
                          ),
                        ),
                        Expanded(
                          child: Text(
                            e.value?.toString() ?? '—',
                            style: const TextStyle(
                              fontSize: 11.5,
                              color: _textBlack,
                              fontWeight: FontWeight.w600,
                            ),
                          ),
                        ),
                      ],
                    ),
                  );
                }).toList(),
              ),
            ),
            const SizedBox(height: 10),
          ],

          // ── Created at ───────────────────────────────────
          Row(
            children: [
              const Icon(
                Icons.schedule_rounded,
                size: 13,
                color: _textGrey,
              ),
              const SizedBox(width: 4),
              Text(
                _formatDateTime(r.createdAt),
                style: const TextStyle(fontSize: 11, color: _textGrey),
              ),
            ],
          ),

          // ── Last call ────────────────────────────────────
          const SizedBox(height: 10),
          if (r.lastCall != null)
            _buildLastCall(r.lastCall!)
          else
            Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _bg,
                borderRadius: BorderRadius.circular(10),
              ),
              child: const Row(
                children: [
                  Icon(
                    Icons.call_missed_rounded,
                    size: 14,
                    color: _textGrey,
                  ),
                  SizedBox(width: 6),
                  Text(
                    'Never called',
                    style: TextStyle(
                      fontSize: 11.5,
                      color: _textGrey,
                      fontStyle: FontStyle.italic,
                    ),
                  ),
                ],
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildLastCall(LastCall lc) {
    final color = _statusColor(lc.status);

    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(10),
      decoration: BoxDecoration(
        color: color.withOpacity(0.06),
        borderRadius: BorderRadius.circular(10),
        border: Border.all(color: color.withOpacity(0.20), width: 1),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Row(
            children: [
              Icon(Icons.phone_in_talk_rounded, size: 14, color: color),
              const SizedBox(width: 6),
              const Text(
                'Last call',
                style: TextStyle(
                  fontSize: 11,
                  color: _textGrey,
                  fontWeight: FontWeight.w600,
                ),
              ),
              const Spacer(),
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 8,
                  vertical: 2,
                ),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.15),
                  borderRadius: BorderRadius.circular(20),
                ),
                child: Text(
                  lc.status.isEmpty ? 'Unknown' : lc.status,
                  style: TextStyle(
                    fontSize: 10,
                    fontWeight: FontWeight.w700,
                    color: color,
                  ),
                ),
              ),
            ],
          ),
          const SizedBox(height: 8),
          Row(
            children: [
              Expanded(
                child: _lastCallMeta(
                  Icons.person_outline_rounded,
                  lc.callerName.isEmpty ? 'Unknown' : lc.callerName,
                ),
              ),
              Expanded(
                child: _lastCallMeta(
                  Icons.timer_outlined,
                  '${lc.callDuration}s',
                ),
              ),
            ],
          ),
          const SizedBox(height: 4),
          _lastCallMeta(
            Icons.schedule_rounded,
            _formatDateTime(lc.createdAt),
          ),
        ],
      ),
    );
  }

  Widget _lastCallMeta(IconData icon, String text) {
    return Row(
      children: [
        Icon(icon, size: 12, color: _textGrey),
        const SizedBox(width: 4),
        Expanded(
          child: Text(
            text,
            overflow: TextOverflow.ellipsis,
            style: const TextStyle(
              fontSize: 11,
              color: _textBlack,
              fontWeight: FontWeight.w500,
            ),
          ),
        ),
      ],
    );
  }

  Color _statusColor(String status) {
    final s = status.toLowerCase();
    if (s.contains('busy')) return _amber;
    if (s.contains('answer') || s.contains('connect')) return _green;
    if (s.contains('miss') || s.contains('reject')) return _red;
    return _primaryRed;
  }

  // ═══════════════════════════════════════════════════════════
  // EMPTY
  // ═══════════════════════════════════════════════════════════
  Widget _buildEmptyState() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(24),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(16),
      ),
      child: const Column(
        children: [
          Icon(Icons.inbox_rounded, size: 40, color: _textGrey),
          SizedBox(height: 10),
          Text(
            'No responses in this survey.',
            style: TextStyle(fontSize: 13, color: _textGrey),
          ),
        ],
      ),
    );
  }

  // ═══════════════════════════════════════════════════════════
  // HELPERS
  // ═══════════════════════════════════════════════════════════
  String _formatDateTime(String iso) {
    if (iso.isEmpty) return '—';
    try {
      final dt = DateTime.parse(iso);
      const months = [
        'Jan', 'Feb', 'Mar', 'Apr', 'May', 'Jun',
        'Jul', 'Aug', 'Sep', 'Oct', 'Nov', 'Dec',
      ];
      return '${months[dt.month - 1]} ${dt.day}, ${dt.year} · '
          '${dt.hour.toString().padLeft(2, '0')}:'
          '${dt.minute.toString().padLeft(2, '0')}';
    } catch (_) {
      return iso;
    }
  }
}