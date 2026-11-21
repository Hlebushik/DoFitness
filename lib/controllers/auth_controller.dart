import 'package:get/get.dart';
import 'package:shared_preferences/shared_preferences.dart';
import '../models/user_model.dart';
import '../pages/home/home_page.dart';
import '../pages/login/login_page.dart';
import '../services/api_service.dart';
import 'exercise_controller.dart';
import 'settings_controller.dart';

class AuthController extends GetxController {
  static const _keyToken = 'auth_access_token';

  final ApiService _api = ApiService();
  SettingsController get _settings => Get.find<SettingsController>();

  final Rx<UserModel?> currentUser = Rx<UserModel?>(null);
  final RxString token = ''.obs;
  final RxBool isLoading = false.obs;
  final RxString authError = ''.obs;

  bool get isAuthenticated => token.value.isNotEmpty && currentUser.value != null;

  Future<AuthController> init() async {
    final prefs = await SharedPreferences.getInstance();
    final savedToken = prefs.getString(_keyToken) ?? '';
    if (savedToken.isNotEmpty) {
      try {
        final user = await _api.getMe(savedToken);
        token.value = savedToken;
        currentUser.value = user;
        await _settings.setLocaleCode(user.preferredLocale);
      } catch (_) {
        await prefs.remove(_keyToken);
      }
    }
    return this;
  }

  Future<bool> login({
    required String email,
    required String password,
  }) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final result = await _api.login(email: email.trim(), password: password);
      await _persistSession(result);
      await _settings.setLocaleCode(result.user.preferredLocale);
      Get.offAll(() => HomePage());
      return true;
    } on ApiException catch (e) {
      authError.value = e.message;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> register({
    required String email,
    required String username,
    required String password,
  }) async {
    isLoading.value = true;
    authError.value = '';
    try {
      final result = await _api.register(
        email: email.trim(),
        username: username.trim(),
        password: password,
        preferredLocale: _settings.localeCode.value,
      );
      await _persistSession(result);
      Get.offAll(() => HomePage());
      return true;
    } on ApiException catch (e) {
      authError.value = e.message;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<bool> updateUsername(String newUsername) async {
    final trimmed = newUsername.trim();
    if (trimmed.length < 2 || token.value.isEmpty) return false;

    isLoading.value = true;
    try {
      final updated = await _api.updatePreferences(
        token: token.value,
        username: trimmed,
      );
      currentUser.value = updated;
      return true;
    } on ApiException catch (e) {
      authError.value = e.message;
      return false;
    } finally {
      isLoading.value = false;
    }
  }

  Future<void> changeLanguage(String langCode) async {
    await _settings.setLocaleCode(langCode);

    if (token.value.isNotEmpty) {
      try {
        final updated = await _api.updatePreferences(
          token: token.value,
          preferredLocale: langCode,
        );
        currentUser.value = updated;
      } catch (_) {
        if (currentUser.value != null) {
          currentUser.value =
              currentUser.value!.copyWith(preferredLocale: langCode);
        }
      }
    }

    if (Get.isRegistered<ExerciseController>()) {
      await Get.find<ExerciseController>().fetchExercises();
    }
  }

  Future<void> _persistSession(AuthResponse result) async {
    token.value = result.accessToken;
    currentUser.value = result.user;
    final prefs = await SharedPreferences.getInstance();
    await prefs.setString(_keyToken, result.accessToken);
  }

  Future<void> logout() async {
    token.value = '';
    currentUser.value = null;
    final prefs = await SharedPreferences.getInstance();
    await prefs.remove(_keyToken);
    Get.offAll(() => const LoginPage());
  }
}