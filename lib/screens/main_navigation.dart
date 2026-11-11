
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
      bottomNavigationBar: NavigationBar(
        height: 68,
        backgroundColor: Colors.white,
        indicatorColor: const Color(0xFF167A45).withValues(alpha: 0.12),
        selectedIndex: selectedIndex,
        labelBehavior: NavigationDestinationLabelBehavior.alwaysShow,
        onDestinationSelected: (index) {
          setState(() => selectedIndex = index);
        },
        destinations: const [
          NavigationDestination(
            icon: Icon(Icons.home_rounded),
            label: 'Trang chủ',
          ),
          NavigationDestination(
            icon: Icon(Icons.grass_rounded),
            label: 'Ruộng',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_rounded),
            label: 'Mùa vụ',
          ),
          NavigationDestination(
            icon: Icon(Icons.eco_rounded),
            label: 'Chăm sóc',
          ),
          NavigationDestination(
            icon: Icon(Icons.account_balance_wallet_rounded),
            label: 'Tài chính',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_rounded),
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
