import 'package:flutter/material.dart';
import 'package:get/get.dart';
import '../../controllers/auth_controller.dart';
import '../../controllers/settings_controller.dart';
import '../../controllers/theme_controller.dart';

class ProfilePage extends StatelessWidget {
  const ProfilePage({super.key});

  void _showEditUsernameDialog(AuthController auth) {
    final currentName = auth.currentUser.value?.username ?? '';
    final nameCtrl = TextEditingController(text: currentName);

    Get.dialog(
      AlertDialog(
        title: Text('edit_username'.tr),
        content: TextField(
          controller: nameCtrl,
          autofocus: true,
          decoration: InputDecoration(
            labelText: 'username'.tr,
            border: const OutlineInputBorder(),
          ),
        ),
        actions: [
          TextButton(
            onPressed: () => Get.back(),
            child: Text('cancel'.tr),
          ),
          FilledButton(
            onPressed: () async {
              final ok = await auth.updateUsername(nameCtrl.text);
              if (ok) {
                Get.back();
                Get.snackbar(
                  'saved'.tr,
                  'username_updated'.tr,
                  snackPosition: SnackPosition.BOTTOM,
                  duration: const Duration(seconds: 2),
                );
              }
            },
            child: Text('save'.tr),
          ),
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final AuthController auth = Get.find<AuthController>();
    final SettingsController settings = Get.find<SettingsController>();
    final ThemeController theme = Get.find<ThemeController>();

    return Scaffold(
      appBar: AppBar(
        title: Text('profile_and_settings'.tr),
        centerTitle: true,
      ),
      body: SafeArea(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: ListView(
              padding: const EdgeInsets.all(16.0),
              children: [
                // 1. User Profile Card with Profile Icon
                Obx(() {
                  final user = auth.currentUser.value;
                  final displayName = user?.username ?? 'User';
                  final email = user?.email ?? '';

                  return Card(
                    child: Padding(
                      padding: const EdgeInsets.all(16.0),
                      child: Row(
                        children: [
                          CircleAvatar(
                            radius: 28,
                            backgroundColor:
                                Theme.of(context).colorScheme.primaryContainer,
                            child: Icon(
                              Icons.person,
                              size: 30,
                              color: Theme.of(context)
                                  .colorScheme
                                  .onPrimaryContainer,
                            ),
                          ),
                          const SizedBox(width: 16),
                          Expanded(
                            child: Column(
                              crossAxisAlignment: CrossAxisAlignment.start,
                              children: [
                                Text(
                                  displayName,
                                  style: Theme.of(context).textTheme.titleMedium,
                                ),
                                const SizedBox(height: 2),
                                Text(
                                  email,
                                  style: Theme.of(context).textTheme.bodySmall,
                                ),
                              ],
                            ),
                          ),
                          IconButton(
                            tooltip: 'edit_username'.tr,
                            onPressed: () => _showEditUsernameDialog(auth),
                            icon: const Icon(Icons.edit_outlined),
                          ),
                        ],
                      ),
                    ),
                  );
                }),
                const SizedBox(height: 16),

                // 2. Day / Night Theme Switch
                Card(
                  child: Obx(() {
                    final isDark = theme.isDarkMode.value;
                    return SwitchListTile(
                      secondary: Icon(
                        isDark
                            ? Icons.dark_mode_outlined
                            : Icons.light_mode_outlined,
                      ),
                      title: Text('dark_mode'.tr),
                      subtitle: Text(
                        isDark ? 'night_mode_active'.tr : 'day_mode_active'.tr,
                      ),
                      value: isDark,
                      onChanged: (val) => theme.setDarkMode(val),
                    );
                  }),
                ),
                const SizedBox(height: 12),

                // 3. Language Selector (English / Ukrainian)
                Card(
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Row(
                          children: [
                            const Icon(Icons.language),
                            const SizedBox(width: 12),
                            Text(
                              'language'.tr,
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                          ],
                        ),
                        const SizedBox(height: 12),
                        Obx(() {
                          final currentLang = settings.localeCode.value;
                          return SizedBox(
                            width: double.infinity,
                            child: SegmentedButton<String>(
                              segments: const [
                                ButtonSegment<String>(
                                  value: 'uk',
                                  label: Text('Українська'),
                                ),
                                ButtonSegment<String>(
                                  value: 'en',
                                  label: Text('English'),
                                ),
                              ],
                              selected: {currentLang},
                              onSelectionChanged: (selection) {
                                auth.changeLanguage(selection.first);
                              },
                            ),
                          );
                        }),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // 4. Logout Button
                OutlinedButton.icon(
                  onPressed: () => auth.logout(),
                  style: OutlinedButton.styleFrom(
                    foregroundColor: Colors.redAccent,
                    side: const BorderSide(color: Colors.redAccent),
                    minimumSize: const Size(double.infinity, 48),
                  ),
                  icon: const Icon(Icons.logout),
                  label: Text('logout'.tr),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}