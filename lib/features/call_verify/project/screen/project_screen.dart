
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../../../core/route/app_routes.dart';
import '../controller/project_controller.dart';
import '../model/project_model.dart';

class ProjectScreen extends StatelessWidget {
  const ProjectScreen({super.key});

  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    final String projectCode = (Get.arguments as String?) ?? '';

    if (projectCode.isEmpty) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        Get.back();
        Get.snackbar(
          'Project code required',
          'Please enter a project code to continue.',
          snackPosition: SnackPosition.BOTTOM,
        );
      });
      return const Scaffold(
        backgroundColor: _bg,
        body: SizedBox.shrink(),
      );
    }

    final c = Get.put(ProjectController(), tag: 'project');

    if (c.queue.value == null && !c.isLoading.value) {
      WidgetsBinding.instance.addPostFrameCallback((_) {
        c.loadQueue(projectCode);
      });
    }

    return Scaffold(
      backgroundColor: _bg,
      appBar: AppBar(
        backgroundColor: _primaryRed,
        foregroundColor: Colors.white,
        elevation: 0,
        title: const Text(
          'Surveys',
          style: TextStyle(fontSize: 17, fontWeight: FontWeight.w700),
        ),
      ),
      body: SafeArea(
        child: Obx(() {
          if (c.isLoading.value) {
            return const Center(
              child: CircularProgressIndicator(color: _primaryRed),
            );
          }

          final err = c.errorMessage.value;
          if (err != null && err.isNotEmpty) {
            return _buildError(err, c, projectCode);
          }

          if (c.project == null) {
            return const Center(
              child: Text(
                'No project loaded.',
                style: TextStyle(color: _textGrey),
              ),
            );
          }

          return RefreshIndicator(
            color: _primaryRed,
            onRefresh: c.refresh,
            child: SingleChildScrollView(
              physics: const AlwaysScrollableScrollPhysics(),
              padding: const EdgeInsets.fromLTRB(16, 18, 16, 24),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Row(
                    children: [
                      const Text(
                        'Surveys',
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
                          '${c.surveys.length}',
                          style: const TextStyle(
                            fontSize: 11,
                            fontWeight: FontWeight.w700,
                            color: _primaryRed,
                          ),
                        ),
                      ),
                    ],
                  ),
                  const SizedBox(height: 14),

                  if (c.surveys.isEmpty)
                    _buildEmptyState()
                  else
                    ...c.surveys.map(
                          (s) => Padding(
                        padding: const EdgeInsets.only(bottom: 10),
                        child: _buildSurveyCard(s),
                      ),
                    ),
                ],
              ),
            ),
          );
        }),
      ),
    );
  }


  // SURVEY CARD — name + response count only

  Widget _buildSurveyCard(Survey s) {
    final count = s.responses.length;

    return InkWell(
      onTap: () {
        Get.toNamed(
          AppRoutes.PROJECT_DETAIL,
          arguments: s,
        );
      },
      borderRadius: BorderRadius.circular(14),
      child: Container(
        padding: const EdgeInsets.symmetric(
          horizontal: 14,
          vertical: 14,
        ),
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14),
          boxShadow: [
            BoxShadow(
              color: Colors.black.withOpacity(0.08),
              blurRadius: 14,
              spreadRadius: 0,
              offset: const Offset(0, 4),
            ),
            BoxShadow(
              color: Colors.black.withOpacity(0.03),
              blurRadius: 4,
              spreadRadius: 0,
              offset: const Offset(0, 1),
            ),
          ],
        ),
        child: Row(
          children: [
            Container(
              width: 40,
              height: 40,
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.10),
                borderRadius: BorderRadius.circular(11),
              ),
              child: const Icon(
                Icons.assignment_rounded,
                size: 20,
                color: _primaryRed,
              ),
            ),
            const SizedBox(width: 12),

            Expanded(
              child: Text(
                s.surveyTitle.isEmpty ? 'Untitled' : s.surveyTitle,
                overflow: TextOverflow.ellipsis,
                style: const TextStyle(
                  fontSize: 14,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
            ),
            const SizedBox(width: 10),

            Container(
              padding: const EdgeInsets.symmetric(
                horizontal: 9,
                vertical: 5,
              ),
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.08),
                borderRadius: BorderRadius.circular(20),
              ),
              child: Row(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Icon(
                    Icons.people_alt_rounded,
                    size: 12,
                    color: _primaryRed,
                  ),
                  const SizedBox(width: 4),
                  Text(
                    '$count',
                    style: const TextStyle(
                      fontSize: 11.5,
                      fontWeight: FontWeight.w700,
                      color: _primaryRed,
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  // EMPTY / ERROR
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
            'No surveys in this project.',
            style: TextStyle(fontSize: 13, color: _textGrey),
          ),
        ],
      ),
    );
  }

  Widget _buildError(String msg, ProjectController c, String code) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Container(
              width: 70,
              height: 70,
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.10),
                shape: BoxShape.circle,
              ),
              child: const Icon(
                Icons.error_outline_rounded,
                size: 36,
                color: _primaryRed,
              ),
            ),
            const SizedBox(height: 16),
            Text(
              msg,
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 13,
                color: _textBlack,
                fontWeight: FontWeight.w500,
              ),
            ),
            const SizedBox(height: 18),
            OutlinedButton.icon(
              onPressed: () => c.loadQueue(code),
              icon: const Icon(Icons.refresh_rounded, size: 16),
              label: const Text('Retry'),
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryRed,
                side: const BorderSide(color: _primaryRed),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}