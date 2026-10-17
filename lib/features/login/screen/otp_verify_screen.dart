// lib/app/modules/auth/view/otp_verify_screen.dart

import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:get/get.dart';

import '../../../core/route/app_routes.dart';
import '../controller/auth_service.dart';
import '../model/login_model.dart';


class OtpVerifyController extends GetxController {
  final OtpFlow flow;
  final String mobile;
  final MobileSignupRequest? signupRequest;

  OtpVerifyController({
    required this.flow,
    required this.mobile,
    this.signupRequest,
  });

  final AuthService _auth = Get.find<AuthService>();

  final otpController = TextEditingController();

  final secondsRemaining = 30.obs;

  Timer? _timer;

  bool get isSignup => flow == OtpFlow.signup;

  // ---------- LIFECYCLE ----------
  @override
  void onInit() {
    super.onInit();
    _startTimer();
  }

  @override
  void onClose() {
    _timer?.cancel();
    otpController.dispose();
    super.onClose();
  }

  // ---------- TIMER ----------
  void _startTimer() {
    _timer?.cancel();
    secondsRemaining.value = 30;

    _timer = Timer.periodic(const Duration(seconds: 1), (timer) {
      if (secondsRemaining.value <= 1) {
        timer.cancel();
        secondsRemaining.value = 0;
      } else {
        secondsRemaining.value--;
      }
    });
  }

  // ---------- VERIFY ----------
  Future<void> verifyOtp() async {
    FocusScope.of(Get.context!).unfocus();

    final otp = otpController.text.trim();

    if (otp.length != 6) {
      _showError('Please enter the 6-digit OTP.');
      return;
    }

    final bool success = flow == OtpFlow.login
        ? await _auth.verifyMobileLoginOtp(mobile: mobile, otp: otp)
        : await _auth.verifyMobileSignupOtp(mobile: mobile, otp: otp);

    if (success) {
      Get.offAllNamed(AppRoutes.BOTTOMNAV);
    } else {
      _showError(
        _auth.errorMessage.value ?? 'Invalid OTP. Please try again.',
      );
    }
  }

  // ---------- RESEND ----------
  Future<void> resendOtp() async {
    if (secondsRemaining.value > 0) return;

    bool success;

    if (flow == OtpFlow.login) {
      success = await _auth.sendMobileLoginOtp(mobile: mobile);
    } else {
      final request = signupRequest;
      if (request == null) {
        _showError('Signup information is missing.');
        return;
      }
      success = await _auth.sendMobileSignupOtp(request: request);
    }

    if (success) {
      _startTimer();
      otpController.clear();

      Get.snackbar(
        'OTP',
        'OTP sent successfully.',
        snackPosition: SnackPosition.BOTTOM,
        margin: const EdgeInsets.all(16),
      );
    } else {
      _showError(
        _auth.errorMessage.value ?? 'Unable to resend OTP.',
      );
    }
  }

  // ---------- ERROR ----------
  void _showError(String message) {
    Get.snackbar(
      'OTP Verification',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFD71920),
      colorText: Colors.white,
    );
  }
}



class OtpVerifyScreen extends StatelessWidget {
  final OtpFlow flow;
  final String mobile;
  final MobileSignupRequest? signupRequest;

  const OtpVerifyScreen({
    super.key,
    required this.flow,
    required this.mobile,
    this.signupRequest,
  });

  // ---------- UI COLORS ----------
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _lightRed = Color(0xFFE52B30);

  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE2E2E2);

  static const Color _pageBackground = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(
      OtpVerifyController(
        flow: flow,
        mobile: mobile,
        signupRequest: signupRequest,
      ),
    );

    final auth = Get.find<AuthService>();
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildRedHeader(size, c),
          SafeArea(
            child: Align(
              alignment: Alignment.topCenter,
              child: SingleChildScrollView(
                padding: EdgeInsets.only(
                  top: size.height * 0.295,
                  left: 17,
                  right: 17,
                  bottom: 25,
                ),
                child: _buildOtpCard(c, auth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildRedHeader(Size size, OtpVerifyController c) {
    return Container(
      height: size.height * 0.37,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lightRed, _primaryRed],
        ),
      ),
      child: Stack(
        children: [
          Positioned(
            right: -38,
            top: -35,
            child: Container(
              width: 105,
              height: 105,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.07),
                shape: BoxShape.circle,
              ),
            ),
          ),
          Positioned(
            left: -28,
            bottom: -30,
            child: Container(
              width: 90,
              height: 90,
              decoration: BoxDecoration(
                color: Colors.white.withOpacity(0.08),
                shape: BoxShape.circle,
              ),
            ),
          ),
          SafeArea(
            child: Center(
              child: Column(
                mainAxisSize: MainAxisSize.min,
                crossAxisAlignment: CrossAxisAlignment.center,
                children: [
                  const SizedBox(height: 14),
                  Container(
                    width: 55,
                    height: 55,
                    decoration: const BoxDecoration(
                      color: Colors.white,
                      shape: BoxShape.circle,
                    ),
                    child: const Icon(
                      Icons.sms_outlined,
                      size: 32,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  Text(
                    c.isSignup
                        ? 'Verify Your Mobile'
                        : 'Verify Login OTP',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const Text(
                    'Sent To Your Number',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  Text(
                    '+91 $mobile',
                    textAlign: TextAlign.center,
                    style: const TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
                    ),
                  ),
                ],
              ),
            ),
          ),

          // ---------- BACK BUTTON ----------
          SafeArea(
            child: Align(
              alignment: Alignment.topLeft,
              child: Padding(
                padding: const EdgeInsets.only(left: 12, top: 8),
                child: InkWell(
                  onTap: () => Get.back(),
                  borderRadius: BorderRadius.circular(12),
                  child: Container(
                    width: 40,
                    height: 40,
                    decoration: BoxDecoration(
                      color: Colors.white.withOpacity(0.15),
                      borderRadius: BorderRadius.circular(12),
                    ),
                    child: const Icon(
                      Icons.arrow_back_ios_new_rounded,
                      size: 16,
                      color: Colors.white,
                    ),
                  ),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildOtpCard(OtpVerifyController c, AuthService auth) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.fromLTRB(16, 20, 16, 18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(22),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 20,
            offset: const Offset(0, 7),
          ),
        ],
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          const Center(
            child: Text(
              'Enter OTP',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.w700,
                color: _textBlack,
              ),
            ),
          ),
          const SizedBox(height: 4),
          Center(
            child: Text(
              'We sent a 6-digit code to +91 $mobile',
              textAlign: TextAlign.center,
              style: const TextStyle(
                fontSize: 12,
                color: _textGrey,
              ),
            ),
          ),
          const SizedBox(height: 20),

          const Text(
            'OTP Code',
            style: TextStyle(
              fontSize: 12,
              fontWeight: FontWeight.w500,
              color: _textBlack,
            ),
          ),
          const SizedBox(height: 6),

          Container(
            height: 52,
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(9),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.025),
                  blurRadius: 5,
                  offset: const Offset(0, 2),
                ),
              ],
            ),
            child: TextField(
              controller: c.otpController,
              keyboardType: TextInputType.number,
              textAlign: TextAlign.center,
              maxLength: 6,
              autofocus: true,
              inputFormatters: [
                FilteringTextInputFormatter.digitsOnly,
                LengthLimitingTextInputFormatter(6),
              ],
              style: const TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.w700,
                letterSpacing: 8,
                color: _textBlack,
              ),
              decoration: InputDecoration(
                counterText: '',
                hintText: '••••••',
                hintStyle: const TextStyle(
                  fontSize: 20,
                  color: Color(0xFF999999),
                  letterSpacing: 8,
                ),
                filled: true,
                fillColor: Colors.white,
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 0,
                ),
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: _borderGrey,
                    width: 1,
                  ),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: _borderGrey,
                    width: 1,
                  ),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(9),
                  borderSide: const BorderSide(
                    color: _primaryRed,
                    width: 1.2,
                  ),
                ),
              ),
            ),
          ),

          const SizedBox(height: 5),

          const Text(
            'Enter the 6-digit code we just sent you.',
            style: TextStyle(fontSize: 10, color: _textGrey),
          ),

          const SizedBox(height: 14),

          Obx(() {
            final loading = auth.isLoading.value;
            return SizedBox(
              width: double.infinity,
              height: 39,
              child: ElevatedButton(
                onPressed: loading ? null : c.verifyOtp,
                style: ElevatedButton.styleFrom(
                  backgroundColor: _primaryRed,
                  foregroundColor: Colors.white,
                  disabledBackgroundColor: _primaryRed.withOpacity(0.5),
                  elevation: 0,
                  padding: EdgeInsets.zero,
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: loading
                    ? const SizedBox(
                  width: 19,
                  height: 19,
                  child: CircularProgressIndicator(
                    strokeWidth: 2,
                    valueColor:
                    AlwaysStoppedAnimation<Color>(Colors.white),
                  ),
                )
                    : const Row(
                  mainAxisAlignment: MainAxisAlignment.center,
                  children: [
                    Icon(Icons.verified_outlined, size: 17),
                    SizedBox(width: 7),
                    Text(
                      'Verify OTP',
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        letterSpacing: 0.2,
                      ),
                    ),
                  ],
                ),
              ),
            );
          }),

          const SizedBox(height: 14),

          Obx(
                () => Row(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Text(
                  c.secondsRemaining.value > 0
                      ? 'Resend OTP in ${c.secondsRemaining.value} s'
                      : "Didn't receive OTP?",
                  style: const TextStyle(
                    fontSize: 11.5,
                    color: _textGrey,
                  ),
                ),
                if (c.secondsRemaining.value == 0)
                  TextButton(
                    onPressed: auth.isLoading.value ? null : c.resendOtp,
                    style: TextButton.styleFrom(
                      padding: const EdgeInsets.symmetric(horizontal: 6),
                      minimumSize: const Size(0, 0),
                      tapTargetSize: MaterialTapTargetSize.shrinkWrap,
                    ),
                    child: const Text(
                      'Resend OTP',
                      style: TextStyle(
                        fontSize: 11.5,
                        color: _primaryRed,
                        fontWeight: FontWeight.w700,
                      ),
                    ),
                  ),
              ],
            ),
          ),
        ],
      ),
    );
  }
}