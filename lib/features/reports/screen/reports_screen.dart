// lib/app/modules/reports/view/reports_screen.dart

import 'package:flutter/material.dart';

class ReportsScreen extends StatelessWidget {
  const ReportsScreen({super.key});

  static const Color _primaryRed = Color(0xFFD71920);
  static const Color _bg = Color(0xFFF7F7F7);
  static const Color _textBlack = Color(0xFF222222);
  static const Color _textGrey = Color(0xFF777777);

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      backgroundColor: _bg,
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.center,
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              Container(
                width: 90,
                height: 90,
                decoration: BoxDecoration(
                  color: _primaryRed.withOpacity(0.10),
                  shape: BoxShape.circle,
                ),
                child: const Icon(
                  Icons.bar_chart_rounded,
                  size: 46,
                  color: _primaryRed,
                ),
              ),
              const SizedBox(height: 20),
              const Text(
                'Reports',
                style: TextStyle(
                  fontSize: 24,
                  fontWeight: FontWeight.w700,
                  color: _textBlack,
                ),
              ),
              const SizedBox(height: 8),
              const Text(
                'Your reports and analytics will appear here.',
                textAlign: TextAlign.center,
                style: TextStyle(fontSize: 13, color: _textGrey),
              ),
            ],
          ),
        ),
      ),
    );
  }
}