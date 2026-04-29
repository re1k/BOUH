import 'package:flutter/material.dart';
import '../theme/colors.dart';
import 'PendingRequestsView.dart';
import 'AcceptedDoctorsView.dart';
import 'CaregiversView.dart';
import 'QualificationRequestsView.dart'; // ← NEW
import 'package:bouh_admin/services/auth_service.dart';
import 'package:bouh_admin/views/login_page.dart';
import 'responsive.dart';
import 'package:bouh_admin/services/DoctorService.dart';
import 'package:bouh_admin/views/Widgets/ConfirmActionDialog.dart';

class AdminDashboardView extends StatefulWidget {
  const AdminDashboardView({super.key});

  @override
  State<AdminDashboardView> createState() => _AdminDashboardViewState();
}

class _AdminDashboardViewState extends State<AdminDashboardView> {
  int _selectedIndex = 0;
  int _pendingCount = 0;
  int _qualificationCount = 0; // ← NEW

  @override
  void initState() {
    super.initState();
    _loadQualificationCount();
  }

  Future<void> _loadQualificationCount() async {
    try {
      final requests = await DoctorService.instance
          .getPendingQualificationRequests(context);
      if (mounted) {
        setState(() => _qualificationCount = requests.length);
      }
    } catch (_) {}
  }

  final List<String> _pageTitles = [
    'طلبات التسجيل',
    'الأطباء المقبولون',
    'مقدمو الرعاية',
    'طلبات تحديث المؤهلات', // ← NEW
  ];

  void _confirmLogout() {
    showDialog(
      context: context,
      builder: (_) => ConfirmActionDialog(
        title: 'تسجيل الخروج',
        message: 'هل تريد تسجيل الخروج من لوحة التحكم؟',
        confirmText: 'تأكيد',
        confirmColor: BColors.primary,
        onConfirm: () async {
          Navigator.pop(context);
          await AdminAuthService.instance.logout();
          if (context.mounted) {
            Navigator.of(context).pushReplacement(
              MaterialPageRoute(builder: (_) => const LoginPage()),
            );
          }
        },
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    final isMobile = ResponsiveBreakpoints.isMobile(context);

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.lightGrey,
        drawer: isMobile
            ? Drawer(
                child: _SidebarWidget(
                  selectedIndex: _selectedIndex,
                  pendingCount: _pendingCount,
                  qualificationCount: _qualificationCount, // ← NEW
                  onSelectIndex: (i) {
                    setState(() => _selectedIndex = i);
                    Navigator.pop(context);
                  },
                  onLogout: _confirmLogout,
                ),
              )
            : null,
        body: isMobile
            ? Column(
                children: [
                  _TopBarWidget(
                    title: _pageTitles[_selectedIndex],
                    showMenuButton: true,
                  ),
                  Expanded(child: _buildCurrentPage()),
                ],
              )
            : Row(
                children: [
                  _SidebarWidget(
                    selectedIndex: _selectedIndex,
                    pendingCount: _pendingCount,
                    qualificationCount: _qualificationCount, // ← NEW
                    onSelectIndex: (i) => setState(() => _selectedIndex = i),
                    onLogout: _confirmLogout,
                  ),
                  Expanded(
                    child: Column(
                      children: [
                        _TopBarWidget(title: _pageTitles[_selectedIndex]),
                        Expanded(child: _buildCurrentPage()),
                      ],
                    ),
                  ),
                ],
              ),
      ),
    );
  }

  Widget _buildCurrentPage() {
    switch (_selectedIndex) {
      case 0:
        return PendingRequestsView(
          onCountLoaded: (count) {
            if (mounted) setState(() => _pendingCount = count);
          },
        );
      case 1:
        return const AcceptedDoctorsView();
      case 2:
        return const CaregiversView();
      case 3: // ← NEW
        return QualificationRequestsView(
          onCountLoaded: (count) {
            if (mounted) setState(() => _qualificationCount = count);
          },
        );
      default:
        return const SizedBox();
    }
  }
}

class _SidebarWidget extends StatelessWidget {
  final int selectedIndex;
  final int pendingCount;
  final int qualificationCount; // ← NEW
  final ValueChanged<int> onSelectIndex;
  final VoidCallback onLogout;

  const _SidebarWidget({
    required this.selectedIndex,
    required this.pendingCount,
    required this.qualificationCount, // ← NEW
    required this.onSelectIndex,
    required this.onLogout,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 250,
      decoration: const BoxDecoration(
        color: BColors.white,
        border: Border(left: BorderSide(color: BColors.grey, width: 0.5)),
      ),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            padding: const EdgeInsets.fromLTRB(20, 28, 20, 24),
            decoration: const BoxDecoration(
              border: Border(
                bottom: BorderSide(color: BColors.grey, width: 0.5),
              ),
            ),
            child: Row(
              children: [
                Container(
                  width: 42,
                  height: 42,
                  decoration: const BoxDecoration(
                    color: BColors.secondary,
                    shape: BoxShape.circle,
                  ),
                  child: const Icon(
                    Icons.monitor_heart_outlined,
                    color: BColors.primary,
                    size: 22,
                  ),
                ),
                const SizedBox(width: 12),
                const Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      'لوحة التحكم',
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w700,
                        color: BColors.textDarkestBlue,
                      ),
                    ),
                    Text(
                      'نظام إدارة المنصة',
                      style: TextStyle(fontSize: 12, color: BColors.darkGrey),
                    ),
                  ],
                ),
              ],
            ),
          ),
          const SizedBox(height: 16),
          const Padding(
            padding: EdgeInsets.symmetric(horizontal: 20),
            child: Text(
              'إدارة المستخدمين',
              style: TextStyle(
                fontSize: 11,
                color: BColors.darkGrey,
                letterSpacing: 1.0,
              ),
            ),
          ),
          const SizedBox(height: 8),
          _NavItemWidget(
            icon: Icons.person_add_outlined,
            label: 'طلبات التسجيل',
            isSelected: selectedIndex == 0,
            badge: pendingCount,
            onTap: () => onSelectIndex(0),
          ),
          _NavItemWidget(
            icon: Icons.people_outlined,
            label: 'الأطباء المقبولون',
            isSelected: selectedIndex == 1,
            onTap: () => onSelectIndex(1),
          ),
          _NavItemWidget(
            icon: Icons.group_outlined,
            label: 'مقدمو الرعاية',
            isSelected: selectedIndex == 2,
            onTap: () => onSelectIndex(2),
          ),
          _NavItemWidget(
            // ← NEW
            icon: Icons.verified_outlined,
            label: 'تحديث طلبات المؤهلات',
            isSelected: selectedIndex == 3,
            badge: qualificationCount,
            onTap: () => onSelectIndex(3),
          ),
          const Spacer(),
          Container(
            padding: const EdgeInsets.all(20),
            decoration: const BoxDecoration(
              border: Border(top: BorderSide(color: BColors.grey, width: 0.5)),
            ),
            child: SizedBox(
              width: double.infinity,
              child: OutlinedButton.icon(
                onPressed: onLogout,
                icon: const Icon(Icons.logout, size: 16),
                label: const Text(
                  'تسجيل الخروج',
                  style: TextStyle(fontSize: 14),
                ),
                style: OutlinedButton.styleFrom(
                  foregroundColor: BColors.destructiveError,
                  side: const BorderSide(color: BColors.grey, width: 0.5),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(8),
                  ),
                  padding: const EdgeInsets.symmetric(vertical: 12),
                ),
              ),
            ),
          ),
        ],
      ),
    );
  }
}

class _NavItemWidget extends StatelessWidget {
  final IconData icon;
  final String label;
  final bool isSelected;
  final int badge;
  final VoidCallback onTap;

  const _NavItemWidget({
    required this.icon,
    required this.label,
    required this.isSelected,
    required this.onTap,
    this.badge = 0,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: BoxDecoration(
          color: isSelected ? BColors.secondary : Colors.transparent,
          border: isSelected
              ? const Border(
                  right: BorderSide(color: BColors.primary, width: 3),
                )
              : null,
        ),
        padding: const EdgeInsets.symmetric(horizontal: 20, vertical: 14),
        child: Row(
          children: [
            Icon(
              icon,
              size: 18,
              color: isSelected ? BColors.primary : BColors.darkerGrey,
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Text(
                label,
                style: TextStyle(
                  fontSize: 14,
                  fontWeight: isSelected ? FontWeight.w600 : FontWeight.w400,
                  color: isSelected ? BColors.primary : BColors.darkerGrey,
                ),
              ),
            ),
            if (badge > 0)
              Container(
                padding: const EdgeInsets.symmetric(
                  horizontal: 10,
                  vertical: 4,
                ),
                decoration: BoxDecoration(
                  color: BColors.accent,
                  borderRadius: BorderRadius.circular(99),
                ),
                child: Text(
                  '$badge',
                  style: const TextStyle(
                    fontSize: 14,
                    fontWeight: FontWeight.w700,
                    color: BColors.white,
                  ),
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _TopBarWidget extends StatelessWidget {
  final String title;
  final bool showMenuButton;

  const _TopBarWidget({required this.title, this.showMenuButton = false});

  @override
  Widget build(BuildContext context) {
    return Container(
      height: 70,
      padding: const EdgeInsets.symmetric(horizontal: 16),
      decoration: const BoxDecoration(
        color: BColors.white,
        border: Border(bottom: BorderSide(color: BColors.grey, width: 0.5)),
      ),
      child: Row(
        children: [
          if (showMenuButton)
            Builder(
              builder: (context) => IconButton(
                icon: const Icon(Icons.menu),
                onPressed: () => Scaffold.of(context).openDrawer(),
              ),
            ),
          Expanded(
            child: Text(
              title,
              textAlign: showMenuButton ? TextAlign.center : TextAlign.start,
              style: const TextStyle(
                fontSize: 20,
                fontWeight: FontWeight.w700,
                color: BColors.textDarkestBlue,
              ),
            ),
          ),
        ],
      ),
    );
  }
}
