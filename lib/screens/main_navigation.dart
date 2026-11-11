import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'field_screen.dart';
import 'season_screen.dart';
import care_screen.dart';
import diagnose_screen.dart';
import finance_screen.dart';
import '../widgets/profile_avatar.dart';

class MainNavigation extends StatefulWidget {
  const MainNavigation({super.key});

  @override
  State<MainNavigation> createState() => _MainNavigationState();
}

class _MainNavigationState extends State<MainNavigation> {
  int selectedIndex = 0;

  late final List<Widget> pages = [
    const HomeScreen(),
    const FieldScreen(),
    const SeasonScreen(),
    const CareScreen(),
    const DiagnoseScreen(),
    const FinanceScreen(),
    const _AccountPage(),
  ];

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: NavigationBar(
        height: 70,
        backgroundColor: Colors.white,
        elevation: 0,
        indicatorColor: green.withValues(alpha: 0.12),
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        animationDuration: const Duration(milliseconds: 250),
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_outlined),
            selectedIcon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.agriculture_outlined),
            selectedIcon: Icon(Icons.agriculture_rounded),
            label: 'Ruộng',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_outlined),
            selectedIcon: Icon(Icons.grass_rounded),
            label: 'Mùa vụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month_rounded),
            label: 'Chăm sóc',
          ),
          NavigationDestination(
            icon: Icon(Icons.biotech_outlined),
            selectedIcon: Icon(Icons.biotech_rounded),
            label: 'AI',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_outlined),
            selectedIcon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person_rounded),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: const Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            ProfileAvatar(),
            SizedBox(height: 16),
            Text(
              'Tài khoản Nông Nghiệp Xanh',
              style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
            ),
          ],
        ),
      ),
    );
  }
}
