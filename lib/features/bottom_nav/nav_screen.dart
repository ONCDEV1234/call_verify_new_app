
import 'package:calling_app/features/home/screen/home_screen.dart';
import 'package:calling_app/features/profile/screen/profile_screen.dart';
import 'package:calling_app/features/reports/screen/reports_screen.dart';
import 'package:flutter/material.dart';
import 'package:get/get.dart';



import '../dashboard/screen/dashboard_screen.dart';
import 'nav_controller.dart';


class BottomNavScreen extends StatelessWidget {
  const BottomNavScreen({super.key});

  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _textGrey = Color(0xFF777777);
  static const Color _bg = Color(0xFFF7F7F7);

  @override
  Widget build(BuildContext context) {
    final c = Get.put(BottomNavController(), tag: 'bottomnav');

    final pages = <Widget>[
      const HomeScreen(),
       DashboardScreen(),
      const ProfileScreen(),
    ];

    return Scaffold(
      backgroundColor: _bg,
      body: Obx(
            () => IndexedStack(
          index: c.currentIndex.value,
          children: pages,
        ),
      ),
      bottomNavigationBar: Obx(
            () => _buildBottomBar(c),
      ),
    );
  }


  Widget _buildBottomBar(BottomNavController c) {
    final idx = c.currentIndex.value;

    return Container(
      decoration: BoxDecoration(
        color: Colors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.06),
            blurRadius: 12,
            offset: const Offset(0, -3),
          ),
        ],
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 62,
          child: Row(
            children: List.generate(3, (i) {
              final active = i == idx;
              return Expanded(
                child: _buildTab(
                  index: i,
                  label: c.titles[i],
                  icon: c.iconFor(i, active: active),
                  active: active,
                  onTap: () => c.changeTab(i),
                ),
              );
            }),
          ),
        ),
      ),
    );
  }

  Widget _buildTab({
    required int index,
    required String label,
    required IconData icon,
    required bool active,
    required VoidCallback onTap,
  }) {
    return InkWell(
      onTap: onTap,
      splashColor: _primaryRed.withOpacity(0.06),
      highlightColor: Colors.transparent,
      child: AnimatedContainer(
        duration: const Duration(milliseconds: 180),
        padding: const EdgeInsets.symmetric(vertical: 6),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            // Icon with an active red pill behind it
            AnimatedContainer(
              duration: const Duration(milliseconds: 180),
              padding: const EdgeInsets.symmetric(
                horizontal: 14,
                vertical: 3,
              ),
              decoration: BoxDecoration(
                color: active
                    ? _primaryRed.withOpacity(0.10)
                    : Colors.transparent,
                borderRadius: BorderRadius.circular(20),
              ),
              child: Icon(
                icon,
                size: 22,
                color: active ? _primaryRed : _textGrey,
              ),
            ),
            const SizedBox(height: 2),
            Text(
              label,
              style: TextStyle(
                fontSize: 11,
                fontWeight: active ? FontWeight.w700 : FontWeight.w500,
                color: active ? _primaryRed : _textGrey,
              ),
            ),
          ],
        ),
      ),
    );
  }
}