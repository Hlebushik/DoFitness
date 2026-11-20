import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:online_trainer/controllers/theme_controller.dart';
import 'package:online_trainer/pages/streaming/streaming_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ThemeController themeController = Get.find<ThemeController>();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('Do Fitness Online'),
        centerTitle: true,
        actions: [
          IconButton(
            onPressed: themeController.toggleTheme,
            icon: Icon(Icons.dark_mode),
          ),
        ],
      ),
      body: Center(
        child: ElevatedButton(
          onPressed: () {
            Get.to(() => const StreamingPage());
          },
          child: const Text('Перейти до трансляції'),
        ),
      ),
    );
  }
}
