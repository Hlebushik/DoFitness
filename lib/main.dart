import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:online_trainer/controllers/theme_controller.dart';
import 'package:online_trainer/pages/welcome/welcome_page.dart';

void main() {
  Get.put(ThemeController());
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return GetMaterialApp(
      title: 'Online Trainer',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        brightness: Brightness.light,
        primarySwatch: Colors.purple),
      darkTheme: ThemeData(
        brightness: Brightness.dark,
        primarySwatch: Colors.purple
      ),
      themeMode: ThemeMode.light,
      home: WelcomePage(),
    );
  }
}