import 'package:flutter/material.dart';
import '../theme/colors.dart';
import '../services/auth_service.dart';
import 'login_page.dart';
import 'doctorspage.dart';
import 'caregiverspage.dart';

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage>
    with SingleTickerProviderStateMixin {
  late final TabController _tabController;

  @override
  void initState() {
    super.initState();
    _tabController = TabController(length: 2, vsync: this);
  }

  @override
  void dispose() {
    _tabController.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.softGrey,
        appBar: AppBar(
          backgroundColor: BColors.primary,
          centerTitle: true,
          automaticallyImplyLeading: false,
          title: const Text(
            'لوحة تحكم المسؤول',
            style: TextStyle(
              color: BColors.white,
              fontWeight: FontWeight.w700,
              fontSize: 18,
            ),
          ),
          actions: [
            TextButton.icon(
              onPressed: () async {
                await AdminAuthService.instance.logout();
                if (context.mounted) {
                  Navigator.of(context).pushReplacement(
                    MaterialPageRoute(builder: (_) => const LoginPage()),
                  );
                }
              },
              icon: const Icon(Icons.logout, color: BColors.white, size: 18),
              label: const Text(
                'تسجيل الخروج',
                style: TextStyle(color: BColors.white, fontSize: 14),
              ),
            ),
            const SizedBox(width: 8),
          ],
          bottom: TabBar(
            controller: _tabController,
            indicatorColor: BColors.white,
            indicatorWeight: 3,
            overlayColor: WidgetStateProperty.all(Colors.transparent),
            labelColor: BColors.white,
            unselectedLabelColor: BColors.white.withValues(alpha: 0.6),
            labelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w700,
            ),
            unselectedLabelStyle: const TextStyle(
              fontSize: 14,
              fontWeight: FontWeight.w400,
            ),
            tabs: const [
              Tab(text: 'إدارة الأطباء'),
              Tab(text: 'إدارة مقدمو الرعاية'),
            ],
          ),
        ),
        body: TabBarView(
          controller: _tabController,
          children: const [DoctorsPage(), CaregiversPage()],
        ),
      ),
    );
  }
}
