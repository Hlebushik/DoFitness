import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/exercise_controller.dart';
import '../../controllers/theme_controller.dart';
import '../../models/exercise_model.dart';
import '../profile/profile_page.dart';
import '../streaming/streaming_page.dart';

class HomePage extends StatelessWidget {
  HomePage({super.key});

  final ThemeController themeController = Get.find<ThemeController>();
  final AuthController authController = Get.find<AuthController>();
  final ExerciseController exerciseController =
      Get.put(ExerciseController());

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text('app_title'.tr),
        centerTitle: true,
        actions: [
          Obx(
            () => IconButton(
              tooltip: 'dark_mode'.tr,
              onPressed: themeController.toggleTheme,
              icon: Icon(
                themeController.isDarkMode.value
                    ? Icons.light_mode_outlined
                    : Icons.dark_mode_outlined,
              ),
            ),
          ),
          IconButton(
            tooltip: 'profile_and_settings'.tr,
            onPressed: () => Get.to(() => const ProfilePage()),
            icon: const Icon(Icons.account_circle_outlined),
          ),
        ],
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 960),
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 12, 16, 0),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Obx(() {
                    final username =
                        authController.currentUser.value?.username ?? '';
                    final favCount = exerciseController.favoritesCount;
                    final isFavTab = exerciseController.favoritesOnly.value;

                    return Wrap(
                      alignment: WrapAlignment.spaceBetween,
                      crossAxisAlignment: WrapCrossAlignment.center,
                      spacing: 12,
                      runSpacing: 10,
                      children: [
                        Text(
                          username.isNotEmpty
                              ? 'greeting_user'.trParams({'name': username})
                              : 'exercise_library'.tr,
                          style: Theme.of(context)
                              .textTheme
                              .titleLarge
                              ?.copyWith(fontWeight: FontWeight.bold),
                        ),
                        SegmentedButton<bool>(
                          segments: [
                            ButtonSegment<bool>(
                              value: false,
                              icon: const Icon(Icons.grid_view_rounded, size: 18),
                              label: Text('all_exercises'.tr),
                            ),
                            ButtonSegment<bool>(
                              value: true,
                              icon: const Icon(Icons.favorite, size: 18),
                              label: Text(
                                'favorites_tab'.trParams({'count': '$favCount'}),
                              ),
                            ),
                          ],
                          selected: {isFavTab},
                          onSelectionChanged: (selection) {
                            exerciseController.favoritesOnly.value =
                                selection.first;
                          },
                        ),
                      ],
                    );
                  }),
                  const SizedBox(height: 12),

                  TextField(
                    onChanged: (val) =>
                        exerciseController.searchQuery.value = val,
                    decoration: InputDecoration(
                      hintText: 'search_exercises'.tr,
                      prefixIcon: const Icon(Icons.search),
                      isDense: true,
                      border: OutlineInputBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                    ),
                  ),
                  const SizedBox(height: 10),
                  Obx(() {
                    final cat = exerciseController.selectedCategory.value;
                    return SingleChildScrollView(
                      scrollDirection: Axis.horizontal,
                      child: Row(
                        children: [
                          ChoiceChip(
                            label: Text('all_categories'.tr),
                            selected: cat == 'all',
                            onSelected: (_) =>
                                exerciseController.selectedCategory.value = 'all',
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('bodyweight'.tr),
                            selected: cat == 'bodyweight',
                            onSelected: (_) => exerciseController
                                .selectedCategory.value = 'bodyweight',
                          ),
                          const SizedBox(width: 8),
                          ChoiceChip(
                            label: Text('weighted'.tr),
                            selected: cat == 'weighted',
                            onSelected: (_) => exerciseController
                                .selectedCategory.value = 'weighted',
                          ),
                        ],
                      ),
                    );
                  }),
                  const SizedBox(height: 12),

                  Expanded(
                    child: Obx(() {
                      if (exerciseController.isLoading.value) {
                        return const Center(child: CircularProgressIndicator());
                      }

                      if (exerciseController.errorMessage.value.isNotEmpty) {
                        return Center(
                          child: Column(
                            mainAxisSize: MainAxisSize.min,
                            children: [
                              Text(
                                exerciseController.errorMessage.value,
                                textAlign: TextAlign.center,
                              ),
                              const SizedBox(height: 12),
                              ElevatedButton.icon(
                                onPressed: exerciseController.fetchExercises,
                                icon: const Icon(Icons.refresh),
                                label: Text('refresh'.tr),
                              ),
                            ],
                          ),
                        );
                      }

                      final items = exerciseController.filteredExercises;
                      if (items.isEmpty) {
                        return Center(
                          child: Text(
                            exerciseController.favoritesOnly.value
                                ? 'no_favorites_yet'.tr
                                : 'no_exercises_found'.tr,
                            textAlign: TextAlign.center,
                            style: Theme.of(context).textTheme.bodyMedium,
                          ),
                        );
                      }

                      return LayoutBuilder(
                        builder: (context, constraints) {
                          final isWide = constraints.maxWidth >= 680;
                          if (isWide) {
                            return GridView.builder(
                              padding: const EdgeInsets.only(bottom: 16),
                              gridDelegate:
                                  const SliverGridDelegateWithFixedCrossAxisCount(
                                crossAxisCount: 2,
                                mainAxisSpacing: 12,
                                crossAxisSpacing: 12,
                                mainAxisExtent: 152,
                              ),
                              itemCount: items.length,
                              itemBuilder: (context, index) => _ExerciseCard(
                                exercise: items[index],
                                onTap: () => Get.to(
                                  () => StreamingPage(exercise: items[index]),
                                ),
                                onToggleFavorite: () => exerciseController
                                    .toggleFavorite(items[index]),
                              ),
                            );
                          }

                          return ListView.separated(
                            padding: const EdgeInsets.only(bottom: 16),
                            itemCount: items.length,
                            separatorBuilder: (_, __) =>
                                const SizedBox(height: 10),
                            itemBuilder: (context, index) => _ExerciseCard(
                              exercise: items[index],
                              onTap: () => Get.to(
                                () => StreamingPage(exercise: items[index]),
                              ),
                              onToggleFavorite: () => exerciseController
                                  .toggleFavorite(items[index]),
                            ),
                          );
                        },
                      );
                    }),
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}

class _ExerciseCard extends StatelessWidget {
  const _ExerciseCard({
    required this.exercise,
    required this.onTap,
    required this.onToggleFavorite,
  });

  final ExerciseModel exercise;
  final VoidCallback onTap;
  final VoidCallback onToggleFavorite;

  @override
  Widget build(BuildContext context) {
    final isWeighted = exercise.category == 'weighted';
    final categoryLabel = isWeighted ? 'weighted'.tr : 'bodyweight'.tr;
    final difficultyLabel =
        exercise.difficulty == 'intermediate' ? 'intermediate'.tr : 'beginner'.tr;

    return Card(
      clipBehavior: Clip.antiAlias,
      child: InkWell(
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.all(14.0),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Row(
                children: [
                  CircleAvatar(
                    radius: 18,
                    child: Icon(
                      isWeighted
                          ? Icons.fitness_center
                          : Icons.accessibility_new,
                      size: 18,
                    ),
                  ),
                  const SizedBox(width: 10),
                  Expanded(
                    child: Text(
                      exercise.name,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                      style: const TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w600,
                      ),
                    ),
                  ),
                  IconButton(
                    visualDensity: VisualDensity.compact,
                    tooltip: exercise.isFavorite
                        ? 'remove_from_favorites'.tr
                        : 'add_to_favorites'.tr,
                    onPressed: onToggleFavorite,
                    icon: Icon(
                      exercise.isFavorite
                          ? Icons.favorite
                          : Icons.favorite_border,
                      color: exercise.isFavorite ? Colors.redAccent : null,
                    ),
                  ),
                ],
              ),
              const SizedBox(height: 6),
              Text(
                exercise.description,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
                style: Theme.of(context).textTheme.bodySmall,
              ),
              const SizedBox(height: 8),
              Row(
                children: [
                  Text(
                    '$categoryLabel • $difficultyLabel',
                    style: TextStyle(
                      fontSize: 12,
                      color: Theme.of(context).colorScheme.primary,
                      fontWeight: FontWeight.w500,
                    ),
                  ),
                  const Spacer(),
                  const Icon(Icons.play_arrow_rounded, size: 20),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}