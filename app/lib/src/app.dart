import 'dart:async';

import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';
import 'package:kina_app/src/analysis/analysis_screen.dart';
import 'package:kina_app/src/calculator/calculator_screen.dart';
import 'package:kina_app/src/marketplace/marketplace_screen.dart';
import 'package:kina_app/src/more/more_screen.dart';
import 'package:kina_app/src/sync/sync_providers.dart';
import 'package:kina_app/src/theme.dart';

/// The app root.
class KinaApp extends StatelessWidget {
  /// Creates the app.
  const KinaApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    title: 'Kina Calculator',
    debugShowCheckedModeBanner: false,
    theme: lightTheme,
    darkTheme: darkTheme,
    home: const HomeShell(),
  );
}

/// A top-level page of the app.
typedef _Destination = ({String label, IconData icon, IconData selected});

const List<_Destination> _destinations = [
  (
    label: 'Calculator',
    icon: Icons.calculate_outlined,
    selected: Icons.calculate,
  ),
  (
    label: 'Marketplace',
    icon: Icons.storefront_outlined,
    selected: Icons.storefront,
  ),
  (label: 'Analysis', icon: Icons.insights_outlined, selected: Icons.insights),
  (label: 'More', icon: Icons.menu_outlined, selected: Icons.menu),
];

/// Switches between the app's pages: a side rail on wide windows, a bottom
/// bar on phones. Pages keep their state while hidden.
class HomeShell extends ConsumerStatefulWidget {
  /// Creates the shell.
  const HomeShell({super.key});

  @override
  ConsumerState<HomeShell> createState() => _HomeShellState();
}

class _HomeShellState extends ConsumerState<HomeShell> {
  var _index = 0;

  @override
  void initState() {
    super.initState();
    // On the PC this starts the sync server if it was switched on; on a
    // phone it syncs once, quietly.
    if (ref.read(syncRoleProvider) == SyncRole.hub) {
      unawaited(ref.read(hubControllerProvider.future));
    } else {
      unawaited(ref.read(pairingProvider.notifier).autoSync());
    }
  }

  void _select(int index) => setState(() => _index = index);

  @override
  Widget build(BuildContext context) {
    final wide = MediaQuery.sizeOf(context).width >= wideLayoutWidth;
    final pages = IndexedStack(
      index: _index,
      children: const [
        CalculatorScreen(),
        MarketplaceScreen(),
        AnalysisScreen(),
        MoreScreen(),
      ],
    );
    return Scaffold(
      appBar: AppBar(
        title: Text(
          _index == 0
              ? 'Kina Calculator'
              : 'Kina Calculator · ${_destinations[_index].label}',
        ),
      ),
      body: SafeArea(
        child: wide
            ? Row(
                children: [
                  NavigationRail(
                    selectedIndex: _index,
                    onDestinationSelected: _select,
                    labelType: NavigationRailLabelType.all,
                    destinations: [
                      for (final d in _destinations)
                        NavigationRailDestination(
                          icon: Icon(d.icon),
                          selectedIcon: Icon(d.selected),
                          label: Text(d.label),
                        ),
                    ],
                  ),
                  const VerticalDivider(width: 1),
                  Expanded(child: pages),
                ],
              )
            : pages,
      ),
      bottomNavigationBar: wide
          ? null
          : NavigationBar(
              selectedIndex: _index,
              onDestinationSelected: _select,
              destinations: [
                for (final d in _destinations)
                  NavigationDestination(
                    icon: Icon(d.icon),
                    selectedIcon: Icon(d.selected),
                    label: d.label,
                  ),
              ],
            ),
    );
  }
}
