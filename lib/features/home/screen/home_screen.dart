
import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import '../../../core/route/app_routes.dart';
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

  // ---------------- DUMMY DATA ----------------
  static const int _totalCalls = 24;
  static const int _receivedCalls = 18;
  static const int _rejectedCalls = 6;

  static final List<_RecentCall> _recentCalls = [
    _RecentCall(
      number: '+91 98765 43210',
      type: 'Incoming',
      time: '10:24 AM',
      status: 'Verified',
      typeColor: _green,
      typeIcon: Icons.call_received_rounded,
    ),
    _RecentCall(
      number: '+91 91234 56789',
      type: 'Rejected',
      time: '09:12 AM',
      status: 'Rejected',
      typeColor: _primaryRed,
      typeIcon: Icons.call_end_rounded,
    ),
    _RecentCall(
      number: '+91 87654 32109',
      type: 'Outgoing',
      time: '08:33 AM',
      status: 'Verified',
      typeColor: _blue,
      typeIcon: Icons.call_made_rounded,
    ),
    _RecentCall(
      number: '+91 99887 66554',
      type: 'Incoming',
      time: '07:50 AM',
      status: 'Verified',
      typeColor: _green,
      typeIcon: Icons.call_received_rounded,
    ),
    _RecentCall(
      number: '+91 98761 23456',
      type: 'Rejected',
      time: '06:18 AM',
      status: 'Rejected',
      typeColor: _primaryRed,
      typeIcon: Icons.call_end_rounded,
    ),
  ];

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final user = auth.currentUser.value;

    final name = (user?.name.isNotEmpty ?? false) ? user!.name : 'User';
    final mobile = user?.mobile ?? '';

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        top: false,
        child: SingleChildScrollView(
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
                child: _buildTodayOverview(),
              ),

              SizedBox(height: 20.h),

              Padding(
                padding: EdgeInsets.symmetric(horizontal: 16.w),
                child: _buildRecentCalls(),
              ),

              SizedBox(height: 24.h),
            ],
          ),
        ),
      ),
    );
  }

  // TOP BANNER
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
              debugPrint('TOP BANNER ERROR: $error');
              return Container(color: _primaryRed);
            },
          ),

          // Bell icon
          Positioned(
            top: 45.h,
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

          // Name + Mobile + Online pill
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

  // VERIFY CALL CARD
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
                debugPrint('TOP CARD ERROR: $error');
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

  // TODAY'S OVERVIEW
  Widget _buildTodayOverview() {
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
                      'Today',
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
                  value: _totalCalls,
                  label: 'Total',
                  color: _primaryRed,
                  progress: 0.75,
                ),
              ),
              Expanded(
                child: _buildCircularStat(
                  value: _receivedCalls,
                  label: 'Received',
                  color: _green,
                  progress: 0.62,
                ),
              ),
              Expanded(
                child: _buildCircularStat(
                  value: _rejectedCalls,
                  label: 'Rejected',
                  color: _primaryRed,
                  progress: 0.28,
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

  // RECENT CALLS
  Widget _buildRecentCalls() {
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

          ...List.generate(_recentCalls.length, (i) {
            final call = _recentCalls[i];
            final isLast = i == _recentCalls.length - 1;
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

  Widget _buildCallRow(_RecentCall call) {
    final isVerified = call.status == 'Verified';
    final statusColor = isVerified ? _green : _primaryRed;
    final statusBg = isVerified
        ? _green.withOpacity(0.10)
        : _primaryRed.withOpacity(0.10);

    return Row(
      children: [
        Container(
          width: 42.w,
          height: 42.w,
          decoration: BoxDecoration(
            color: call.typeColor,
            shape: BoxShape.circle,
          ),
          child: Icon(
            call.typeIcon,
            color: Colors.white,
            size: 20.sp,
          ),
        ),
        SizedBox(width: 12.w),

        Expanded(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(
                call.number,
                style: TextStyle(
                  fontSize: 14.sp,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
              SizedBox(height: 2.h),
              Text(
                '${call.type}  •  ${call.time}',
                style: TextStyle(
                  fontSize: 11.5.sp,
                  color: _textGrey,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ],
          ),
        ),

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
            call.status,
            style: TextStyle(
              fontSize: 11.sp,
              fontWeight: FontWeight.w700,
              color: statusColor,
            ),
          ),
        ),
        SizedBox(width: 4.w),

        Icon(
          Icons.more_vert_rounded,
          size: 18.sp,
          color: _textGrey,
        ),
      ],
    );
  }

  // HELPERS
  String _greeting() {
    final h = DateTime.now().hour;
    if (h < 12) return 'Good Morning';
    if (h < 17) return 'Good Afternoon';
    return 'Good Evening';
  }
}

// DATA HOLDERS
class _RecentCall {
  final String number;
  final String type;
  final String time;
  final String status;
  final Color typeColor;
  final IconData typeIcon;

  _RecentCall({
    required this.number,
    required this.type,
    required this.time,
    required this.status,
    required this.typeColor,
    required this.typeIcon,
  });
}