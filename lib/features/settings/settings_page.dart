import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:go_router/go_router.dart';
import 'package:hire_craft/app/app.dart';
import 'package:hire_craft/providers/auth_provider.dart';
import 'package:package_info_plus/package_info_plus.dart';

enum _LogoutChoice { currentDevice, allDevices }

final appVersionProvider = FutureProvider<String>((ref) async {
  final info = await PackageInfo.fromPlatform();
  return info.version;
});

class SettingsPage extends ConsumerWidget {
  const SettingsPage({super.key});

  static const _customColors = <Color>[
    Color(0xFF6750A4),
    Color(0xFF006E1C),
    Color(0xFF9C4046),
    Color(0xFF005DA4),
    Color(0xFF7A5900),
    Color(0xFF7B4B94),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final appVersion = ref.watch(appVersionProvider);
    final authState = ref.watch(authProvider);
    final user = authState.user;
    final settings =
        ref.watch(themeSettingsProvider).asData?.value ??
        ThemeSettings(
          themeMode: ThemeMode.system,
          useSystemMonet: true,
          customSeedColorValue: Theme.of(
            context,
          ).colorScheme.primary.toARGB32(),
        );

    return Scaffold(
      body: SafeArea(
        child: CustomScrollView(
          slivers: [
            const SliverAppBar.large(pinned: true, title: Text('Settings')),
            SliverPadding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 24),
              sliver: SliverToBoxAdapter(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Account',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            ListTile(
                              contentPadding: EdgeInsets.zero,
                              leading: const CircleAvatar(
                                child: Icon(Icons.person),
                              ),
                              title: Text(
                                (user?.userMetadata?['full_name'] as String?)
                                            ?.trim()
                                            .isNotEmpty ==
                                        true
                                    ? (user!.userMetadata!['full_name']
                                          as String)
                                    : 'HireCraft User',
                              ),
                              subtitle: Text(
                                user?.email ?? 'No email available',
                              ),
                            ),
                            Text(
                              'User ID: ${user?.id ?? 'N/A'}',
                              style: Theme.of(context).textTheme.bodySmall,
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.start,
                          children: [
                            Text(
                              'Theme',
                              style: Theme.of(context).textTheme.titleMedium,
                            ),
                            const SizedBox(height: 12),
                            SegmentedButton<ThemeMode>(
                              segments: const [
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.system,
                                  label: Text('System'),
                                  icon: Icon(Icons.settings_suggest_outlined),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.light,
                                  label: Text('Light'),
                                  icon: Icon(Icons.light_mode_outlined),
                                ),
                                ButtonSegment<ThemeMode>(
                                  value: ThemeMode.dark,
                                  label: Text('Dark'),
                                  icon: Icon(Icons.dark_mode_outlined),
                                ),
                              ],
                              selected: {settings.themeMode},
                              onSelectionChanged: (selection) {
                                final mode = selection.first;
                                ref
                                    .read(themeSettingsProvider.notifier)
                                    .setThemeMode(mode);
                              },
                            ),
                            const SizedBox(height: 16),
                            Text(
                              'Monet color',
                              style: Theme.of(context).textTheme.titleSmall,
                            ),
                            const SizedBox(height: 8),
                            SegmentedButton<bool>(
                              segments: const [
                                ButtonSegment<bool>(
                                  value: true,
                                  label: Text('System default'),
                                  icon: Icon(Icons.palette_outlined),
                                ),
                                ButtonSegment<bool>(
                                  value: false,
                                  label: Text('Other'),
                                  icon: Icon(Icons.color_lens_outlined),
                                ),
                              ],
                              selected: {settings.useSystemMonet},
                              onSelectionChanged: (selection) {
                                final useSystem = selection.first;
                                ref
                                    .read(themeSettingsProvider.notifier)
                                    .setUseSystemMonet(useSystem);
                              },
                            ),
                            if (!settings.useSystemMonet) ...[
                              const SizedBox(height: 14),
                              Text(
                                'Choose app color',
                                style: Theme.of(context).textTheme.titleSmall,
                              ),
                              const SizedBox(height: 8),
                              Wrap(
                                spacing: 10,
                                runSpacing: 10,
                                children: _customColors.map((color) {
                                  final selected =
                                      settings.customSeedColorValue ==
                                      color.toARGB32();
                                  return InkWell(
                                    borderRadius: BorderRadius.circular(24),
                                    onTap: () {
                                      ref
                                          .read(themeSettingsProvider.notifier)
                                          .setCustomSeedColor(color);
                                    },
                                    child: Container(
                                      width: 40,
                                      height: 40,
                                      decoration: BoxDecoration(
                                        color: color,
                                        shape: BoxShape.circle,
                                        border: Border.all(
                                          color: selected
                                              ? Theme.of(
                                                  context,
                                                ).colorScheme.onSurface
                                              : Theme.of(
                                                  context,
                                                ).colorScheme.outlineVariant,
                                          width: selected ? 3 : 1,
                                        ),
                                      ),
                                      child: selected
                                          ? const Icon(
                                              Icons.check,
                                              color: Colors.white,
                                            )
                                          : null,
                                    ),
                                  );
                                }).toList(),
                              ),
                            ],
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    Card(
                      child: Padding(
                        padding: const EdgeInsets.all(16),
                        child: Column(
                          crossAxisAlignment: CrossAxisAlignment.stretch,
                          children: [
                            FilledButton.icon(
                              onPressed: () async {
                                final choice = await showDialog<_LogoutChoice>(
                                  context: context,
                                  builder: (dialogContext) => AlertDialog(
                                    title: const Text('Log out'),
                                    content: const Text(
                                      'Do you want to log out only from this device or from every device?',
                                    ),
                                    actions: [
                                      SizedBox(
                                        width: double.infinity,
                                        child: OutlinedButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(_LogoutChoice.currentDevice),
                                          child: const Text(
                                            'Log out on this device',
                                          ),
                                        ),
                                      ),
                                      SizedBox(
                                        width: double.infinity,
                                        child: FilledButton(
                                          onPressed: () => Navigator.of(
                                            dialogContext,
                                          ).pop(_LogoutChoice.allDevices),
                                          child: const Text(
                                            'Log out on every device',
                                          ),
                                        ),
                                      ),
                                      TextButton(
                                        onPressed: () =>
                                            Navigator.of(dialogContext).pop(),
                                        child: const Text('Cancel'),
                                      ),
                                    ],
                                    actionsPadding: const EdgeInsets.fromLTRB(
                                      16,
                                      0,
                                      16,
                                      16,
                                    ),
                                    actionsAlignment: MainAxisAlignment.center,
                                    actionsOverflowDirection:
                                        VerticalDirection.down,
                                    actionsOverflowButtonSpacing: 8,
                                    actionsOverflowAlignment:
                                        OverflowBarAlignment.center,
                                    buttonPadding: EdgeInsets.zero,
                                    icon: null,
                                  ),
                                );

                                if (choice == null) {
                                  return;
                                }

                                await ref
                                    .read(authProvider.notifier)
                                    .signOut(
                                      scope: choice == _LogoutChoice.allDevices
                                          ? AppSignOutScope.allDevices
                                          : AppSignOutScope.currentDevice,
                                    );
                                if (!context.mounted) {
                                  return;
                                }
                                context.go('/auth?loggedOut=1');
                              },
                              icon: const Icon(Icons.logout),
                              label: const Text('Log out'),
                            ),
                          ],
                        ),
                      ),
                    ),
                    const SizedBox(height: 20),
                    Align(
                      alignment: Alignment.center,
                      child: Text(
                        appVersion.when(
                          data: (value) => 'Version $value',
                          loading: () => 'Version -',
                          error: (_, __) => 'Version -',
                        ),
                        style: Theme.of(context).textTheme.bodySmall,
                      ),
                    ),
                  ],
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}
