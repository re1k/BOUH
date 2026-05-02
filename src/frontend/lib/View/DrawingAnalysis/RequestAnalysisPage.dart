import 'dart:async';

import 'package:bouh/View/DrawingAnalysis/DrawingHistoryPage.dart';
import 'package:bouh/View/DrawingAnalysis/UploadDrawingPage.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/radius.dart';
import 'package:bouh/theme/base_themes/typography.dart';
import 'package:bouh/services/ChildrenService.dart';
import 'package:bouh/authentication/AuthSession.dart';

//First page for drawing analysis feature
class RequestAnalysisPage extends StatefulWidget {
  const RequestAnalysisPage({super.key, this.currentIndex = 1, this.onTap});

  //Active bottom nav index (1 = drawings). Pass when used inside CaregiverNavbar.
  final int currentIndex;

  //Called when a bottom nav item is tapped. Pass when used inside CaregiverNavbar.
  final ValueChanged<int>? onTap;

  @override
  State<RequestAnalysisPage> createState() => _RequestAnalysisPageState();
}

class _RequestAnalysisPageState extends State<RequestAnalysisPage> {
  final GlobalKey _dropdownKey = GlobalKey();
  static const double _menuWidth = 280;

  final _childrenService = ChildrenService();
  List<({String id, String name})> _children = [];
  bool _loadingChildren = true;
  ({String id, String name})? _selectedChild;

  Timer? _refreshTimer;

  @override
  void initState() {
    super.initState();
    _loadChildren();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) {
      _loadChildren();
    });
  }

  Future<void> _loadChildren() async {
    final caregiverId = AuthSession.instance.userId;
    if (caregiverId == null) return;
    try {
      final children = await _childrenService.getChildrenNames(caregiverId);
      setState(() {
        _children = children;
        _loadingChildren = false;
      });
    } catch (e) {
      setState(() => _loadingChildren = false);
    }
  }

  //Main build
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: Stack(
          clipBehavior: Clip.none,
          children: [
            //Decorative top image.
            Positioned(
              top: 0,
              left: 0,
              right: 0,
              child: Image.asset(
                'assets/images/wave_Draw.png',
                width: double.infinity,
                fit: BoxFit.cover,
              ),
            ),
            SafeArea(
              child: Padding(
                padding: const EdgeInsets.symmetric(horizontal: 24.0),
                child: SingleChildScrollView(
                  child: ConstrainedBox(
                    constraints: BoxConstraints(
                      minHeight:
                          MediaQuery.of(context).size.height -
                          MediaQuery.of(context).padding.top -
                          MediaQuery.of(context).padding.bottom -
                          80,
                    ),
                    child: IntrinsicHeight(
                      child: Column(
                        crossAxisAlignment: CrossAxisAlignment.stretch,
                        children: [
                          const SizedBox(height: 16),
                          _buildTopBar(),
                          const Spacer(flex: 3),
                          _buildTitle(),
                          const SizedBox(height: 24),
                          _buildChildDropdown(),
                          const Spacer(flex: 2),
                          _buildStartButton(),
                          const Spacer(flex: 2),
                        ],
                      ),
                    ),
                  ),
                ),
              ),
            ),
          ],
        ),
        bottomNavigationBar: Material(
          clipBehavior: Clip.none,
          color: Colors.transparent,
          child: Directionality(
            textDirection: TextDirection.rtl,
            child: CaregiverBottomNav(
              currentIndex: widget.currentIndex,
              onTap: widget.onTap,
            ),
          ),
        ),
      ),
    );
  }

  //Builds the top bar with previous drawings button
  Widget _buildTopBar() {
    return Row(
      mainAxisAlignment: MainAxisAlignment.end,
      children: [
        ElevatedButton.icon(
          onPressed: () {
            Navigator.of(context).push(
              MaterialPageRoute<void>(
                builder: (_) => const DrawingHistoryPage(),
              ),
            );
          },
          icon: const Icon(Icons.history, color: BColors.white, size: 21),
          label: Text(
            'الرسومات السابقة',
            style: BTypography.buttonText.copyWith(fontSize: 14),
          ),
          style: ElevatedButton.styleFrom(
            backgroundColor: BColors.accent,
            foregroundColor: BColors.white,
            padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 6),
            shape: RoundedRectangleBorder(
              borderRadius: BRadius.buttonMediumRadius,
            ),
            elevation: 0,
          ),
        ),
      ],
    );
  }

  //Builds page title
  Widget _buildTitle() {
    return Text(
      'حلل رسمة طفلك اليوم!',
      style: BTypography.pageTitle,
      textAlign: TextAlign.center,
    );
  }

  //Builds child selection dropdown
  Widget _buildChildDropdown() {
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Padding(
          padding: const EdgeInsets.only(bottom: 10, right: 6),
          child: Text(
            'اختر الطفل الذي تود تحليل رسمته',
            style: BTypography.labelText,
          ),
        ),

        //Dropdown container
        Container(
          key: _dropdownKey,
          height: 48,
          decoration: BoxDecoration(
            color: BColors.secondry,
            borderRadius: BRadius.dropdownRadius,
            border: Border.all(color: BColors.grey, width: 1),
          ),
          child: InkWell(
            onTap: _loadingChildren ? null : _showChildMenu,
            borderRadius: BRadius.dropdownRadius,
            child: Padding(
              padding: const EdgeInsets.symmetric(horizontal: 16),
              child: Row(
                children: [
                  Container(
                    padding: const EdgeInsets.all(6),
                    decoration: const BoxDecoration(
                      color: BColors.white,
                      shape: BoxShape.circle,
                    ),
                    child: Icon(
                      Icons.people_outline,
                      color: BColors.darkGrey,
                      size: 22,
                    ),
                  ),
                  const SizedBox(width: 12),
                  Expanded(
                    child: _loadingChildren
                        ? const SizedBox(
                            height: 16,
                            width: 16,
                            child: BouhOvalLoadingIndicator(),
                          )
                        : Text(
                            _selectedChild?.name ?? 'اختر اسم الطفل',
                            style: _selectedChild != null
                                ? BTypography.dropdownSelected
                                : BTypography.dropdownHint,
                            textAlign: TextAlign.right,
                          ),
                  ),
                  const Icon(
                    Icons.keyboard_arrow_down,
                    color: BColors.darkGrey,
                  ),
                ],
              ),
            ),
          ),
        ),
      ],
    );
  }

  //Custom menu list for the dropdown
  void _showChildMenu() {
    final box = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.of(context).size.width; //
    final top = pos.dy + size.height;
    // Align menue (RTL)
    final left = pos.dx + size.width - _menuWidth;
    final right = screenWidth - pos.dx - size.width;

    showMenu<({String id, String name})>(
      context: context,
      position: RelativeRect.fromLTRB(left, top, right, 0),
      shape: RoundedRectangleBorder(borderRadius: BRadius.dropdownRadius),
      color: BColors.secondry,
      items: _children.asMap().entries.map((entry) {
        final itemColor = _selectedChild?.id == entry.value.id
            ? BColors.white
            : BColors.secondry;
        return PopupMenuItem<({String id, String name})>(
          value: entry.value,
          padding: EdgeInsets.zero,
          child: Container(
            width: _menuWidth,
            height: 48,
            color: itemColor,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerRight,
            child: Text(
              entry.value.name,
              textAlign: TextAlign.right,
              style: BTypography.dropdownSelected,
            ),
          ),
        );
      }).toList(),
    ).then((selected) {
      if (selected != null)
        setState(() => _selectedChild = selected); //update the selected child
    });
  }

  //Builds the start analysis button
  Widget _buildStartButton() {
    return Center(
      child: ElevatedButton(
        onPressed: _selectedChild != null
            ? () {
                // Navigate to step 1: upload drawing (gallery or camera).
                // BACKEND: selectedChildName is passed through the flow for your API (e.g. associate analysis with child).
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => UploadDrawingPage(
                      childId: _selectedChild!.id,
                      childName: _selectedChild!.name,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: BColors.accent,
          disabledBackgroundColor: BColors.grey,
          padding: const EdgeInsets.symmetric(horizontal: 92, vertical: 8),
          shape: RoundedRectangleBorder(
            borderRadius: BRadius.buttonLargeRadius,
          ),
          elevation: 0,
        ),
        child: Text('بدء', style: BTypography.buttonText),
      ),
    );
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    super.dispose();
  }
}
