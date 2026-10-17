
import 'package:flutter/material.dart';
import 'package:get/get.dart';

class BottomNavController extends GetxController {
  final RxInt currentIndex = 0.obs;

  final List<String> titles = const [
    'Home',
    'Reports',
    'Profile',
  ];

  void changeTab(int index) {
    if (index == currentIndex.value) return;
    currentIndex.value = index;
  }

  IconData iconFor(int index, {required bool active}) {
    switch (index) {
      case 0:
        return active ? Icons.home_rounded : Icons.home_outlined;
      case 1:
        return active
            ? Icons.bar_chart_rounded
            : Icons.bar_chart_outlined;
      case 2:
        return active ? Icons.person_rounded : Icons.person_outline;
      default:
        return Icons.circle_outlined;
    }
  }
}