import 'dart:io';
import 'package:flutter/material.dart';
import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';

class SettingsController extends GetxController {
  static const _keyLocale = 'settings_locale_code';

  final RxString localeCode = 'uk'.obs;
  final int connectionTimeoutSeconds = 5;

  late SharedPreferences _prefs;

  String get _host => Platform.isAndroid ? '10.0.2.2:8000' : '127.0.0.1:8000';
  String get httpBaseUrl => 'http://$_host';
  String get wsBaseUrl => 'ws://$_host';

  Locale get currentLocale =>
      localeCode.value == 'en' ? const Locale('en', 'US') : const Locale('uk', 'UA');

  Future<SettingsController> init() async {
    _prefs = await SharedPreferences.getInstance();
    localeCode.value = _prefs.getString(_keyLocale) ?? 'uk';
    return this;
  }

  Future<void> setLocaleCode(String code) async {
    final normalized = code == 'en' ? 'en' : 'uk';
    localeCode.value = normalized;
    await _prefs.setString(_keyLocale, normalized);
    Get.updateLocale(
      normalized == 'en' ? const Locale('en', 'US') : const Locale('uk', 'UA'),
    );
  }
}