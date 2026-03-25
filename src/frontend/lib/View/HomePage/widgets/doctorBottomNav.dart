import 'package:flutter/material.dart';
import 'package:flutter_svg/flutter_svg.dart';

import 'package:bouh/theme/base_themes/colors.dart';

/// Reusable bottom navigation bar for the doctor view.
///
/// Displays three items (RTL): الرئيسية, المواعيد, حسابي.
///
/// Optional parameters:
/// - [currentIndex]: Which item is active (0 = home). Defaults to 0. Clamped to 0..2.
/// - [onTap]: Callback when an item is tapped; receives the index.
///
/// Usage: Use as [Scaffold.bottomNavigationBar]. Wrap in [Directionality] (RTL)
/// when used in an RTL screen. The parent typically wraps in [Material]
/// (clipBehavior: Clip.none) for correct overflow.
class DoctorBottomNav extends StatelessWidget {
  const DoctorBottomNav({super.key, this.currentIndex = 0, this.onTap});

  /// Index of the currently active item (0 = home, 1 = appointments, 2 = profile).
  final int currentIndex;

  /// Called when a nav item is tapped; receives the index. Optional.
  final ValueChanged<int>? onTap;

  /// Height of the bar. Use for content padding (e.g. scroll view bottom padding).
  /// Matches caregiver bar height.
  static const double barHeight = 92;

  // --- Layout constants ---
  static const double _bottomNavHeight = barHeight;
  static const double _navLabelGap = 4;
  static const double _navActivePillWidth = 130;
  static const double _navActivePillHeight = 60;
  static const double _navLabelFontSize = 12;
  static const double _navItemPaddingV = 10;

  static const List<_NavItemData> _items = [
    _NavItemData(label: 'الرئيسية', iconAsset: 'assets/images/home icon.svg'),
    _NavItemData(
      label: 'المواعيد',
      iconAsset: 'assets/images/calendar icon.svg',
    ),
    _NavItemData(label: 'حسابي', iconAsset: 'assets/images/profile icon.svg'),
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
    final iconWidget = _NavTabSvgIcon(assetPath: iconAsset, color: color);
    final content = Column(
      mainAxisSize: MainAxisSize.min,
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        iconWidget,
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
        ? SizedBox(
            width: _navActivePillWidth,
            height: _navActivePillHeight,
            child: Stack(
              alignment: Alignment.center,
              clipBehavior: Clip.none,
              children: [
                SvgPicture.asset(
                  'assets/images/circle.svg',
                  width: _navActivePillWidth,
                  height: _navActivePillHeight,
                  fit: BoxFit.contain,
                ),
                content,
              ],
            ),
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

class _NavTabSvgIcon extends StatelessWidget {
  const _NavTabSvgIcon({required this.assetPath, required this.color});

  static const double _box = 25;

  final String assetPath;
  final Color color;

  bool _isDrawingsAsset() => assetPath.toLowerCase().contains('drawings');

  @override
  Widget build(BuildContext context) {
    final useContain = _isDrawingsAsset();
    final fit = useContain ? BoxFit.contain : BoxFit.cover;
    return SizedBox(
      width: _box,
      height: _box,
      child: SvgPicture.asset(
        assetPath,
        width: _box,
        height: _box,
        fit: fit,
        alignment: Alignment.center,
        clipBehavior: useContain ? Clip.none : Clip.hardEdge,
        colorFilter: ColorFilter.mode(color, BlendMode.srcIn),
      ),
    );
  }
}
