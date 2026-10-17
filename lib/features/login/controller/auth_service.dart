
import 'dart:convert';

import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

import '../../../core/network/api_provider.dart';
import '../../../core/route/app_routes.dart';


import '../model/login_model.dart';

// AUTH SERVICE
class AuthService extends GetxService {
  final ApiProvider _api = Get.find<ApiProvider>();

  final Rx<AuthUser?> currentUser = Rx<AuthUser?>(null);
  final RxBool isLoggedIn = false.obs;
  final RxBool isLoading = false.obs;
  final RxnString errorMessage = RxnString();

  // BOOT
  Future<AuthService> init() async {
    _api.onUnauthorized = _onUnauthorized;
    await tryAutoLogin();
    return this;
  }

  Future<bool> tryAutoLogin() async {
    if (!_api.hasToken) {
      isLoggedIn.value = false;
      currentUser.value = null;
      print('🔐 [AuthService] No token in prefs — not logged in');
      return false;
    }

    final prefs = await SharedPreferences.getInstance();
    final userJson = prefs.getString('auth_user');

    if (userJson == null || userJson.isEmpty) {
      print('⚠️ [AuthService] Token present but no user — clearing session');
      await _api.clearAuthSession();
      isLoggedIn.value = false;
      currentUser.value = null;
      return false;
    }

    try {
      final decoded = jsonDecode(userJson);
      if (decoded is! Map) {
        throw const FormatException('Invalid stored user data');
      }
      currentUser.value = AuthUser.fromJson(
        Map<String, dynamic>.from(decoded),
      );
    } catch (e) {
      print('⚠️ [AuthService] Corrupt stored user JSON — clearing: $e');
      await _api.clearAuthSession();
      isLoggedIn.value = false;
      currentUser.value = null;
      return false;
    }

    final user = currentUser.value;
    if (user == null) {
      await _api.clearAuthSession();
      isLoggedIn.value = false;
      return false;
    }

    // Mobile-created users have role=user and can have client_code=null.
    final isMobileUser = user.role == 'user';
    final isAdmin = user.isAdmin;

    if (!isAdmin && !isMobileUser && _api.clientCode.isEmpty) {
      print('⚠️ [AuthService] No clientCode in prefs — clearing session');
      await _api.clearAuthSession();
      isLoggedIn.value = false;
      currentUser.value = null;
      return false;
    }

    isLoggedIn.value = true;
    print(
      '🔐 [AuthService] Restored session — '
          'mobile=${user.mobile}, role=${user.role}, '
          'clientCode=${_api.clientCode}',
    );
    return true;
  }

  // MOBILE LOGIN — SEND OTP
  Future<bool> sendMobileLoginOtp({required String mobile}) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final url = '${ApiProvider.authPrefix}/auth/mobile/login/send-otp';
      print('📱 [AuthService] POST $url');

      final resp = await _api.post(url, {'mobile': mobile.trim()});
      final response = MobileOtpResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send OTP.';
        return false;
      }

      print('📱 [AuthService] Mobile login OTP sent');
      return true;
    } on ApiException catch (e) {
      print('❌ [AuthService] Mobile login OTP failed: ${e.message}');
      _setOtpError(e);
      return false;
    } catch (e) {
      print('❌ [AuthService] Unexpected mobile login OTP error: $e');
      errorMessage.value = 'Unable to send OTP. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // MOBILE LOGIN — VERIFY OTP
  Future<bool> verifyMobileLoginOtp({
    required String mobile,
    required String otp,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final url = '${ApiProvider.authPrefix}/auth/mobile/login/verify-otp';
      print('📱 [AuthService] POST $url');

      final resp = await _api.post(url, {
        'mobile': mobile.trim(),
        'otp': otp.trim(),
      });

      final response = MobileLoginResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      if (!response.success || response.accessToken.isEmpty) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'OTP verification failed.';
        return false;
      }

      await _saveAuthenticatedSession(
        token: response.accessToken,
        user: response.user,
      );

      print(
        '📱 [AuthService] Mobile login successful — '
            'user=${response.user.mobile}, role=${response.user.role}',
      );
      return true;
    } on ApiException catch (e) {
      print('❌ [AuthService] Mobile login verification failed: ${e.message}');
      _setOtpError(e);
      return false;
    } catch (e) {
      print('❌ [AuthService] Unexpected mobile login verification error: $e');
      errorMessage.value = 'OTP verification failed. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // MOBILE SIGNUP — SEND OTP
  Future<bool> sendMobileSignupOtp({
    required MobileSignupRequest request,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final url = '${ApiProvider.authPrefix}/auth/mobile/signup/send-otp';
      print('📱 [AuthService] POST $url');

      final resp = await _api.post(url, request.toJson());
      final response = MobileOtpResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      if (!response.success) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Unable to send signup OTP.';
        return false;
      }

      print('📱 [AuthService] Signup OTP sent');
      return true;
    } on ApiException catch (e) {
      print('❌ [AuthService] Signup OTP failed: ${e.message}');
      _setOtpError(e);
      return false;
    } catch (e) {
      print('❌ [AuthService] Unexpected signup OTP error: $e');
      errorMessage.value = 'Unable to send OTP. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // MOBILE SIGNUP — VERIFY OTP

  Future<bool> verifyMobileSignupOtp({
    required String mobile,
    required String otp,
  }) async {
    if (isLoading.value) return false;

    isLoading.value = true;
    errorMessage.value = null;

    try {
      final url = '${ApiProvider.authPrefix}/auth/mobile/signup/verify-otp';
      print('📱 [AuthService] POST $url');

      final resp = await _api.post(url, {
        'mobile': mobile.trim(),
        'otp': otp.trim(),
      });

      final response = MobileSignupResponse.fromJson(
        Map<String, dynamic>.from(resp),
      );

      if (!response.success || response.accessToken.isEmpty) {
        errorMessage.value = response.message.isNotEmpty
            ? response.message
            : 'Signup verification failed.';
        return false;
      }

      await _saveAuthenticatedSession(
        token: response.accessToken,
        user: response.user,
      );

      print(
        '📱 [AuthService] Mobile signup successful — '
            'user=${response.user.mobile}, role=${response.user.role}',
      );
      return true;
    } on ApiException catch (e) {
      print('❌ [AuthService] Signup OTP verification failed: ${e.message}');
      _setOtpError(e);
      return false;
    } catch (e) {
      print('❌ [AuthService] Unexpected signup verification error: $e');
      errorMessage.value = 'OTP verification failed. Please try again.';
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  // SAVE SESSION
  Future<void> _saveAuthenticatedSession({
    required String token,
    required AuthUser user,
  }) async {
    await _api.setAuthSession(token: token, clientCode: user.clientCode);

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_user', jsonEncode(user.toJson()));

    currentUser.value = user;
    isLoggedIn.value = true;

    print(
      '🔐 [AuthService] Session saved locally — '
          'id=${user.id}, role=${user.role}, mobile=${user.mobile}',
    );
  }


  // ERROR HELPER
  void _setOtpError(ApiException e) {
    if (e.statusCode == 400) {
      errorMessage.value = e.message;
    } else if (e.statusCode == 401) {
      errorMessage.value = 'Incorrect OTP. Please try again.';
    } else if (e.statusCode == 403) {
      errorMessage.value =
      'This number is not registered. Please sign up first.';
    } else if (e.statusCode == 404) {
      errorMessage.value = 'Account not found. Please sign up first.';
    } else if (e.statusCode == 422) {
      errorMessage.value = 'Please enter valid information.';
    } else if (e.isNetworkError) {
      errorMessage.value = 'No internet connection. Please try again.';
    } else {
      errorMessage.value = e.message.isNotEmpty
          ? e.message
          : 'Something went wrong.';
    }
  }

  /// Optional: call this from any screen's `onInit()` to clear stale errors.
  void clearError() => errorMessage.value = null;

  // LOGOUT

  Future<void> logout() async {
    print('🔐 [AuthService] Logging out');
    await _api.clearAuthSession();
    currentUser.value = null;
    isLoggedIn.value = false;
    errorMessage.value = null;
    Get.offAllNamed(AppRoutes.LOGIN);
  }

  // 401 HANDLER
  void _onUnauthorized() {
    if (!isLoggedIn.value) return;
    print('🔐 [AuthService] 401 received — forcing logout');
    Future.microtask(() async {
      await _api.clearAuthSession();
      currentUser.value = null;
      isLoggedIn.value = false;
      Get.offAllNamed(AppRoutes.LOGIN);
    });
  }
}