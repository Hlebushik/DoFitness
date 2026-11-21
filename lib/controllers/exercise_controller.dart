import 'package:get/get.dart';
import '../models/exercise_model.dart';
import '../services/api_service.dart';
import 'auth_controller.dart';
import 'settings_controller.dart';

class ExerciseController extends GetxController {
  final ApiService _api = ApiService();
  final AuthController _auth = Get.find<AuthController>();
  final SettingsController _settings = Get.find<SettingsController>();

  final RxList<ExerciseModel> allExercises = <ExerciseModel>[].obs;
  final RxBool isLoading = false.obs;
  final RxString errorMessage = ''.obs;

  final RxBool favoritesOnly = false.obs;
  final RxString selectedCategory = 'all'.obs;
  final RxString searchQuery = ''.obs;

  @override
  void onInit() {
    super.onInit();
    fetchExercises();
  }

  Future<void> fetchExercises() async {
    isLoading.value = true;
    errorMessage.value = '';
    try {
      final list = await _api.getExercises(
        token: _auth.token.value,
        lang: _settings.localeCode.value,
      );
      allExercises.assignAll(list);
    } on ApiException catch (e) {
      errorMessage.value = e.message;
    } finally {
      isLoading.value = false;
    }
  }

  List<ExerciseModel> get filteredExercises {
    final query = searchQuery.value.trim().toLowerCase();
    return allExercises.where((ex) {
      if (favoritesOnly.value && !ex.isFavorite) return false;
      if (selectedCategory.value != 'all' &&
          ex.category != selectedCategory.value) {
        return false;
      }
      if (query.isNotEmpty) {
        final matchName = ex.name.toLowerCase().contains(query) ||
            ex.nameEn.toLowerCase().contains(query) ||
            ex.nameUk.toLowerCase().contains(query);
        if (!matchName) return false;
      }
      return true;
    }).toList();
  }

  int get favoritesCount => allExercises.where((e) => e.isFavorite).length;

  Future<void> toggleFavorite(ExerciseModel exercise) async {
    if (!_auth.isAuthenticated) return;

    final index = allExercises.indexWhere((e) => e.slug == exercise.slug);
    if (index == -1) return;

    final previousState = allExercises[index].isFavorite;
    allExercises[index] = allExercises[index].copyWith(isFavorite: !previousState);

    try {
      final confirmedState = await _api.toggleFavorite(
        token: _auth.token.value,
        slug: exercise.slug,
      );
      allExercises[index] =
          allExercises[index].copyWith(isFavorite: confirmedState);
    } on ApiException catch (e) {
      allExercises[index] =
          allExercises[index].copyWith(isFavorite: previousState);
      Get.snackbar(
        'error_title'.tr,
        e.message,
        snackPosition: SnackPosition.BOTTOM,
        duration: const Duration(seconds: 2),
      );
    }
  }
}