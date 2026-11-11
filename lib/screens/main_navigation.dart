import 'package:flutter/material.dart';

import 'home_screen.dart';
import 'field_screen.dart';
import 'care_screen.dart';
import 'chat_ai_screen.dart';
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
    const ChatAiScreen(),
    const CareScreen(),
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
        indicatorColor: green.withValues(alpha: 0.12),
        selectedIndex: selectedIndex,
        labelBehavior:
            NavigationDestinationLabelBehavior.alwaysShow,
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
            icon: Icon(Icons.smart_toy_outlined),
            selectedIcon: Icon(Icons.smart_toy),
            label: 'AI Chat',
          ),
          NavigationDestination(
            icon: Icon(Icons.calendar_month_outlined),
            selectedIcon: Icon(Icons.calendar_month),
            label: 'Chăm sóc',
          ),
          NavigationDestination(
            icon: Icon(Icons.person_outline),
            selectedIcon: Icon(Icons.person),
            label: 'Tài khoản',
          ),
        ],
      ),
    );
  }
}

class _AccountPage extends StatelessWidget {
  const _AccountPage();

  void openPage(BuildContext context, Widget page) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => page),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('Tài khoản')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          const Center(child: ProfileAvatar()),
          const SizedBox(height: 12),
          const Center(
            child: Text(
              'Tài khoản Nông Nghiệp Xanh',
              style: TextStyle(
                fontSize: 18,
                fontWeight: FontWeight.bold,
              ),
            ),
          ),
          const SizedBox(height: 25),
          const Text(
            'CHỨC NĂNG KHÁC',
            style: TextStyle(
              fontWeight: FontWeight.bold,
              color: Colors.green,
            ),
          ),
          const SizedBox(height: 10),
          Card(
            child: ListTile(
              leading: const Icon(Icons.grass, color: Colors.green),
              title: const Text('Quản lý mùa vụ'),
              subtitle: const Text('Theo dõi tiến trình cây trồng'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPage(context, const SeasonScreen()),
            ),
          ),
          Card(
            child: ListTile(
              leading: const Icon(Icons.account_balance_wallet,
                  color: Colors.green),
              title: const Text('Tài chính nông nghiệp'),
              subtitle: const Text('Chi phí, doanh thu và lợi nhuận'),
              trailing: const Icon(Icons.chevron_right),
              onTap: () => openPage(context, const FinanceScreen()),
            ),
          ),
        ],
      ),
    );
  }
}
