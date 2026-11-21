import 'dart:ui';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'controllers/auth_controller.dart';
import 'controllers/settings_controller.dart';
import 'controllers/theme_controller.dart';
import 'pages/home/home_page.dart';
import 'pages/welcome/welcome_page.dart';
import 'translations/app_translations.dart';

class AppScrollBehavior extends MaterialScrollBehavior {
  @override
  Set<PointerDeviceKind> get dragDevices => {
        PointerDeviceKind.touch,
        PointerDeviceKind.mouse,
        PointerDeviceKind.trackpad,
        PointerDeviceKind.stylus,
      };

  @override
  Widget buildScrollbar(
    BuildContext context,
    Widget child,
    ScrollableDetails details,
  ) {
    return child;
  }
}

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  final settings =
      await Get.putAsync<SettingsController>(() => SettingsController().init());
  final theme =
      await Get.putAsync<ThemeController>(() => ThemeController().init());
  final auth = await Get.putAsync<AuthController>(() => AuthController().init());

  runApp(
    MyApp(
      isLoggedIn: auth.isAuthenticated,
      initialLocale: settings.currentLocale,
      initialThemeMode: theme.themeMode,
    ),
  );
}

class MyApp extends StatelessWidget {
  const MyApp({
    super.key,
    required this.isLoggedIn,
    required this.initialLocale,
    required this.initialThemeMode,
  });

  final bool isLoggedIn;
  final Locale initialLocale;
  final ThemeMode initialThemeMode;

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Do Fitness',
      debugShowCheckedModeBanner: false,
      translations: AppTranslations(),
      locale: initialLocale,
      fallbackLocale: const Locale('en', 'US'),
      scrollBehavior: AppScrollBehavior(),
      theme: ThemeData.light(useMaterial3: true),
      darkTheme: ThemeData.dark(useMaterial3: true),
      themeMode: initialThemeMode,
      home: isLoggedIn ? HomePage() : const WelcomePage(),
    );
  }
}