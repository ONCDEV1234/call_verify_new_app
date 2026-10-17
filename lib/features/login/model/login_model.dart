
class AuthUser {
  final int id;
  final String name;
  final String email;
  final String mobile;
  final String role;
  final String clientCode;
  final bool isActive;

  const AuthUser({
    required this.id,
    required this.name,
    required this.email,
    required this.mobile,
    required this.role,
    required this.clientCode,
    required this.isActive,
  });

  factory AuthUser.fromJson(Map<String, dynamic> json) {
    return AuthUser(
      id: (json['id'] as num?)?.toInt() ?? 0,
      name: json['name']?.toString() ?? '',
      email: json['email']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
      role: json['role']?.toString() ?? '',
      clientCode: json['client_code']?.toString() ?? '',
      isActive: json['is_active'] == true,
    );
  }

  Map<String, dynamic> toJson() {
    return {
      'id': id,
      'name': name,
      'email': email,
      'mobile': mobile,
      'role': role,
      'client_code': clientCode,
      'is_active': isActive,
    };
  }

  bool get isAdmin {
    return role == 'platform_admin' ||
        role == 'admin' ||
        role == 'super_admin';
  }
}


enum OtpFlow {
  login,
  signup,
}


class MobileSignupRequest {
  final String name;
  final String firstName;
  final String lastName;
  final String email;
  final String dateOfBirth;
  final String mobile;

  const MobileSignupRequest({
    required this.name,
    required this.firstName,
    required this.lastName,
    required this.email,
    required this.dateOfBirth,
    required this.mobile,
  });

  Map<String, dynamic> toJson() {
    return {
      'name': name.trim(),
      'first_name': firstName.trim(),
      'last_name': lastName.trim(),
      'email': email.trim(),
      'date_of_birth': dateOfBirth,
      'mobile': mobile.trim(),
    };
  }
}



class MobileOtpResponse {
  final bool success;
  final String message;
  final String mobile;

  const MobileOtpResponse({
    required this.success,
    required this.message,
    required this.mobile,
  });

  factory MobileOtpResponse.fromJson(Map<String, dynamic> json) {
    return MobileOtpResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      mobile: json['mobile']?.toString() ?? '',
    );
  }
}


class MobileOtpVerifyRequest {
  final String mobile;
  final String otp;

  const MobileOtpVerifyRequest({
    required this.mobile,
    required this.otp,
  });

  Map<String, dynamic> toJson() {
    return {
      'mobile': mobile.trim(),
      'otp': otp.trim(),
    };
  }
}


class MobileLoginResponse {
  final bool success;
  final String message;
  final String accessToken;
  final String tokenType;
  final AuthUser user;

  const MobileLoginResponse({
    required this.success,
    required this.message,
    required this.accessToken,
    required this.tokenType,
    required this.user,
  });

  factory MobileLoginResponse.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];

    return MobileLoginResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
      user: AuthUser.fromJson(
        userMap is Map
            ? Map<String, dynamic>.from(userMap)
            : <String, dynamic>{},
      ),
    );
  }
}


class MobileSignupResponse {
  final bool success;
  final String message;
  final AuthUser user;
  final String accessToken;
  final String tokenType;

  const MobileSignupResponse({
    required this.success,
    required this.message,
    required this.user,
    required this.accessToken,
    required this.tokenType,
  });

  factory MobileSignupResponse.fromJson(Map<String, dynamic> json) {
    final userMap = json['user'];

    return MobileSignupResponse(
      success: json['success'] == true,
      message: json['message']?.toString() ?? '',
      user: AuthUser.fromJson(
        userMap is Map
            ? Map<String, dynamic>.from(userMap)
            : <String, dynamic>{},
      ),
      accessToken: json['access_token']?.toString() ?? '',
      tokenType: json['token_type']?.toString() ?? 'bearer',
    );
  }
}


