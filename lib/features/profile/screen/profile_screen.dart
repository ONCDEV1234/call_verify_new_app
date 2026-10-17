// lib/app/modules/profile/view/profile_screen.dart

import 'package:flutter/material.dart';
import 'package:get/get.dart';

import '../../login/controller/auth_service.dart';

class ProfileScreen extends StatelessWidget {
  const ProfileScreen({super.key});

  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _borderGrey = Color(0xFFE2E2E2);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();
    final user = auth.currentUser.value;

    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: SingleChildScrollView(
          padding: const EdgeInsets.fromLTRB(20, 24, 20, 24),
          child: Column(
            children: [
              // ── AVATAR ────────────────────────────────────
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.person_rounded,
                  size: 46,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(height: 14),

              // ── NAME ──────────────────────────────────────
              Text(
                user?.name.isNotEmpty == true ? user!.name : 'User',
                style: const TextStyle(
                  fontSize: 20,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
              const SizedBox(height: 4),

              // ── MOBILE ────────────────────────────────────
              Text(
                user?.mobile.isNotEmpty == true
                    ? '+91 ${user!.mobile}'
                    : '—',
                style: const TextStyle(fontSize: 13, color: _textGrey),
              ),

              const SizedBox(height: 26),

              // ── INFO CARD ─────────────────────────────────
              Container(
                width: double.infinity,
                padding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: Colors.white,
                  borderRadius: BorderRadius.circular(16),
                  boxShadow: [
                    BoxShadow(
                      color: Colors.black.withOpacity(0.05),
                      blurRadius: 12,
                      offset: const Offset(0, 4),
                    ),
                  ],
                ),
                child: Column(
                  children: [
                    _infoRow(
                      icon: Icons.email_outlined,
                      label: 'Email',
                      value: user?.email.isNotEmpty == true
                          ? user!.email
                          : '—',
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.badge_outlined,
                      label: 'Role',
                      value: user?.role.isNotEmpty == true
                          ? user!.role
                          : '—',
                    ),
                    _divider(),
                    _infoRow(
                      icon: Icons.business_outlined,
                      label: 'Client Code',
                      value: user?.clientCode.isNotEmpty == true
                          ? user!.clientCode
                          : '—',
                    ),
                  ],
                ),
              ),

              const SizedBox(height: 24),

              // ── LOGOUT BUTTON ─────────────────────────────
              SizedBox(
                width: double.infinity,
                height: 46,
                child: OutlinedButton.icon(
                  onPressed: () async {
                    final confirmed = await Get.dialog<bool>(
                      AlertDialog(
                        title: const Text('Logout'),
                        content: const Text(
                          'Are you sure you want to logout?',
                        ),
                        actions: [
                          TextButton(
                            onPressed: () => Get.back(result: false),
                            child: const Text(
                              'Cancel',
                              style: TextStyle(color: _textGrey),
                            ),
                          ),
                          TextButton(
                            onPressed: () => Get.back(result: true),
                            child: const Text(
                              'Logout',
                              style: TextStyle(color: _primaryRed),
                            ),
                          ),
                        ],
                      ),
                    );
                    if (confirmed == true) {
                      await auth.logout();
                    }
                  },
                  icon: const Icon(Icons.logout_rounded, size: 18),
                  label: const Text(
                    'Logout',
                    style: TextStyle(
                      fontSize: 13,
                      fontWeight: FontWeight.w700,
                    ),
                  ),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: _primaryRed,
                    side: const BorderSide(color: _primaryRed, width: 1),
                    shape: RoundedRectangleBorder(
                      borderRadius: BorderRadius.circular(10),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  Widget _infoRow({
    required IconData icon,
    required String label,
    required String value,
  }) {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 14),
      child: Row(
        children: [
          Icon(icon, size: 18, color: _primaryRed),
          const SizedBox(width: 12),
          Expanded(
            child: Text(
              label,
              style: const TextStyle(
                fontSize: 13,
                color: _textGrey,
                fontWeight: FontWeight.w500,
              ),
            ),
          ),
          Flexible(
            child: Text(
              value,
              textAlign: TextAlign.right,
              overflow: TextOverflow.ellipsis,
              style: const TextStyle(
                fontSize: 13,
                color: _textBlack,
                fontWeight: FontWeight.w600,
              ),
            ),
          ),
        ],
      ),
    );
  }

  Widget _divider() => Container(height: 1, color: _borderGrey);
}