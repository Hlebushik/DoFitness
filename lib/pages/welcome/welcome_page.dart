import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:lottie/lottie.dart';
import '../login/login_page.dart';

class WelcomePage extends StatelessWidget {
  const WelcomePage({super.key});

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.symmetric(horizontal: 24.0, vertical: 16.0),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                ConstrainedBox(
                  constraints: const BoxConstraints(
                    maxWidth: 380,
                    maxHeight: 380,
                  ),
                  child: Lottie.asset(
                    'assets/lotties/welcome_screen.json',
                    fit: BoxFit.contain,
                  ),
                ),
                const SizedBox(height: 24),
                Text(
                  'Do Fitness Online',
                  textAlign: TextAlign.center,
                  style: Theme.of(context).textTheme.headlineMedium?.copyWith(
                        fontWeight: FontWeight.bold,
                        letterSpacing: 4.0,
                      ),
                ),
                const SizedBox(height: 32),
                ConstrainedBox(
                  constraints: const BoxConstraints(maxWidth: 360),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      FilledButton(
                        onPressed: () => Get.to(() => const LoginPage()),
                        style: FilledButton.styleFrom(
                          minimumSize: const Size(double.infinity, 48),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('login'.tr),
                      ),
                      const SizedBox(height: 12),
                      TextButton(
                        onPressed: () => Get.to(
                          () => const LoginPage(),
                        ),
                        style: TextButton.styleFrom(
                          minimumSize: const Size(double.infinity, 44),
                          shape: const StadiumBorder(),
                        ),
                        child: Text('register'.tr),
                      ),
                    ],
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}