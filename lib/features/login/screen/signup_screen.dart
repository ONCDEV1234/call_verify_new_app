// lib/app/modules/auth/view/signup_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../controller/auth_service.dart';
import '../model/login_model.dart';
import 'otp_verify_screen.dart';


class SignupController extends GetxController {
  final AuthService _auth = Get.find<AuthService>();

  final GlobalKey<FormState> formKey = GlobalKey<FormState>();

  final nameController = TextEditingController();
  final firstNameController = TextEditingController();
  final lastNameController = TextEditingController();
  final emailController = TextEditingController();
  final dobController = TextEditingController();
  final mobileController = TextEditingController();

  final selectedDate = Rxn<DateTime>();

  Future<void> pickDateOfBirth(BuildContext context) async {
    FocusScope.of(context).unfocus();

    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: DateTime(now.year - 18, now.month, now.day),
      firstDate: DateTime(1900),
      lastDate: now,
      builder: (context, child) {
        return Theme(
          data: Theme.of(context).copyWith(
            colorScheme: const ColorScheme.light(
              primary: Color(0xFFD71920),
              onPrimary: Colors.white,
              surface: Colors.white,
              onSurface: Color(0xFF222222),
            ),
          ),
          child: child!,
        );
      },
    );

    if (picked == null) return;

    selectedDate.value = picked;

    dobController.text =
    '${picked.year.toString().padLeft(4, '0')}-'
        '${picked.month.toString().padLeft(2, '0')}-'
        '${picked.day.toString().padLeft(2, '0')}';
  }

  Future<void> submitSignup() async {
    FocusScope.of(Get.context!).unfocus();

    if (!formKey.currentState!.validate()) return;

    final request = MobileSignupRequest(
      name: nameController.text.trim(),
      firstName: firstNameController.text.trim(),
      lastName: lastNameController.text.trim(),
      email: emailController.text.trim(),
      dateOfBirth: dobController.text.trim(),
      mobile: mobileController.text.trim(),
    );

    final success = await _auth.sendMobileSignupOtp(request: request);

    if (!success) {
      _showError(
        _auth.errorMessage.value ?? 'Unable to send OTP.',
      );
      return;
    }

    Get.to(
          () => OtpVerifyScreen(
        flow: OtpFlow.signup,
        mobile: request.mobile,
        signupRequest: request,
      ),
    );
  }

  // ---------- ERROR ----------
  void _showError(String message) {
    Get.snackbar(
      'Signup',
      message,
      snackPosition: SnackPosition.BOTTOM,
      margin: const EdgeInsets.all(16),
      backgroundColor: const Color(0xFFD71920),
      colorText: Colors.white,
    );
  }

  @override
  void onClose() {
    nameController.dispose();
    firstNameController.dispose();
    lastNameController.dispose();
    emailController.dispose();
    dobController.dispose();
    mobileController.dispose();
    super.onClose();
  }
}


class SignupScreen extends StatelessWidget {
  const SignupScreen({super.key});

  // ---------- COLORS ----------
  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _lightRed = Color(0xFFE52B30);

  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE2E2E2);

  static const Color _pageBackground = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(SignupController());

    final auth = Get.find<AuthService>();

    final size = MediaQuery.of(context).size;

    return Scaffold(
      backgroundColor: _pageBackground,
      resizeToAvoidBottomInset: true,
      body: Stack(
        children: [
          // ---------- RED HEADER ----------
          _buildRedHeader(size),

          // ---------- SIGNUP CARD ----------
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
                child: _buildSignupCard(context, c, auth),
              ),
            ),
          ),
        ],
      ),
    );
  }

  // RED HEADER
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
          )
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
                      Icons.person_add_alt_1_rounded,
                      size: 30,
                      color: _primaryRed,
                    ),
                  ),
                  const SizedBox(height: 12),
                  const Text(
                    'Create Your Account',
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
                    'Join us and get started',
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

  // SIGNUP CARD
  Widget _buildSignupCard(
      BuildContext context,
      SignupController c,
      AuthService auth,
      ) {
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
      child: Form(
        key: c.formKey,
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Center(
              child: Text(
                'Create Account',
                style: TextStyle(
                  fontSize: 18,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
            ),
            const SizedBox(height: 4),
            const Center(
              child: Text(
                'Enter your details to continue',
                style: TextStyle(fontSize: 14, color: _textGrey),
              ),
            ),
            const SizedBox(height: 21),

            _label('Name'),
            _buildInputField(
              controller: c.nameController,
              hint: 'Enter your name',
              prefix: const Icon(
                Icons.person_outline,
                size: 19,
                color: _textGrey,
              ),
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 13),

            _label('First Name'),
            _buildInputField(
              controller: c.firstNameController,
              hint: 'Enter first name',
              prefix: const Icon(
                Icons.person_outline,
                size: 19,
                color: _textGrey,
              ),
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 13),

            _label('Last Name'),
            _buildInputField(
              controller: c.lastNameController,
              hint: 'Enter last name',
              prefix: const Icon(
                Icons.person_outline,
                size: 19,
                color: _textGrey,
              ),
              textCapitalization: TextCapitalization.words,
              keyboardType: TextInputType.name,
            ),
            const SizedBox(height: 13),

            _label('Email Address'),
            _buildInputField(
              controller: c.emailController,
              hint: 'Email',
              prefix: const Icon(
                Icons.email_outlined,
                size: 19,
                color: _textGrey,
              ),
              keyboardType: TextInputType.emailAddress,
            ),
            const SizedBox(height: 13),

            _label('Date of Birth'),
            _buildInputField(
              controller: c.dobController,
              hint: 'Select date of birth',
              prefix: const Icon(
                Icons.calendar_today_outlined,
                size: 18,
                color: _textGrey,
              ),
              readOnly: true,
              onTap: () => c.pickDateOfBirth(context),
              suffix: const Icon(
                Icons.keyboard_arrow_down_rounded,
                size: 20,
                color: _textGrey,
              ),
            ),
            const SizedBox(height: 13),

            _label('Mobile Number'),
            _buildInputField(
              controller: c.mobileController,
              hint: '10-digit mobile number',
              prefix: const Icon(
                Icons.phone_android_outlined,
                size: 19,
                color: _textGrey,
              ),
              keyboardType: TextInputType.phone,
              maxLength: 10,
              prefixText: '+91  ',
            ),
            const SizedBox(height: 5),
            const Text(
              'An OTP will be sent to this mobile number.',
              style: TextStyle(fontSize: 10, color: _textGrey),
            ),
            const SizedBox(height: 12),

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

            Obx(() {
              final loading = auth.isLoading.value;
              return SizedBox(
                width: double.infinity,
                height: 39,
                child: ElevatedButton(
                  onPressed: loading ? null : c.submitSignup,
                  style: ElevatedButton.styleFrom(
                    backgroundColor: _primaryRed,
                    foregroundColor: Colors.white,
                    disabledBackgroundColor:
                    _primaryRed.withOpacity(0.5),
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
                      valueColor: AlwaysStoppedAnimation<Color>(
                        Colors.white,
                      ),
                    ),
                  )
                      : const Row(
                    mainAxisAlignment: MainAxisAlignment.center,
                    children: [
                      Icon(Icons.sms_outlined, size: 17),
                      SizedBox(width: 7),
                      Text(
                        'Continue',
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

            const SizedBox(height: 18),

            Row(
              children: [
                Expanded(
                  child: Container(height: 1, color: _borderGrey),
                ),
                const Padding(
                  padding: EdgeInsets.symmetric(horizontal: 12),
                  child: Text(
                    'Already have an account?',
                    style: TextStyle(fontSize: 10.5, color: _textGrey),
                  ),
                ),
                Expanded(
                  child: Container(height: 1, color: _borderGrey),
                ),
              ],
            ),

            const SizedBox(height: 15),

            SizedBox(
              width: double.infinity,
              height: 39,
              child: OutlinedButton(
                onPressed: () => Get.back(),
                style: OutlinedButton.styleFrom(
                  foregroundColor: _primaryRed,
                  side: const BorderSide(color: _primaryRed, width: 1),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(10),
                  ),
                ),
                child: const Text(
                  'Login',
                  style: TextStyle(
                    fontSize: 12,
                    fontWeight: FontWeight.w600,
                  ),
                ),
              ),
            ),

            const SizedBox(height: 14),

            const Center(
              child: Text.rich(
                TextSpan(
                  children: [
                    TextSpan(
                      text: 'Powered by ',
                      style: TextStyle(fontSize: 10.5, color: _textGrey),
                    ),
                    TextSpan(
                      text: 'LeadTech',
                      style: TextStyle(
                        fontSize: 10.5,
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
      ),
    );
  }


  // HELPERS
  Widget _label(String text) {
    return Padding(
      padding: const EdgeInsets.only(bottom: 6),
      child: Text(
        text,
        style: const TextStyle(
          fontSize: 12,
          fontWeight: FontWeight.w500,
          color: _textBlack,
        ),
      ),
    );
  }

  Widget _buildInputField({
    required TextEditingController controller,
    required String hint,
    required Widget prefix,
    Widget? suffix,
    bool readOnly = false,
    VoidCallback? onTap,
    TextInputType? keyboardType,
    TextCapitalization textCapitalization = TextCapitalization.none,
    int? maxLength,
    String? prefixText,
  }) {
    return Container(
      height: 42,
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
        readOnly: readOnly,
        onTap: onTap,
        keyboardType: keyboardType,
        textCapitalization: textCapitalization,
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
          prefixText: prefixText,
          prefixStyle: const TextStyle(
            fontSize: 12.5,
            color: _textBlack,
            fontWeight: FontWeight.w500,
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