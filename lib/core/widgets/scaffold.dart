import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:autogit/core/constants/icons/nav_icons.dart';
import 'package:autogit/core/core.dart';

class ScaffoldWithNavBar extends ConsumerWidget {
  final StatefulNavigationShell navigationShell;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
    this.floatingActionButton,
    this.appBar,
  });

  void _onItemTapped(int index) {
    navigationShell.goBranch(index);
  }

  final List<NavigationDestination> _destinations = [
    const NavigationDestination(
      selectedIcon: Icon(AGNavIcons.homeSelected),
      icon: PhosphorIcon(AGNavIcons.home),
      label: 'Home',
    ),
    const NavigationDestination(
      selectedIcon: Icon(AGNavIcons.searchSelected),
      icon: Icon(AGNavIcons.search),
      label: 'Search',
    ),
    const NavigationDestination(
      selectedIcon: Icon(AGNavIcons.assistantSelected),
      icon: Icon(AGNavIcons.assistant),
      label: 'Assist',
    ),
    const NavigationDestination(
      selectedIcon: Icon(AGNavIcons.profileSelected),
      icon: Icon(AGNavIcons.profile),
      label: 'Profile',
    ),
    const NavigationDestination(
      selectedIcon: Icon(AGNavIcons.settingsSelected),
      icon: Icon(AGNavIcons.settings),
      label: 'Settings',
    ),
  ];
  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    return Scaffold(
      body: AnnotatedRegion<SystemUiOverlayStyle>(
        value: SystemUiOverlayStyle(
          statusBarColor: Colors.transparent,
          statusBarIconBrightness: brightness == Brightness.dark
              ? Brightness.light
              : Brightness.dark,
          systemNavigationBarColor: Colors.transparent,
        ),
        child: navigationShell,
      ),
      bottomNavigationBar: NavigationBar(
        selectedIndex: navigationShell.currentIndex,
        onDestinationSelected: _onItemTapped,
        destinations: _destinations,
      ),
      floatingActionButton: floatingActionButton,
      appBar: appBar,
    );
  }
}
