
import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_service.dart';
import '../model/login_model.dart';
import 'otp_verify_screen.dart';
import 'signup_screen.dart';

class LoginController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  // ---------- FORM ----------
  final mobileController = TextEditingController();

  // ---------- VALIDATION ----------
  static final RegExp _mobileRegex = RegExp(r'^[6-9][0-9]{9}$');

  bool isValidMobile(String value) => _mobileRegex.hasMatch(value);

  // ---------- SEND OTP ----------
  Future<void> submitMobileLogin() async {
    FocusScope.of(Get.context!).unfocus();

    final mobile = mobileController.text.trim();

    if (mobile.isEmpty) {
      Get.snackbar(
        'Mobile number required',
        'Please enter your mobile number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    if (!isValidMobile(mobile)) {
      Get.snackbar(
        'Invalid mobile number',
        'Please enter a valid 10-digit mobile number.',
        snackPosition: SnackPosition.BOTTOM,
      );
      return;
    }

    final ok = await _auth.sendMobileLoginOtp(mobile: mobile);
    if (!ok) return;

    Get.to(
          () => OtpVerifyScreen(
        flow: OtpFlow.login,
        mobile: mobile,
      ),
    );
  }

  @override
  void onClose() {
    mobileController.dispose();
    super.onClose();
  }
}


class LoginScreen extends StatelessWidget {
  const LoginScreen({super.key});

  // ---------- COLORS ----------
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _lightRed = Color(0xFFE52B30);

  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE2E2E2);

  static const Color _pageBackground = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(LoginController());
    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          _buildRedHeader(size),
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
                child: _buildLoginCard(c),
              ),
            ),
          ),
        ],
      ),
    );
  }


  Widget _buildRedHeader(Size size) {
    return Container(
      height: size.height * 0.37,
      width: double.infinity,
      decoration: const BoxDecoration(
        gradient: LinearGradient(
          begin: Alignment.topCenter,
          end: Alignment.bottomCenter,
          colors: [_lightRed, _primaryRed],
        ),
        borderRadius: BorderRadius.only(
          bottomLeft: Radius.circular(25),
          bottomRight: Radius.circular(25),
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
                      Icons.person,
                      size: 32,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Elevate Your Experience',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const Text(
                    'From Anywhere',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 20,
                      fontWeight: FontWeight.w700,
                      color: Colors.white,
                      height: 1.15,
                    ),
                  ),
                  const SizedBox(height: 7),
                  const Text(
                    'Access your account seamlessly',
                    textAlign: TextAlign.center,
                    style: TextStyle(
                      fontSize: 14,
                      fontWeight: FontWeight.w500,
                      color: Colors.white,
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


  // LOGIN CARD

  Widget _buildLoginCard(LoginController c) {
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
          // ---------- TITLE ----------
          const Center(
            child: Text(
              'Login with Mobile',
              style: TextStyle(
                fontSize: 15,
                fontWeight: FontWeight.w700,
                color: _textBlack,
              ),
            ),
          ),

          const SizedBox(height: 18),

          // ---------- MOBILE FORM ----------
          _buildMobileLoginForm(c),

          const SizedBox(height: 18),

          // ---------- NEW USER DIVIDER ----------
          Row(
            children: [
              Expanded(
                child: Container(height: 1, color: _borderGrey),
              ),
              const Padding(
                padding: EdgeInsets.symmetric(horizontal: 12),
                child: Text(
                  'New to our platform?',
                  style: TextStyle(
                    fontSize: 12,
                    color: _textGrey,
                  ),
                ),
              ),
              Expanded(
                child: Container(height: 1, color: _borderGrey),
              ),
            ],
          ),

          const SizedBox(height: 15),

          // ---------- SIGN UP BUTTON ----------
          SizedBox(
            width: double.infinity,
            height: 39,
            child: OutlinedButton(
              onPressed: () {
                Get.to(() => const SignupScreen());
              },
              style: OutlinedButton.styleFrom(
                foregroundColor: _primaryRed,
                side: const BorderSide(color: _primaryRed, width: 1),
                shape: RoundedRectangleBorder(
                  borderRadius: BorderRadius.circular(10),
                ),
              ),
              child: const Text(
                'Sign up',
                style: TextStyle(
                  fontSize: 12,
                  fontWeight: FontWeight.w600,
                ),
              ),
            ),
          ),

          const SizedBox(height: 14),

          // ---------- POWERED BY ----------
          const Center(
            child: Text.rich(
              TextSpan(
                children: [
                  TextSpan(
                    text: 'Powered by ',
                    style: TextStyle(fontSize: 12, color: _textGrey),
                  ),
                  TextSpan(
                    text: 'LeadTech',
                    style: TextStyle(
                      fontSize: 12,
                      color: _primaryRed,
                      fontWeight: FontWeight.w600,
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


  // MOBILE LOGIN FORM

  Widget _buildMobileLoginForm(LoginController c) {
    final auth = Get.find<AuthService>();

    return Column(
      key: const ValueKey('mobile-login'),
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        const Text(
          'Mobile Number',
          style: TextStyle(
            fontSize: 14,
            fontWeight: FontWeight.w600,
            color: _textBlack,
          ),
        ),
        const SizedBox(height: 10),

        _buildInputField(
          controller: c.mobileController,
          hint: 'Enter 10-digit mobile number',
          prefix: const Icon(
            Icons.phone_android_outlined,
            size: 19,
            color: _textGrey,
          ),
          keyboardType: TextInputType.phone,
          textInputAction: TextInputAction.done,
          maxLength: 10,
          onSubmitted: (_) => c.submitMobileLogin(),
        ),

        const SizedBox(height: 14),

        const Text(
          'We will send a verification OTP to this number.',
          style: TextStyle(fontSize: 12, color: _textGrey),
        ),

        const SizedBox(height: 14),

        // ---------- PRIVACY ----------
        _buildPrivacyRow(),

        const SizedBox(height: 14),

        // ---------- ERROR MESSAGE ----------
        Obx(() {
          final err = auth.errorMessage.value;
          if (err == null || err.isEmpty) {
            return const SizedBox.shrink();
          }
          return Padding(
            padding: const EdgeInsets.only(bottom: 8),
            child: Container(
              width: double.infinity,
              padding: const EdgeInsets.symmetric(
                horizontal: 10,
                vertical: 8,
              ),
              decoration: BoxDecoration(
                color: _primaryRed.withOpacity(0.06),
                borderRadius: BorderRadius.circular(8),
              ),
              child: Text(
                err,
                textAlign: TextAlign.center,
                style: const TextStyle(
                  color: _primaryRed,
                  fontSize: 11,
                  fontWeight: FontWeight.w500,
                ),
              ),
            ),
          );
        }),

        // ---------- SEND OTP BUTTON ----------
        Obx(() {
          final loading = auth.isLoading.value;
          return SizedBox(
            width: double.infinity,
            height: 39,
            child: ElevatedButton(
              onPressed: loading ? null : c.submitMobileLogin,
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
                  Icon(Icons.sms_outlined, size: 17),
                  SizedBox(width: 7),
                  Text(
                    'Send OTP',
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
      ],
    );
  }


  // PRIVACY ROW

  Widget _buildPrivacyRow() {
    return Row(
      children: [
        SizedBox(
          width: 28,
          height: 28,
          child: Checkbox(
            value: false,
            activeColor: _primaryRed,
            side: const BorderSide(
              color: Color(0xFF555555),
              width: 1.3,
            ),
            shape: RoundedRectangleBorder(
              borderRadius: BorderRadius.circular(5),
            ),
            onChanged: (_) {},
          ),
        ),
        const SizedBox(width: 3),
        const Expanded(
          child: Text.rich(
            TextSpan(
              children: [
                TextSpan(
                  text: 'I agree to the ',
                  style: TextStyle(fontSize: 12, color: _textGrey),
                ),
                TextSpan(
                  text: 'Privacy Policy',
                  style: TextStyle(
                    fontSize: 12,
                    color: _primaryRed,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ],
            ),
          ),
        ),
      ],
    );
  }


  // INPUT FIELD

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required Widget prefix,
    bool obscureText = false,
    FocusNode? focusNode,
    TextInputType? keyboardType,
    TextInputAction? textInputAction,
    ValueChanged<String>? onSubmitted,
    Widget? suffix,
    int? maxLength,
  }) {
    return Container(
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
        controller: controller,
        focusNode: focusNode,
        obscureText: obscureText,
        keyboardType: keyboardType,
        textInputAction: textInputAction,
        onSubmitted: onSubmitted,
        maxLength: maxLength,
        style: const TextStyle(
          fontSize: 12.5,
          color: _textBlack,
          fontWeight: FontWeight.w400,
        ),
        decoration: InputDecoration(
          counterText: '',
          hintText: hint,
          hintStyle: const TextStyle(
            fontSize: 12,
            color: Color(0xFF999999),
          ),
          prefixIcon: Padding(
            padding: const EdgeInsets.only(left: 11, right: 4),
            child: prefix,
          ),
          prefixIconConstraints: const BoxConstraints(
            minWidth: 38,
            minHeight: 42,
          ),
          suffixIcon: suffix,
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
    );
  }
}