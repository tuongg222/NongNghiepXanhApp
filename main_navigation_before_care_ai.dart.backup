
import 'package:flutter/material.dart';
import 'home_screen.dart';
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
    const FinanceScreen(),
    const _AccountPage(),
  ];

  final List<IconData> icons = [
    Icons.home_rounded,
    Icons.grass_rounded,
    Icons.calendar_month_rounded,
    Icons.account_balance_wallet_rounded,
    Icons.person_rounded,
  ];

  final List<String> labels = [
    'Trang chủ',
    'Ruộng',
    'Mùa vụ',
    'Tài chính',
    'Tài khoản',
  ];

  @override
  Widget build(BuildContext context) {
    const green = Color(0xFF167A45);

    return Scaffold(
      body: IndexedStack(
        index: selectedIndex,
        children: pages,
      ),
      bottomNavigationBar: Container(
        decoration: BoxDecoration(
          color: Colors.white,
          boxShadow: [
            BoxShadow(
              color: Colors.black.withValues(alpha: 0.06),
              blurRadius: 18,
              offset: const Offset(0, -4),
            ),
          ],
        ),
        child: SafeArea(
          top: false,
          child: Padding(
            padding: const EdgeInsets.fromLTRB(6, 8, 6, 5),
            child: Row(
              children: List.generate(5, (index) {
                final selected = selectedIndex == index;

                return Expanded(
                  child: InkWell(
                    borderRadius: BorderRadius.circular(18),
                    onTap: () {
                      if (selectedIndex != index) {
                        setState(() => selectedIndex = index);
                      }
                    },
                    child: AnimatedContainer(
                      duration: const Duration(milliseconds: 280),
                      curve: Curves.easeOutCubic,
                      padding: const EdgeInsets.symmetric(vertical: 5),
                      child: Column(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          AnimatedContainer(
                            duration: const Duration(milliseconds: 280),
                            curve: Curves.easeOutCubic,
                            width: selected ? 52 : 42,
                            height: 32,
                            decoration: BoxDecoration(
                              color: selected
                                  ? green.withValues(alpha: 0.13)
                                  : Colors.transparent,
                              borderRadius: BorderRadius.circular(20),
                            ),
                            child: Center(
                              child: AnimatedScale(
                                scale: selected ? 1.15 : 0.95,
                                duration: const Duration(milliseconds: 250),
                                curve: Curves.easeOutBack,
                                child: Icon(
                                  icons[index],
                                  size: 23,
                                  color: selected
                                      ? green
                                      : Colors.grey.shade600,
                                ),
                              ),
                            ),
                          ),
                          const SizedBox(height: 3),
                          AnimatedDefaultTextStyle(
                            duration: const Duration(milliseconds: 220),
                            curve: Curves.easeInOut,
                            style: TextStyle(
                              fontSize: selected ? 11 : 10,
                              fontWeight: selected
                                  ? FontWeight.w700
                                  : FontWeight.w500,
                              color: selected
                                  ? green
                                  : Colors.grey.shade600,
                            ),
                            child: Text(
                              labels[index],
                              maxLines: 1,
                              overflow: TextOverflow.ellipsis,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                );
              }),
            ),
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
