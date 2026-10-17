import 'package:flutter/material.dart';
import 'package:flutter_screenutil/flutter_screenutil.dart';
import 'package:get/get.dart';

import 'core/network/api_provider.dart';
import 'core/route/app_routes.dart';
import 'features/login/controller/auth_service.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Get.putAsync<ApiProvider>(() => ApiProvider().init(), permanent: true);
  await Get.putAsync<AuthService>(() => AuthService().init(), permanent: true);

  runApp(const CallVerifyApp());
}

class CallVerifyApp extends StatelessWidget {
  const CallVerifyApp({super.key});

  static const Color _primaryRed = Color(0xFFD71920);

  @override
  Widget build(BuildContext context) {
    final auth = Get.find<AuthService>();

    return ScreenUtilInit(
      designSize: const Size(360, 800),   // 👈 baseline design size
      minTextAdapt: true,
      splitScreenMode: true,
      builder: (context, child) {
        return GetMaterialApp(
          title: 'Call Verify',
          debugShowCheckedModeBanner: false,
          theme: ThemeData(
            useMaterial3: true,
            colorScheme: ColorScheme.fromSeed(seedColor: _primaryRed),
            scaffoldBackgroundColor: const Color(0xFFF7F7F7),
          ),
          initialBinding: AppBinding(),
          initialRoute: auth.isLoggedIn.value
              ? AppRoutes.BOTTOMNAV
              : AppRoutes.LOGIN,
          getPages: AppPages.pages,
        );
      },
    );
  }
}