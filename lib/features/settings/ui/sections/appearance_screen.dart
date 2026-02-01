import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:font_awesome_flutter/font_awesome_flutter.dart';
import 'package:autogit/core/providers/providers.dart';
import 'package:autogit/core/providers/theme_persistence.dart';
import 'package:autogit/core/widgets/large_app_bar.dart';

class AppearanceScreen extends ConsumerWidget {
  const AppearanceScreen({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final themeMode = ref.watch(themeModeProvider);
    final colorSchemeSeed = ref.watch(colorSchemeSeedProvider);

    return Scaffold(
      body: CustomScrollView(
        slivers: [
          const LargeAppBar(title: 'Appearance'),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 0),
              child: Text(
                'Theme',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverList(
            delegate: SliverChildListDelegate([
              _ThemeTile(
                title: 'AMOLED Black',
                subtitle: 'Pure black background (like Cursor)',
                value: AppThemeMode.amoled,
                groupValue: themeMode,
                onChanged: () {
                  ref.read(themeModeProvider.notifier).state =
                      AppThemeMode.amoled;
                  saveThemeMode(AppThemeMode.amoled);
                },
              ),
              _ThemeTile(
                title: 'Dark',
                subtitle: 'Standard dark theme',
                value: AppThemeMode.dark,
                groupValue: themeMode,
                onChanged: () {
                  ref.read(themeModeProvider.notifier).state =
                      AppThemeMode.dark;
                  saveThemeMode(AppThemeMode.dark);
                },
              ),
              _ThemeTile(
                title: 'Light',
                subtitle: 'Standard light theme',
                value: AppThemeMode.light,
                groupValue: themeMode,
                onChanged: () {
                  ref.read(themeModeProvider.notifier).state =
                      AppThemeMode.light;
                  saveThemeMode(AppThemeMode.light);
                },
              ),
              _ThemeTile(
                title: 'System',
                subtitle: 'Follow device light/dark setting',
                value: AppThemeMode.system,
                groupValue: themeMode,
                onChanged: () {
                  ref.read(themeModeProvider.notifier).state =
                      AppThemeMode.system;
                  saveThemeMode(AppThemeMode.system);
                },
              ),
            ]),
          ),
          SliverToBoxAdapter(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 24, 16, 0),
              child: Text(
                'Accent color',
                style: Theme.of(context).textTheme.titleSmall?.copyWith(
                  color: Theme.of(context).colorScheme.primary,
                ),
              ),
            ),
          ),
          SliverToBoxAdapter(
            child: ListTile(
              leading: const Icon(FontAwesomeIcons.paintbrush),
              title: const Text('Color scheme'),
              trailing: DropdownButton<Color>(
                underline: const SizedBox(),
                borderRadius: BorderRadius.circular(8),
                value: colorSchemeSeed,
                items: const [
                  DropdownMenuItem(value: Colors.teal, child: Text('Teal')),
                  DropdownMenuItem(value: Colors.blue, child: Text('Blue')),
                  DropdownMenuItem(value: Colors.indigo, child: Text('Indigo')),
                  DropdownMenuItem(value: Colors.purple, child: Text('Purple')),
                  DropdownMenuItem(value: Colors.red, child: Text('Red')),
                  DropdownMenuItem(value: Colors.green, child: Text('Green')),
                  DropdownMenuItem(value: Colors.amber, child: Text('Amber')),
                ],
                onChanged: (Color? newColor) {
                  if (newColor != null) {
                    ref.read(colorSchemeSeedProvider.notifier).state = newColor;
                    saveColorSeed(newColor);
                  }
                },
              ),
            ),
          ),
          const SliverToBoxAdapter(child: SizedBox(height: 24)),
        ],
      ),
    );
  }
}

class _ThemeTile extends StatelessWidget {
  const _ThemeTile({
    required this.title,
    required this.subtitle,
    required this.value,
    required this.groupValue,
    required this.onChanged,
  });

  final String title;
  final String subtitle;
  final AppThemeMode value;
  final AppThemeMode groupValue;
  final VoidCallback onChanged;

  @override
  Widget build(BuildContext context) {
    final selected = value == groupValue;
    return ListTile(
      leading: Radio<AppThemeMode>(
        value: value,
        groupValue: groupValue,
        onChanged: (_) => onChanged(),
      ),
      title: Text(title),
      subtitle: Text(subtitle),
      onTap: onChanged,
    );
  }
}
