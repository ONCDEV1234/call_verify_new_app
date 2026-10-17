// lib/core/route/app_routes.dart

import 'package:get/get.dart';

import '../../features/bottom_nav/nav_screen.dart';
import '../../features/call_verify/call_log/call_log.dart';
import '../../features/call_verify/post_calling/screen/post_call_form_screen.dart';
import '../../features/call_verify/project/screen/project_detail_screen.dart';
import '../../features/call_verify/project/screen/project_screen.dart';
import '../../features/login/model/login_model.dart';
import '../../features/login/screen/login_screen.dart';
import '../../features/login/screen/otp_verify_screen.dart';
import '../../features/login/screen/signup_screen.dart';


// ═══════════════════════════════════════════════════════════
// ROUTE NAMES
// ═══════════════════════════════════════════════════════════
class AppRoutes {
  AppRoutes._();

  static const String LOGIN = '/login';
  static const String SIGNUP = '/signup';
  static const String OTP = '/otp';
  static const String BOTTOMNAV = '/bottomnav';
  static const String PROJECT = '/project';
  static const String PROJECT_DETAIL = '/project-detail';
  static const String POST_CALL = '/post-call';
}

// ═══════════════════════════════════════════════════════════
// BINDING
// ═══════════════════════════════════════════════════════════
class AppBinding extends Bindings {

  @override
  void dependencies() {
    Get.put(CallLog(), permanent: true);
  }
}

// ═══════════════════════════════════════════════════════════
// PAGES
// ═══════════════════════════════════════════════════════════
class AppPages {
  AppPages._();

  static final List<GetPage> pages = [
    // ── LOGIN ────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.LOGIN,
      page: () => const LoginScreen(),
      transition: Transition.fadeIn,
    ),

    // ── SIGNUP ───────────────────────────────────────────────
    GetPage(
      name: AppRoutes.SIGNUP,
      page: () => const SignupScreen(),
      transition: Transition.rightToLeft,
    ),

    // ── OTP ──────────────────────────────────────────────────
    GetPage(
      name: AppRoutes.OTP,
      page: () {
        final args = (Get.arguments as Map?) ?? {};
        return OtpVerifyScreen(
          flow: args['flow'] as OtpFlow,
          mobile: args['mobile'] as String,
          signupRequest: args['signupRequest'],
        );
      },
      transition: Transition.rightToLeft,
    ),

    // ── HOME (BottomNav) ─────────────────────────────────────
    GetPage(
      name: AppRoutes.BOTTOMNAV,
      page: () => const BottomNavScreen(),
      transition: Transition.fadeIn,
    ),

    // ── PROJECT (survey list) ────────────────────────────────
    GetPage(
      name: AppRoutes.PROJECT,
      page: () => const ProjectScreen(),
      transition: Transition.rightToLeft,
    ),

    // ── PROJECT DETAIL (responses) ───────────────────────────
    GetPage(
      name: AppRoutes.PROJECT_DETAIL,
      page: () => const ProjectDetailScreen(),
      transition: Transition.rightToLeft,
    ),

    GetPage(
      name: AppRoutes.POST_CALL,
      page: () => const PostCallFormScreen(),
      transition: Transition.rightToLeft,
    ),
  ];
}