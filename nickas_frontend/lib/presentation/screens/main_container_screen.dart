import 'package:flutter/material.dart';
import '../../l10n/app_localizations.dart';
import 'shopping_list_screen.dart';
import 'finance_dashboard_screen.dart';

class MainContainerScreen extends StatefulWidget {
  const MainContainerScreen({super.key});

  @override
  State<MainContainerScreen> createState() => _MainContainerScreenState();
}

class _MainContainerScreenState extends State<MainContainerScreen> {
  int _currentIndex = 0;

  final List<Widget> _screens = [
    const FinanceDashboardScreen(),
    const ShoppingListScreen(),
  ];

  @override
  Widget build(BuildContext context) {
    final l10n = AppLocalizations.of(context)!;
    return Scaffold(
      body: _screens[_currentIndex],
      bottomNavigationBar: NavigationBar(
        selectedIndex: _currentIndex,
        onDestinationSelected: (index) {
          setState(() {
            _currentIndex = index;
          });
        },
        destinations: [
          NavigationDestination(
            icon: const Icon(Icons.pie_chart_outline),
            selectedIcon: const Icon(Icons.pie_chart),
            label: l10n.tabFinances,
          ),
          NavigationDestination(
            icon: const Icon(Icons.shopping_cart_outlined),
            selectedIcon: const Icon(Icons.shopping_cart),
            label: l10n.tabShopping,
          ),
        ],
      ),
    );
  }
}
