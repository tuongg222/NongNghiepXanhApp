
import 'package:flutter/material.dart';
import 'home_screen.dart';
import 'care_ai_screen.dart';
import 'field_screen.dart';
import 'season_screen.dart';
import 'finance_screen.dart';
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
    const CareAIScreen(),
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
      bottomNavigationBar: SafeArea(
        top: false,
        child: Container(
          decoration: BoxDecoration(
            color: Colors.white,
            border: Border(
              top: BorderSide(
                color: Colors.green.withValues(alpha: 0.08),
              ),
            ),
          ),
          child: NavigationBar(
            height: 72,
            backgroundColor: Colors.white,
            elevation: 0,
            indicatorColor: green.withValues(alpha: 0.12),
            selectedIndex: selectedIndex,
            labelBehavior:
                NavigationDestinationLabelBehavior.alwaysShow,
            animationDuration: const Duration(milliseconds: 300),
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
                icon: Icon(Icons.grass_outlined),
                selectedIcon: Icon(Icons.grass_rounded),
                label: 'Ruộng',
              ),
              NavigationDestination(
                icon: Icon(Icons.calendar_month_outlined),
                selectedIcon: Icon(Icons.calendar_month_rounded),
                label: 'Mùa vụ',
              ),
              NavigationDestination(
                icon: Icon(Icons.eco_outlined),
                selectedIcon: Icon(Icons.eco_rounded),
                label: 'Chăm sóc',
              ),
              NavigationDestination(
                icon: Icon(Icons.account_balance_wallet_outlined),
                selectedIcon: Icon(Icons.account_balance_wallet_rounded),
                label: 'Tài chính',
              ),
              NavigationDestination(
                icon: Icon(Icons.person_outline_rounded),
                selectedIcon: Icon(Icons.person_rounded),
                label: 'Tài khoản',
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      appBar: AppBar(
        title: const Text(
          'Tài khoản',
          style: TextStyle(fontWeight: FontWeight.bold),
        ),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            const ProfileAvatar(),
            const SizedBox(height: 18),
            const Text(
              'Nông Nghiệp Xanh',
              style: TextStyle(
                fontSize: 22,
                fontWeight: FontWeight.bold,
                color: green,
              ),
            ),
            const SizedBox(height: 8),
            const Text('Quản lý hồ sơ nông nghiệp của bạn'),
          ],
        ),
      ),
    );
  }
}
