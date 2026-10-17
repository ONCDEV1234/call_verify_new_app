// lib/app/data/providers/api_provider.dart

import 'dart:async';
import 'dart:convert';
import 'dart:io';

import 'package:flutter/foundation.dart' show kDebugMode, VoidCallback;
import 'package:get/get.dart';
import 'package:http/http.dart' as http;
import 'package:shared_preferences/shared_preferences.dart';

class ApiProvider extends GetxService {
  // ═══════════════════════════════════════════════════════════
  // CONFIG
  // ═══════════════════════════════════════════════════════════
  static const String baseUrl = 'https://jansetu.leadtech.in';
  static const String apiPrefix = '/api/leadtech/api/v1';
  static const String authPrefix = '/api/leadtech/api/v1';

  // ═══════════════════════════════════════════════════════════
  // AUTH STATE
  // ═══════════════════════════════════════════════════════════
  String? _authToken;
  String? _clientCode;

  String get authToken => _authToken ?? '';
  String get clientCode => _clientCode ?? '';
  bool get hasToken => (_authToken ?? '').isNotEmpty;

  // ═══════════════════════════════════════════════════════════
  // 401 CALLBACK — set by AuthService
  // ═══════════════════════════════════════════════════════════
  VoidCallback? onUnauthorized;

  void _notifyUnauthorized() {
    try {
      onUnauthorized?.call();
    } catch (e) {
      _log('⚠️ [Api] onUnauthorized callback failed: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // BOOT
  // ═══════════════════════════════════════════════════════════
  Future<ApiProvider> init() async {
    final prefs = await SharedPreferences.getInstance();
    _authToken = prefs.getString('auth_token');
    _clientCode = prefs.getString('client_code');
    _log('🔑 [Api] Initialized — clientCode=${_clientCode ?? '<none>'}');
    return this;
  }

  // ═══════════════════════════════════════════════════════════
  // SESSION
  // ═══════════════════════════════════════════════════════════
  Future<void> setAuthSession({
    required String token,
    required String clientCode,
  }) async {
    _authToken = token;
    _clientCode = clientCode;

    final prefs = await SharedPreferences.getInstance();
    await prefs.setString('auth_token', token);
    await prefs.setString('client_code', clientCode);

    _log('🔑 [Api] Session saved — clientCode=$clientCode');
  }

  Future<void> clearAuthSession() async {
    _authToken = null;
    _clientCode = null;

    final prefs = await SharedPreferences.getInstance();
    await prefs.remove('auth_token');
    await prefs.remove('client_code');
    await prefs.remove('auth_user');

    _log('🔑 [Api] Session cleared');
  }

  // ═══════════════════════════════════════════════════════════
  // HEADERS
  // ═══════════════════════════════════════════════════════════
  Map<String, String> get _headers {
    final headers = <String, String>{
      'Content-Type': 'application/json',
      'Accept': 'application/json',
    };
    if (hasToken) {
      headers['Authorization'] = 'Bearer $_authToken';
    }
    return headers;
  }

  // ═══════════════════════════════════════════════════════════
  // HTTP VERBS
  // ═══════════════════════════════════════════════════════════
  Future<Map<String, dynamic>> get(String url) async {
    final fullUrl = '$baseUrl$url';
    _log('🌐 [GET] $fullUrl');

    try {
      final response = await http
          .get(Uri.parse(fullUrl), headers: _headers)
          .timeout(const Duration(seconds: 60));

      _log('📥 [GET] ${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Request timed out', isNetworkError: true);
    } on SocketException catch (e) {
      throw ApiException('No internet: ${e.message}', isNetworkError: true);
    } on http.ClientException catch (e) {
      throw ApiException('Connection failed: ${e.message}', isNetworkError: true);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> post(
      String url,
      Map<String, dynamic> body,
      ) async {
    final fullUrl = '$baseUrl$url';
    _log('🌐 [POST] $fullUrl');
    _log('🌐 [POST] body: ${jsonEncode(body)}');

    try {
      final response = await http
          .post(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 60));

      _log('📥 [POST] ${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Request timed out', isNetworkError: true);
    } on SocketException catch (e) {
      throw ApiException('No internet: ${e.message}', isNetworkError: true);
    } on http.ClientException catch (e) {
      throw ApiException('Connection failed: ${e.message}', isNetworkError: true);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> put(
      String url,
      Map<String, dynamic> body,
      ) async {
    final fullUrl = '$baseUrl$url';
    _log('🌐 [PUT] $fullUrl');

    try {
      final response = await http
          .put(
        Uri.parse(fullUrl),
        headers: _headers,
        body: jsonEncode(body),
      )
          .timeout(const Duration(seconds: 60));

      _log('📥 [PUT] ${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Request timed out', isNetworkError: true);
    } on SocketException catch (e) {
      throw ApiException('No internet: ${e.message}', isNetworkError: true);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  Future<Map<String, dynamic>> delete(String url) async {
    final fullUrl = '$baseUrl$url';
    _log('🌐 [DELETE] $fullUrl');

    try {
      final response = await http
          .delete(Uri.parse(fullUrl), headers: _headers)
          .timeout(const Duration(seconds: 60));

      _log('📥 [DELETE] ${response.statusCode}');
      return _handleResponse(response);
    } on ApiException {
      rethrow;
    } on TimeoutException {
      throw ApiException('Request timed out', isNetworkError: true);
    } on SocketException catch (e) {
      throw ApiException('No internet: ${e.message}', isNetworkError: true);
    } catch (e) {
      throw ApiException('Unexpected error: $e');
    }
  }

  // ═══════════════════════════════════════════════════════════
  // RESPONSE HANDLER
  // ═══════════════════════════════════════════════════════════
  Map<String, dynamic> _handleResponse(http.Response response) {
    Map<String, dynamic> body = {};
    if (response.body.isNotEmpty) {
      try {
        final decoded = jsonDecode(response.body);
        body = decoded is Map<String, dynamic> ? decoded : {'data': decoded};
      } catch (_) {
        body = {'raw': response.body};
      }
    }

    final code = response.statusCode;

    if (code >= 200 && code < 300) return body;

    final detail = body['detail']?.toString() ??
        body['message']?.toString() ??
        'Request failed';

    if (code == 401) {
      _log('🔒 [API] 401 UNAUTHORIZED');
      _notifyUnauthorized(); // 👈 fires AuthService._onUnauthorized
      throw ApiException(
        'Unauthorized: $detail',
        statusCode: 401,
        isAuthError: true,
      );
    }
    if (code == 403) {
      throw ApiException(
        'Forbidden: $detail',
        statusCode: 403,
        isAuthError: true,
      );
    }
    if (code >= 400 && code < 500) {
      throw ApiException('Client error ($code): $detail', statusCode: code);
    }
    if (code >= 500) {
      throw ApiException('Server error ($code): $detail', statusCode: code);
    }

    throw ApiException('Unexpected status $code', statusCode: code);
  }

  // ═══════════════════════════════════════════════════════════
  // LOG
  // ═══════════════════════════════════════════════════════════
  void _log(String message) {
    if (kDebugMode) print(message);
  }
}

// ═══════════════════════════════════════════════════════════
// EXCEPTION
// ═══════════════════════════════════════════════════════════
class ApiException implements Exception {
  final String message;
  final int? statusCode;
  final bool isAuthError;
  final bool isNetworkError;

  ApiException(
      this.message, {
        this.statusCode,
        this.isAuthError = false,
        bool? isNetworkError,
      }) : isNetworkError =
      isNetworkError ?? (statusCode == null && !isAuthError);

  @override
  String toString() => 'ApiException(${statusCode ?? 'none'}): $message';
}