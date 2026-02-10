import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:go_router/go_router.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:phosphor_flutter/phosphor_flutter.dart';
import 'package:autogit/core/constants/icons/nav_icons.dart';
import 'package:autogit/core/core.dart';

/// Breakpoint width: use NavigationRail when the scaffold is at least this wide
/// (e.g. landscape or tablet). Otherwise use bottom NavigationBar.
const double _kNavRailBreakpoint = 600;

class ScaffoldWithNavBar extends ConsumerWidget {
  ScaffoldWithNavBar({
    super.key,
    required this.navigationShell,
    this.floatingActionButton,
    this.appBar,
  });

  final StatefulNavigationShell navigationShell;
  final Widget? floatingActionButton;
  final PreferredSizeWidget? appBar;

  void _onItemTapped(int index) {
    navigationShell.goBranch(index);
  }

  static const List<NavigationDestination> _navBarDestinations = [
    NavigationDestination(
      selectedIcon: Icon(AGNavIcons.homeSelected),
      icon: PhosphorIcon(AGNavIcons.home),
      label: 'Home',
    ),
    NavigationDestination(
      selectedIcon: Icon(AGNavIcons.searchSelected),
      icon: Icon(AGNavIcons.search),
      label: 'Search',
    ),
    NavigationDestination(
      selectedIcon: Icon(AGNavIcons.assistantSelected),
      icon: Icon(AGNavIcons.assistant),
      label: 'Assist',
    ),
    NavigationDestination(
      selectedIcon: Icon(AGNavIcons.profileSelected),
      icon: Icon(AGNavIcons.profile),
      label: 'Profile',
    ),
    NavigationDestination(
      selectedIcon: Icon(AGNavIcons.settingsSelected),
      icon: Icon(AGNavIcons.settings),
      label: 'Settings',
    ),
  ];

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final brightness = ref.watch(brightnessProvider);
    final width = MediaQuery.sizeOf(context).width;
    final useNavRail = width >= _kNavRailBreakpoint;

    return AnnotatedRegion<SystemUiOverlayStyle>(
      value: SystemUiOverlayStyle(
        statusBarColor: Colors.transparent,
        statusBarIconBrightness:
            brightness == Brightness.dark ? Brightness.light : Brightness.dark,
        systemNavigationBarColor: Colors.transparent,
      ),
      child: Scaffold(
        body: useNavRail
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: navigationShell.currentIndex,
                    onDestinationSelected: _onItemTapped,
                    labelType: NavigationRailLabelType.none,
                    destinations: _navBarDestinations
                        .map(
                          (d) => NavigationRailDestination(
                            icon: d.icon,
                            selectedIcon: d.selectedIcon,
                            label: Text(d.label),
                          ),
                        )
                        .toList(),
                  ),
                  Expanded(child: navigationShell),
                ],
              )
            : navigationShell,
        bottomNavigationBar: useNavRail
            ? null
            : NavigationBar(
                selectedIndex: navigationShell.currentIndex,
                onDestinationSelected: _onItemTapped,
                destinations: _navBarDestinations,
              ),
        floatingActionButton: floatingActionButton,
        appBar: appBar,
      ),
    );
  }
}
