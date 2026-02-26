import 'package:bouh/View/DrawingAnalysis/DrawingHistoryPage.dart';
import 'package:bouh/View/DrawingAnalysis/UploadDrawingPage.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/radius.dart';
import 'package:bouh/theme/base_themes/typography.dart';


//First page for drawing analysis feature
class RequestAnalysisPage extends StatefulWidget {
  const RequestAnalysisPage({
    super.key,
    this.currentIndex = 1,
    this.onTap,
  });

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

  String? _selectedChild; //Selected child name from dropdown
  final List<String> _childrenNames = [
    //Dummy data of children names
    'ليان',
    'بسام',
    'خزامى',
  ];

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
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    const SizedBox(height: 16),
                    _buildTopBar(),
                    const Spacer(flex: 5),
                    _buildTitle(),
                    const SizedBox(height: 40),
                    _buildChildDropdown(),
                    const SizedBox(height: 130),
                    _buildStartButton(),
                    const Spacer(flex: 3),
                  ],
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
                builder: (context) =>
                    DrawingHistoryPage(selectedChildName: _selectedChild),
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
          child: Text('اختر الطفل الذي تود تحليل رسمته', style: BTypography.labelText),
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
            onTap: _showChildMenu,
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
                    child: Text(
                      _selectedChild ?? 'اختر اسم الطفل',
                      style: _selectedChild != null
                          ? BTypography.dropdownSelected
                          : BTypography.dropdownHint,
                      textAlign: TextAlign.right,
                    ),
                  ),
                  const Icon(Icons.keyboard_arrow_down, color: BColors.darkGrey),
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
    final screenWidth = MediaQuery.of(context).size.width;//
    final top = pos.dy + size.height;
    // Align menue (RTL)
    final left = pos.dx + size.width - _menuWidth;
    final right = screenWidth - pos.dx - size.width;

    showMenu<String>(

      context: context,
      position: RelativeRect.fromLTRB(left, top, right, 0),
      shape: RoundedRectangleBorder(borderRadius: BRadius.dropdownRadius),
      color: BColors.secondry,
      items: _childrenNames.asMap().entries.map((entry) {
        final index = entry.key;
        final name = entry.value;
        final itemColor = index.isEven ? BColors.secondry : BColors.white;

        return PopupMenuItem<String>(
          value: name,
          padding: EdgeInsets.zero,
          child: Container(
            width: _menuWidth,
            height: 48,
            color: itemColor,
            padding: const EdgeInsets.symmetric(horizontal: 24),
            alignment: Alignment.centerRight,
            child: Text(
              name,
              textAlign: TextAlign.right,
              style: BTypography.dropdownSelected,
            ),
          ),
        );
      }).toList(),
    ).then((value) {
      if (value != null) setState(() => _selectedChild = value); //update the selected child
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
                    builder: (context) =>
                        UploadDrawingPage(selectedChildName: _selectedChild),
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
}