import 'package:flutter/material.dart';
import '../../../theme/base_themes/colors.dart';

/// Reusable bottom navigation bar for the caregiver view.
///
/// Displays four items (RTL): الرئيسية, الرسومات, المواعيد, حسابي.
/// The active item is highlighted with a circular background (circle.png).
///
/// Optional parameters:
/// - [currentIndex]: Which item is active (0 = home). Defaults to 0. Clamped to 0..3.
/// - [onTap]: Callback when an item is tapped; receives the index. No logic by default.
///
/// Usage: Use as [Scaffold.bottomNavigationBar]. Wrap in [Directionality] (RTL)
/// when used in an RTL screen. The parent typically wraps in [Material]
/// (clipBehavior: Clip.none) for correct overflow.
///
/// Example:
///   bottomNavigationBar: Material(
///     clipBehavior: Clip.none,
///     color: Colors.transparent,
///     child: Directionality(
///       textDirection: TextDirection.rtl,
///       child: CaregiverBottomNav(currentIndex: 0),
///     ),
///   )
class CaregiverBottomNav extends StatelessWidget {
  const CaregiverBottomNav({super.key, this.currentIndex = 0, this.onTap});

  /// Index of the currently active item (0 = home, 1 = drawings, 2 = appointments, 3 = profile).
  final int currentIndex;

  /// Called when a nav item is tapped; receives the index. Optional.
  final ValueChanged<int>? onTap;

  /// Height of the bar. Use for content padding (e.g. scroll view bottom padding).
  static const double barHeight = 92;

  // --- Layout constants (must match original bar exactly; do not change visuals) ---
  static const double _bottomNavHeight = barHeight;
  static const double _navIconSize = 24;
  static const double _navLabelGap = 4;
  static const double _navActivePillWidth = 130;
  static const double _navActivePillHeight = 60;
  static const double _navLabelFontSize = 12;
  static const double _navItemPaddingV = 10;

  static const List<_NavItemData> _items = [
    _NavItemData(label: 'الرئيسية', iconAsset: 'assets/images/home icon.png'),
    _NavItemData(
      label: 'الرسومات',
      iconAsset: 'assets/images/drawings icon.png',
    ),
    _NavItemData(
      label: 'المواعيد',
      iconAsset: 'assets/images/calendar icon.png',
    ),
    _NavItemData(label: 'حسابي', iconAsset: 'assets/images/profile icon.png'),
  ];

  @override
  Widget build(BuildContext context) {
    final index = currentIndex.clamp(0, _items.length - 1);
    return Container(
      height: _bottomNavHeight,
      clipBehavior: Clip.none,
      decoration: BoxDecoration(
        color: BColors.white,
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.08),
            offset: const Offset(0, -2),
            blurRadius: 8,
            spreadRadius: 0,
          ),
        ],
      ),
      alignment: Alignment.center,
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceEvenly,
        mainAxisSize: MainAxisSize.max,
        crossAxisAlignment: CrossAxisAlignment.center,
        textDirection: TextDirection.rtl,
        children: [
          for (int i = 0; i < _items.length; i++)
            Expanded(
              child: Center(
                child: _buildNavItem(
                  label: _items[i].label,
                  iconAsset: _items[i].iconAsset,
                  active: i == index,
                  onTap: onTap != null ? () => onTap!(i) : null,
                ),
              ),
            ),
        ],
      ),
    );
  }

  Widget _buildNavItem({
    required String label,
    required String iconAsset,
    required bool active,
    VoidCallback? onTap,
  }) {
    final color = BColors.textBlack;
    final iconWidget = Image.asset(
      iconAsset,
      width: _navIconSize,
      height: _navIconSize,
      fit: BoxFit.contain,
      filterQuality: FilterQuality.high,
      isAntiAlias: true,
    );
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        ColorFiltered(
          colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
          child: iconWidget,
        ),
        SizedBox(height: _navLabelGap),
        Text(
          label,
          style: TextStyle(
            fontFamily: 'Markazi Text',
            fontSize: _navLabelFontSize,
            color: color,
          ),
        ),
      ],
    );

    final child = active
        ? Container(
            width: _navActivePillWidth,
            height: _navActivePillHeight,
            clipBehavior: Clip.none,
            alignment: Alignment.center,
            decoration: BoxDecoration(
              image: DecorationImage(
                image: AssetImage('assets/images/circle.png'),
                fit: BoxFit.contain,
                alignment: Alignment.center,
                filterQuality: FilterQuality.high,
              ),
            ),
            child: content,
          )
        : Padding(
            padding: const EdgeInsets.symmetric(vertical: _navItemPaddingV),
            child: content,
          );

    if (onTap != null) {
      return GestureDetector(
        onTap: onTap,
        behavior: HitTestBehavior.opaque,
        child: child,
      );
    }
    return child;
  }
}

class _NavItemData {
  const _NavItemData({required this.label, required this.iconAsset});
  final String label;
  final String iconAsset;
}

// USAGE EXAMPLE
//
// Default (home active, no tap handling):
//
//   bottomNavigationBar: Material(
//     clipBehavior: Clip.none,
//     color: Colors.transparent,
//     child: Directionality(
//       textDirection: TextDirection.rtl,
//       child: CaregiverBottomNav(),
//     ),
//   )
//
// With optional currentIndex and onTap:
//
//   CaregiverBottomNav(
//     currentIndex: 0,
//     onTap: (index) { /* navigate to tab index */ },
//   )
//
