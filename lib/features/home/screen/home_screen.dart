import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/route/app_routes.dart';
import '../../dashboard/controller/dashboard_controller.dart';
import '../../dashboard/model/dashboard_model.dart';
import '../../login/controller/auth_service.dart';
import '../../widgets/project_id_dialog.dart';


class HomeScreen extends StatelessWidget {
  const HomeScreen({super.key});

  // ---------------- COLORS ----------------
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _lightRed = Color(0xFFE52B30);
  static const Color _bg = Color(0xFFFDFAFA);
  static const Color _textBlack = Color(0xFF1A1A1A);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE5E5E5);

  static const Color _green = Color(0xFF16A34A);
  static const Color _amber = Color(0xFFF59E0B);
  static const Color _blue = Color(0xFF2563EB);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final user = auth.currentUser.value;

    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'User';
    final mobile = user?.mobile ?? '';

    final DashboardController controller = Get.isRegistered<DashboardController>()
        ? Get.find<DashboardController>()
        : Get.put(DashboardController());

    if (controller.dashboard.value == null && !controller.isLoading.value) {
      controller.fetchDashboard();
    }

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: RefreshIndicator(
          onRefresh: () => controller.fetchDashboard(),
          color: _primaryRed,
          child: SingleChildScrollView(
            physics: const AlwaysScrollableScrollPhysics(),
            padding: EdgeInsets.zero,
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [

                _buildTopBanner(name, mobile),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: _buildVerifyCallCard(),
                ),

                SizedBox(height: 15.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Obx(() => _buildTodayOverview(controller)),
                ),

                SizedBox(height: 20.h),

                Padding(
                  padding: EdgeInsets.symmetric(horizontal: 16.w),
                  child: Obx(() => _buildRecentCalls(controller)),
                ),

                SizedBox(height: 24.h),
              ],
            ),
          ),
        ),
      ),
    );
  }

  Widget _buildTopBanner(String name, String mobile) {
    return SizedBox(
      width: double.infinity,
      height: 240.h,
      child: Stack(
        fit: StackFit.expand,
        children: [
          Image.asset(
            'assets/top_banner.png',
            fit: BoxFit.cover,
            alignment: Alignment.topCenter,
            errorBuilder: (context, error, stackTrace) {
              return Container(color: _primaryRed);
            },
          ),
          Positioned(
            top: 60.h,
            right: 8.w,
            child: Container(
              width: 40.w,
              height: 40.w,
              decoration: BoxDecoration(
                color: Colors.white,
                shape: BoxShape.circle,
                boxShadow: [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 8,
                    offset: const Offset(0, 3),
                  ),
                ],
              ),
              child: Stack(
                alignment: Alignment.center,
                children: [
                  Icon(
                    Icons.notifications_none_rounded,
                    color: _primaryRed,
                    size: 22.sp,
                  ),
                  Positioned(
                    top: 5.h,
                    right: 10.w,
                    child: Container(
                      width: 8.w,
                      height: 8.w,
                      decoration: const BoxDecoration(
                        color: _primaryRed,
                        shape: BoxShape.circle,
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ),
          Positioned(
            left: 20.w,
            top: 110.h,
            child: SizedBox(
              width: 175.w,
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    name,
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 20.sp,
                      fontWeight: FontWeight.w800,
                      color: Colors.black87,
                      height: 1.1,
                    ),
                  ),
                  SizedBox(height: 4.h),
                  Text(
                    mobile.isNotEmpty ? '+91 $mobile' : '+91 98765 43210',
                    maxLines: 1,
                    overflow: TextOverflow.ellipsis,
                    softWrap: false,
                    style: TextStyle(
                      fontSize: 15.sp,
                      fontWeight: FontWeight.w600,
                      color: Colors.red,
                    ),
                  ),
                  SizedBox(height: 1.h),
                  Container(
                    padding: EdgeInsets.symmetric(
                      horizontal: 10.w,
                      vertical: 5.h,
                    ),
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.25),
                      borderRadius: BorderRadius.circular(20.r),
                      border: Border.all(
                        color: Colors.white.withOpacity(0.4),
                        width: 1,
                      ),
                    ),
                    child: Row(
                      mainAxisSize: MainAxisSize.min,
                      children: [
                        Container(
                          width: 8.w,
                          height: 8.w,
                          decoration: const BoxDecoration(
                            color: _green,
                            shape: BoxShape.circle,
                          ),
                        ),
                        SizedBox(width: 6.w),
                        Text(
                          'Online',
                          style: TextStyle(
                            fontSize: 11.sp,
                            fontWeight: FontWeight.w700,
                            color: Colors.green,
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildVerifyCallCard() {
    return Container(
      width: double.infinity,
      height: 150.h,
      decoration: BoxDecoration(
        borderRadius: BorderRadius.circular(24.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 16,
            offset: const Offset(0, -10),
            spreadRadius: 0,
          ),
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, 6),
            spreadRadius: 0,
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(24.r),
        child: Stack(
          fit: StackFit.expand,
          children: [
            Image.asset(
              'assets/top_card.png',
              fit: BoxFit.cover,
              alignment: Alignment.centerLeft,
              errorBuilder: (context, error, stackTrace) {
                return Container(color: Colors.white);
              },
            ),
            Positioned(
              right: 14.w,
              top: 0,
              bottom: 0,
              child: Row(
                children: [
                  SizedBox(
                    width: 135.w,
                    child: Column(
                      mainAxisAlignment: MainAxisAlignment.center,
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Verify Call',
                          style: TextStyle(
                            fontSize: 22.sp,
                            fontWeight: FontWeight.w800,
                            color: const Color(0xFF1A1A1A),
                          ),
                        ),
                        SizedBox(height: 6.h),
                        Text(
                          'Verify survey calls\nand track responses',
                          style: TextStyle(
                            fontSize: 13.sp,
                            height: 1.4,
                            color: const Color(0xFF666666),
                            fontWeight: FontWeight.w500,
                          ),
                        ),
                      ],
                    ),
                  ),
                  SizedBox(width: 10.w),
                  GestureDetector(
                    onTap: () async {
                      final code = await ProjectIdDialog.show();
                      if (code == null || code.trim().isEmpty) return;
                      Get.toNamed(
                        AppRoutes.PROJECT,
                        arguments: code.trim(),
                      );
                    },
                    child: Container(
                      width: 52.w,
                      height: 52.w,
                      decoration: BoxDecoration(
                        color: _primaryRed,
                        shape: BoxShape.circle,
                        boxShadow: [
                          BoxShadow(
                            color: _primaryRed.withOpacity(0.35),
                            blurRadius: 12,
                            offset: const Offset(0, 5),
                          ),
                        ],
                      ),
                      child: Icon(
                        Icons.arrow_forward_rounded,
                        color: Colors.white,
                        size: 24.sp,
                      ),
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

  Widget _buildTodayOverview(DashboardController controller) {
    if (controller.isLoading.value) {
      return _buildLoaderCard(height: 200.h);
    }

    if (controller.errorMessage.value.isNotEmpty) {
      return _buildErrorCard(
        message: controller.errorMessage.value,
        onRetry: () => controller.fetchDashboard(),
      );
    }

    final data = controller.dashboard.value;
    if (data == null) {
      return const SizedBox.shrink();
    }

    final total = data.totalCalls;
    final accepted = data.acceptedCalls;
    final rejected = data.rejectedCalls;

    final totalProgress = 1.0;
    final acceptedProgress = total == 0 ? 0.0 : accepted / total;
    final rejectedProgress = total == 0 ? 0.0 : rejected / total;

    // Filter label
    String filterLabel = 'Today';
    if (controller.filterType.value == DashboardFilterType.date) {
      final d = controller.selectedDate.value;
      filterLabel = '${d.day}/${d.month}/${d.year}';
    } else if (controller.filterType.value == DashboardFilterType.range) {
      filterLabel = 'Range';
    } else {
      filterLabel = controller.selectedDay.value == 'today' ? 'Today' : 'Yesterday';
    }

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  "Today's Overview",
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _textBlack,
                  ),
                ),
              ),
              Container(
                padding: EdgeInsets.symmetric(
                  horizontal: 10.w,
                  vertical: 6.h,
                ),
                decoration: BoxDecoration(
                  color: _bg,
                  borderRadius: BorderRadius.circular(20.r),
                ),
                child: Row(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Icon(
                      Icons.calendar_today_rounded,
                      size: 13.sp,
                      color: _textGrey,
                    ),
                    SizedBox(width: 5.w),
                    Text(
                      filterLabel,
                      style: TextStyle(
                        fontSize: 12.sp,
                        fontWeight: FontWeight.w600,
                        color: _textGrey,
                      ),
                    ),
                    SizedBox(width: 4.w),
                    Icon(
                      Icons.keyboard_arrow_down_rounded,
                      size: 16.sp,
                      color: _textGrey,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 20.h),
          Row(
            children: [
              Expanded(
                child: _buildCircularStat(
                  value: total,
                  label: 'Total',
                  color: _primaryRed,
                  progress: totalProgress,
                ),
              ),
              Expanded(
                child: _buildCircularStat(
                  value: accepted,
                  label: 'Received',
                  color: _green,
                  progress: acceptedProgress,
                ),
              ),
              Expanded(
                child: _buildCircularStat(
                  value: rejected,
                  label: 'Rejected',
                  color: _primaryRed,
                  progress: rejectedProgress,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }

  Widget _buildCircularStat({
    required int value,
    required String label,
    required Color color,
    required double progress,
  }) {
    return Column(
      children: [
        SizedBox(
          width: 84.w,
          height: 84.w,
          child: Stack(
            alignment: Alignment.center,
            children: [
              SizedBox(
                width: 84.w,
                height: 84.w,
                child: CircularProgressIndicator(
                  value: 1,
                  strokeWidth: 7.w,
                  valueColor: AlwaysStoppedAnimation<Color>(
                    color.withOpacity(0.12),
                  ),
                ),
              ),
              SizedBox(
                width: 84.w,
                height: 84.w,
                child: CircularProgressIndicator(
                  value: progress,
                  strokeWidth: 7.w,
                  strokeCap: StrokeCap.round,
                  valueColor: AlwaysStoppedAnimation<Color>(color),
                ),
              ),
              Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  Text(
                    '$value',
                    style: TextStyle(
                      fontSize: 22.sp,
                      fontWeight: FontWeight.w800,
                      color: _textBlack,
                      height: 1,
                    ),
                  ),
                  SizedBox(height: 2.h),
                  Text(
                    label,
                    style: TextStyle(
                      fontSize: 11.sp,
                      fontWeight: FontWeight.w500,
                      color: _textGrey,
                    ),
                  ),
                ],
              ),
            ],
          ),
        ),
      ],
    );
  }

  Widget _buildRecentCalls(DashboardController controller) {
    if (controller.isLoading.value) {
      return _buildLoaderCard(height: 300.h);
    }

    final calls = controller.dashboard.value?.recentCalls ?? [];

    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
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
          Row(
            children: [
              Expanded(
                child: Text(
                  'Recent Calls',
                  style: TextStyle(
                    fontSize: 16.sp,
                    fontWeight: FontWeight.w800,
                    color: _textBlack,
                  ),
                ),
              ),
              GestureDetector(
                onTap: () {},
                child: Row(
                  children: [
                    Text(
                      'View All',
                      style: TextStyle(
                        fontSize: 13.sp,
                        fontWeight: FontWeight.w700,
                        color: _primaryRed,
                      ),
                    ),
                    SizedBox(width: 2.w),
                    Icon(
                      Icons.chevron_right_rounded,
                      size: 18.sp,
                      color: _primaryRed,
                    ),
                  ],
                ),
              ),
            ],
          ),
          SizedBox(height: 14.h),

          if (calls.isEmpty)
            Padding(
              padding: EdgeInsets.symmetric(vertical: 20.h),
              child: Center(
                child: Column(
                  children: [
                    Icon(Icons.phone_missed_rounded, size: 40.sp, color: _borderGrey),
                    SizedBox(height: 8.h),
                    Text('No recent calls found', style: TextStyle(fontSize: 13.sp, color: _textGrey)),
                  ],
                ),
              ),
            )
          else
            ...List.generate(calls.length, (i) {
              final call = calls[i];
              final isLast = i == calls.length - 1;
              return Column(
                children: [
                  _buildCallRow(call),
                  if (!isLast)
                    Padding(
                      padding: EdgeInsets.symmetric(vertical: 8.h),
                      child: const Divider(height: 1, color: Color(0xFFEEEEEE)),
                    ),
                ],
              );
            }),
        ],
      ),
    );
  }

  Widget _buildCallRow(RecentCallModel call) {
    // 1. Status ke hisaab se color decide karo
    final isAccepted = call.isAccepted;
    final statusColor = isAccepted ? _green : _primaryRed;
    final statusBg = isAccepted ? _green.withOpacity(0.10) : _primaryRed.withOpacity(0.10);

    // 2. Time format karo (Agar null hai toh 'Time unavailable' dikhao)
    String timeStr = 'Time unavailable';
    if (call.callTime != null) {
      final t = call.callTime!;
      final hour = t.hour > 12 ? t.hour - 12 : (t.hour == 0 ? 12 : t.hour);
      final min = t.minute.toString().padLeft(2, '0');
      final ampm = t.hour >= 12 ? 'PM' : 'AM';
      timeStr = '$hour:$min $ampm';
    }

    // 3. Duration format karo (seconds mein)
    final durationStr = '${call.callDuration}s';

    // 4. Marked Status format karo (API se aayega, e.g., "Correct", "Not Required")
    final markedStatus = call.userStatus.isNotEmpty ? call.userStatus : 'Not specified';

    return Row(
      crossAxisAlignment: CrossAxisAlignment.center, // Text ko vertically center rakhne ke liye
      children: [
        // 👇 LEFT ICON (Status ke hisaab se Red ya Green)
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: statusColor, // Red for Rejected, Green for Accepted
            shape: BoxShape.circle,
          ),
          child: Icon(
            // Image mein phone icon use hua hai, aap call_rounded ya call_end_rounded use kar sakte hain
            isAccepted ? Icons.call_rounded : Icons.call_end_rounded,
            color: Colors.white,
            size: 20.sp,
          ),
        ),

        SizedBox(width: 12.w),

        // 👇 CENTER TEXT (Number, Time+Duration, Marked Status)
        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              // Number
              Text(
                call.phone,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
              SizedBox(height: 3.h),

              // Time • Duration
              Text(
                '$timeStr • $durationStr',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
              SizedBox(height: 3.h),

              // Marked: Status
              Text(
                'Marked: $markedStatus',
                style: TextStyle(
                  fontSize: 11.sp,
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

        // 👇 RIGHT STATUS PILL (Rejected / Accepted)
        Container(
          padding: EdgeInsets.symmetric(
            horizontal: 12.w,
            vertical: 5.h,
          ),
          decoration: BoxDecoration(
            color: statusBg,
            borderRadius: BorderRadius.circular(20.r),
          ),
          child: Text(
            call.classification, // "Rejected" ya "Accepted"
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildLoaderCard({required double height}) {
    return Container(
      height: height,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: const Center(
        child: CircularProgressIndicator(color: _primaryRed),
      ),
    );
  }

  Widget _buildErrorCard({
    required String message,
    required VoidCallback onRetry,
  }) {
    return Container(
      padding: EdgeInsets.all(16.w),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(20.r),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.04),
            blurRadius: 10,
            offset: const Offset(0, 3),
          ),
        ],
      ),
      child: Column(
        children: [
          Icon(Icons.error_outline_rounded, color: _primaryRed, size: 40.sp),
          SizedBox(height: 8.h),
          Text(
            message,
            textAlign: TextAlign.center,
            style: TextStyle(fontSize: 12.sp, color: _textGrey),
          ),
          SizedBox(height: 12.h),
          TextButton(
            onPressed: onRetry,
            child: Text(
              'Retry',
              style: TextStyle(
                color: _primaryRed,
                fontWeight: FontWeight.w700,
              ),
            ),
          ),
        ],
      ),
    );
  }
}