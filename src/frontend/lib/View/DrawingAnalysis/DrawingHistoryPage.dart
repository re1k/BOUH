import 'package:bouh/widgets/loading_overlay.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/radius.dart';
import 'package:bouh/theme/base_themes/typography.dart';
import 'package:bouh/authentication/AuthSession.dart';
import 'package:bouh/services/ChildrenService.dart';
import 'package:bouh/services/DrawingAnalysisService.dart';
import 'package:bouh/dto/DrawingAnalysis/DrawingDto.dart';
import 'package:bouh/View/DrawingAnalysis/AnalysisResultsPage.dart';

class DrawingHistoryPage extends StatefulWidget {
  const DrawingHistoryPage({super.key});

  @override
  State<DrawingHistoryPage> createState() => _DrawingHistoryPageState();
}

class _DrawingHistoryPageState extends State<DrawingHistoryPage> {
  final _childrenService = ChildrenService();
  final _analysisService = DrawingAnalysisService();

  final GlobalKey _dropdownKey = GlobalKey();
  static const double _menuWidth = 280;

  // ── Children dropdown ───────────────────────────────────────────────────────
  List<({String id, String name})> _children = [];
  bool _loadingChildren = true;
  ({String id, String name})? _selectedChild;

  // ── History / pagination ────────────────────────────────────────────────────
  List<DrawingDto> _drawings = [];
  String? _nextCursor;
  bool _loadingHistory = false;
  bool _loadingMore = false;
  String? _historyError;

  final ScrollController _scrollController = ScrollController();

  @override
  void initState() {
    super.initState();
    _loadChildren();
    // When user scrolls within 200px of the bottom, load next page
    _scrollController.addListener(() {
      final pos = _scrollController.position;
      if (pos.pixels >= pos.maxScrollExtent - 200 &&
          _nextCursor != null &&
          !_loadingMore) {
        _loadMoreHistory();
      }
    });
  }

  @override
  void dispose() {
    _scrollController.dispose();
    super.dispose();
  }

  // ── Data loading ────────────────────────────────────────────────────────────

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

  // Resets history and loads page 1 for the selected child
  Future<void> _loadFirstPage(String childId) async {
    setState(() {
      _drawings = [];
      _nextCursor = null;
      _loadingHistory = true;
      _historyError = null;
    });
    try {
      final page = await _analysisService.getHistory(childId: childId);
      setState(() {
        _drawings = page.records;
        _nextCursor = page.nextCursor;
        _loadingHistory = false;
      });
    } catch (e) {
      setState(() {
        _historyError = e.toString();
        _loadingHistory = false;
      });
    }
  }

  // Appends the next page when user scrolls to the bottom
  Future<void> _loadMoreHistory() async {
    if (_selectedChild == null || _nextCursor == null) return;
    setState(() => _loadingMore = true);
    try {
      final page = await _analysisService.getHistory(
        childId: _selectedChild!.id,
        cursor: _nextCursor,
      );
      setState(() {
        _drawings.addAll(page.records);
        _nextCursor = page.nextCursor;
        _loadingMore = false;
      });
    } catch (e) {
      setState(() => _loadingMore = false);
    }
  }

  // ── Build ───────────────────────────────────────────────────────────────────

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              const SizedBox(height: 16),
              _buildBackButton(context),
              const SizedBox(height: 32),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildChildDropdown(),
                      const SizedBox(height: 24),

                      if (_selectedChild == null)
                        _buildEmptyState()
                      else if (_loadingHistory)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 60),
                          child: Center(
                            child: BouhLoadingOverlay(showBarrier: false),
                          ),
                        )
                      else if (_historyError != null)
                        _buildErrorState()
                      else
                        _buildDrawingList(),

                      // Small spinner at bottom while loading page 2+
                      if (_loadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: BouhLoadingOverlay(showBarrier: false),
                          ),
                        ),

                      const SizedBox(height: 24),
                    ],
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }

  // ── Widgets ─────────────────────────────────────────────────────────────────

  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: BColors.darkGrey,
              size: 22,
            ),
          ),
          Expanded(
            child: Center(
              child: Text(
                'الرسومات السابقة',
                style: BTypography.labelText.copyWith(
                  fontWeight: FontWeight.w700,
                  fontSize: 24,
                ),
                textAlign: TextAlign.center,
              ),
            ),
          ),
          const SizedBox(width: 48),
        ],
      ),
    );
  }

  Widget _buildChildDropdown() {
    return Container(
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
                child: const Icon(
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
                        child: BouhLoadingOverlay(showBarrier: false, size: 16),
                      )
                    : Text(
                        _selectedChild?.name ??
                            'اختر الطفل الذي تود رؤيه رسوماته',
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
    );
  }

  void _showChildMenu() {
    final box = _dropdownKey.currentContext?.findRenderObject() as RenderBox?;
    if (box == null) return;
    final pos = box.localToGlobal(Offset.zero);
    final size = box.size;
    final screenWidth = MediaQuery.sizeOf(context).width;

    showMenu<({String id, String name})>(
      context: context,
      position: RelativeRect.fromLTRB(
        pos.dx + size.width - _menuWidth,
        pos.dy + size.height,
        screenWidth - pos.dx - size.width,
        0,
      ),
      shape: RoundedRectangleBorder(borderRadius: BRadius.dropdownRadius),
      color: BColors.secondry,
      items: _children.asMap().entries.map((entry) {
        return PopupMenuItem<({String id, String name})>(
          value: entry.value,
          padding: EdgeInsets.zero,
          child: Container(
            width: _menuWidth,
            height: 48,
            color: entry.key.isEven ? BColors.secondry : BColors.white,
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
      if (selected == null) return;
      setState(() => _selectedChild = selected);
      _loadFirstPage(selected.id);
    });
  }

  static const String _emptyStateImageAsset =
      'assets/images/NoSelectedChild_PlaceHolder.png';

  Widget _buildEmptyState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 48, horizontal: 24),
      child: Center(
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Image.asset(
              _emptyStateImageAsset,
              height: 370,
              fit: BoxFit.contain,
              errorBuilder: (_, __, ___) => Icon(
                Icons.brush_outlined,
                size: 120,
                color: BColors.darkGrey.withValues(alpha: 0.4),
              ),
            ),
            const SizedBox(height: 24),
          ],
        ),
      ),
    );
  }

  Widget _buildErrorState() {
    return Padding(
      padding: const EdgeInsets.symmetric(vertical: 32),
      child: Center(
        child: Column(
          children: [
            Text(
              'حدث خطأ أثناء تحميل الرسومات',
              style: BTypography.bodyText.copyWith(color: BColors.darkGrey),
              textAlign: TextAlign.center,
            ),
            const SizedBox(height: 12),
            TextButton(
              onPressed: () => _loadFirstPage(_selectedChild!.id),
              child: const Text('إعادة المحاولة'),
            ),
          ],
        ),
      ),
    );
  }

  Widget _buildDrawingList() {
    if (_drawings.isEmpty) {
      return Padding(
        padding: const EdgeInsets.symmetric(vertical: 32),
        child: Center(
          child: Text(
            'لا توجد رسمات سابقة لهذا الطفل',
            style: BTypography.bodyText.copyWith(color: BColors.darkGrey),
            textAlign: TextAlign.center,
          ),
        ),
      );
    }

    return Column(
      mainAxisSize: MainAxisSize.min,
      children: List.generate(
        _drawings.length,
        (i) => Padding(
          padding: const EdgeInsets.only(bottom: 20),
          child: _buildDrawingCard(_drawings[i]),
        ),
      ),
    );
  }

  Widget _buildDrawingCard(DrawingDto item) {
    // Parse ISO timestamp → readable Arabic date e.g. "15/2/2024"
    String dateText = '';
    try {
      final dt = DateTime.parse(item.createdAt);
      dateText = '${dt.day}/${dt.month}/${dt.year}';
    } catch (_) {
      dateText = item.createdAt;
    }

    return Container(
      decoration: BoxDecoration(
        color: BColors.white,
        borderRadius: BorderRadius.circular(BRadius.cardLarge),
        border: Border.all(color: BColors.grey, width: 1),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withValues(alpha: 0.06),
            blurRadius: 8,
            offset: const Offset(0, 2),
          ),
        ],
      ),
      child: ClipRRect(
        borderRadius: BorderRadius.circular(BRadius.cardLarge),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          mainAxisSize: MainAxisSize.min,
          children: [
            // Drawing image — real GCS URL via Image.network
            AspectRatio(
              aspectRatio: 16 / 10,
              child: item.imageURL.isNotEmpty
                  ? Image.network(
                      item.imageURL,
                      fit: BoxFit.cover,
                      errorBuilder: (_, __, ___) => _imagePlaceholder(),
                    )
                  : _imagePlaceholder(),
            ),

            Padding(
              padding: const EdgeInsets.all(12),
              child: Row(
                children: [
                  // Date badge
                  Container(
                    padding: const EdgeInsets.symmetric(
                      horizontal: 14,
                      vertical: 10,
                    ),
                    decoration: BoxDecoration(
                      color: BColors.softGrey,
                      borderRadius: BorderRadius.circular(BRadius.buttonMedium),
                    ),
                    child: Text(
                      dateText,
                      style: BTypography.labelText.copyWith(
                        color: BColors.darkGrey,
                      ),
                    ),
                  ),
                  const SizedBox(width: 12),

                  Expanded(
                    child: ElevatedButton(
                      onPressed: () {
                        // Data already in memory — no extra API call needed
                        Navigator.of(context).push(
                          MaterialPageRoute<void>(
                            builder: (_) => AnalysisResultsPage(
                              hideStepper: true,
                              emotionalInterpretation:
                                  item.emotionalInterpretation,
                              doctors: item.doctors,
                            ),
                          ),
                        );
                      },
                      style: ElevatedButton.styleFrom(
                        backgroundColor: BColors.accent,
                        foregroundColor: BColors.white,
                        padding: const EdgeInsets.symmetric(vertical: 12),
                        shape: RoundedRectangleBorder(
                          borderRadius: BorderRadius.circular(
                            BRadius.buttonMedium,
                          ),
                        ),
                        elevation: 0,
                      ),
                      child: Text(
                        'تحليل الرسمة',
                        style: BTypography.labelText.copyWith(
                          color: BColors.white,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  Widget _imagePlaceholder() {
    return Container(
      color: BColors.softGrey,
      child: Center(
        child: Icon(
          Icons.draw,
          size: 48,
          color: BColors.darkGrey.withValues(alpha: 0.6),
        ),
      ),
    );
  }
}
