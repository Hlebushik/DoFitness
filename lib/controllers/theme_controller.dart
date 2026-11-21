import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class ThemeController extends GetxController {
  static const _keyIsDark = 'settings_is_dark_mode';

  final RxBool isDarkMode = true.obs;
  late SharedPreferences _prefs;

  ThemeMode get themeMode => isDarkMode.value ? ThemeMode.dark : ThemeMode.light;

  Future<ThemeController> init() async {
    _prefs = await SharedPreferences.getInstance();
    isDarkMode.value = _prefs.getBool(_keyIsDark) ?? true;
    return this;
  }

  Future<void> setDarkMode(bool dark) async {
    isDarkMode.value = dark;
    Get.changeThemeMode(dark ? ThemeMode.dark : ThemeMode.light);
    await _prefs.setBool(_keyIsDark, dark);
  }

  Future<void> toggleTheme() async {
    await setDarkMode(!isDarkMode.value);
  }
}