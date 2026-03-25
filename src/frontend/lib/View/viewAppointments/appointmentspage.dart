import 'dart:async';
import 'package:flutter/material.dart';

import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/View/caregiverHomepage/widgets/suggestedDoctorCard.dart';
import 'package:bouh/View/caregiverHomepage/widgets/caregiverBottomNav.dart';
import 'package:bouh/View/BookAppointment/DoctorDetails.dart';

import 'package:bouh/dto/doctorSummaryDto.dart';
import 'package:bouh/services/DoctorSearchService.dart';
import 'package:bouh/widgets/loading_overlay.dart';

class AppointmentsPage extends StatefulWidget {
  const AppointmentsPage({
    super.key,
    this.currentIndex = 2,
    this.onTap,
    this.onSwitchToBooked,
  });

  final int currentIndex;
  final ValueChanged<int>? onTap;
  final VoidCallback? onSwitchToBooked;

  @override
  State<AppointmentsPage> createState() => _AppointmentsPageState();
}

class _AppointmentsPageState extends State<AppointmentsPage> {
  final TextEditingController _searchController = TextEditingController();
  final ScrollController _scrollController = ScrollController();

  List<DoctorSummaryDto> _allDoctors = [];
  List<DoctorSummaryDto> _filteredDoctors = [];
  List<DoctorSummaryDto> _searchResults = [];

  bool _isLoading = false;
  String? _error;
  Timer? _debounce;
  String? _selectedArea;
  bool _hasMore = true;
  String? _lastDoctorId;
  bool _isLoadingMore = false;
  bool _isSearching = false;
  final Map<String, String> _cachedPhotoUrls = {};
  Timer? _refreshTimer;
  Timer? _defaultRefreshTimer;
  final DoctorSearchService _service = DoctorSearchService();

  static const double _titleTopPadding = 24;
  static const double _titleBottomPadding = 24;
  static const double _tabHeight = 44;
  static const double _tabRadius = 12;
  static const double _tabContainerPadding = 4;
  static const double _searchFilterGap = 8;
  static const double _searchHeight = 48;
  static const double _searchRadius = 12;
  static const double _filterButtonSize = 48;
  static const double _sectionGap = 24;
  static const double _cardGap = 16;

  static const Color _tabContainerBg = Color(0xFFF0F2F4);
  static const Color _tabActiveBg = Color(0xFFFFFFFF);
  static const Color _tabActiveColor = Color(0xFF2C3E50);
  static const Color _tabInactiveColor = Color(0xFF7D8A96);
  static const Color _searchBorderColor = Color(0xFFE8EBED);
  static const Color _filterButtonBg = Color(0xFF5B8FA3);
  static const List<String> _areas = [
    'الكل',
    'توتر وقلق',
    'خوف',
    'حزن',
    'تفاؤل',
    'غضب',
  ];

  @override
  void initState() {
    super.initState();
    _searchController.addListener(_onSearchChanged);
    _scrollController.addListener(() {
      if (_scrollController.position.pixels >=
          _scrollController.position.maxScrollExtent - 200) {
        if (!_isSearching && _selectedArea == null) _loadMore();
      }
    });
    _loadDoctorsForCaregiver();
    _defaultRefreshTimer = Timer.periodic(const Duration(seconds: 3), (
      _,
    ) async {
      if (!_isSearching && _selectedArea == null) {
        try {
          final (doctors, hasMore) = await _service.getTopRatedDoctors();
          for (final doc in doctors) {
            if (doc.profilePhotoURL != null &&
                doc.profilePhotoURL!.isNotEmpty &&
                !_cachedPhotoUrls.containsKey(doc.doctorId)) {
              _cachedPhotoUrls[doc.doctorId!] = doc.profilePhotoURL!;
            }
          }
          setState(() {
            _allDoctors = doctors;
            _filteredDoctors = doctors;
            _hasMore = hasMore;
            _lastDoctorId = doctors.isNotEmpty ? doctors.last.doctorId : null;
          });
        } catch (_) {}
      }
    });
  }

  Future<void> _loadDoctorsForCaregiver() async {
    setState(() {
      _isLoading = true;
      _error = null;
      _allDoctors = [];
      _lastDoctorId = null;
      _hasMore = true;
    });

    try {
      final (doctors, hasMore) = await _service.getTopRatedDoctors();
      setState(() {
        _allDoctors = doctors;
        _filteredDoctors = doctors;
        _hasMore = hasMore;
        _lastDoctorId = doctors.isNotEmpty ? doctors.last.doctorId : null;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في تحميل الأطباء';
        _isLoading = false;
      });
    }
  }

  Future<void> _loadMore() async {
    if (_isLoadingMore || !_hasMore || _lastDoctorId == null) return;
    setState(() => _isLoadingMore = true);
    try {
      final (doctors, hasMore) = await _service.getTopRatedDoctors(
        lastDoctorId: _lastDoctorId,
      );
      setState(() {
        _allDoctors.addAll(doctors);
        _filteredDoctors = _allDoctors;
        _hasMore = hasMore;
        _lastDoctorId = doctors.isNotEmpty ? doctors.last.doctorId : null;
        _isLoadingMore = false;
      });
    } catch (e) {
      setState(() => _isLoadingMore = false);
    }
  }

  // ── 10.2.32  filter by area ───────────────────────────────────────────────────
  Future<void> _onAreaSelected(String area) async {
    // "الكل" clears the filter
    if (area == 'الكل') {
      setState(() => _selectedArea = null);
      if (!_isSearching)
        await _loadDoctorsForCaregiver(); // ← fresh fetch
      else
        setState(() => _filteredDoctors = _searchResults);
      return;
    }

    if (_selectedArea == area) {
      setState(() => _selectedArea = null);
      if (!_isSearching)
        await _loadDoctorsForCaregiver(); // ← fresh fetch
      else
        setState(() => _filteredDoctors = _searchResults);
      return;
    }

    setState(() => _selectedArea = area);

    // search is active → filter raw search results locally, no API call
    if (_isSearching) {
      setState(() {
        _filteredDoctors = _searchResults
            .where((d) => d.areaOfKnowledge == area)
            .toList();
      });
      return;
    }

    // no search active → call backend
    _startRefreshTimer();
    setState(() {
      _isLoading = true;
      _error = null;
    });

    try {
      final results = await _service.filterDoctors(area);
      setState(() {
        _filteredDoctors = results;
        _isLoading = false;
      });
    } catch (e) {
      setState(() {
        _error = 'حدث خطأ في التصفية';
        _isLoading = false;
      });
    }
  }

  // ── 10.2.31  search by name — calls backend ───────────────────────────────────
  void _onSearchChanged() {
    if (_debounce?.isActive ?? false) _debounce!.cancel();

    _debounce = Timer(const Duration(milliseconds: 300), () async {
      final q = _searchController.text.trim();

      if (q.isEmpty) {
        setState(() {
          _isSearching = false;
          _searchResults = [];
          _filteredDoctors = _selectedArea != null
              ? _allDoctors
                    .where((d) => d.areaOfKnowledge == _selectedArea)
                    .toList()
              : _allDoctors;
        });
        if (_selectedArea == null) _refreshTimer?.cancel();
        return;
      }

      setState(() => _isSearching = true);
      _startRefreshTimer();

      try {
        final results = await _service.searchDoctors(q);
        _searchResults = results;
        final filtered = _selectedArea != null
            ? results.where((d) => d.areaOfKnowledge == _selectedArea).toList()
            : results;
        setState(() => _filteredDoctors = filtered);
      } catch (e) {
        setState(() {
          _searchResults = [];
          _filteredDoctors = [];
        });
      }
    });
  }

  void _startRefreshTimer() {
    _refreshTimer?.cancel();
    _refreshTimer = Timer.periodic(const Duration(seconds: 3), (_) async {
      final q = _searchController.text.trim();

      if (q.isNotEmpty) {
        try {
          final results = await _service.searchDoctors(q);
          _searchResults = results;
          final filtered = _selectedArea != null
              ? results
                    .where((d) => d.areaOfKnowledge == _selectedArea)
                    .toList()
              : results;
          setState(() => _filteredDoctors = filtered);
        } catch (_) {}
      } else if (_selectedArea != null) {
        try {
          final results = await _service.filterDoctors(_selectedArea!);
          setState(() => _filteredDoctors = results);
        } catch (_) {}
      } else {
        _refreshTimer?.cancel();
      }
    });
  }

  @override
  void dispose() {
    _refreshTimer?.cancel();
    _defaultRefreshTimer?.cancel();
    _searchController.removeListener(_onSearchChanged);
    _searchController.dispose();
    _scrollController.dispose();
    _debounce?.cancel();
    super.dispose();
  }

  void _openDoctorDetails(DoctorSummaryDto doctor) {
    Navigator.push(
      context,
      MaterialPageRoute(builder: (_) => DoctorDetailsView(doctor: doctor)),
    );
  }

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
              _buildTitle(),
              Expanded(
                child: SingleChildScrollView(
                  controller: _scrollController,
                  padding: const EdgeInsets.symmetric(horizontal: 16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      _buildSegmentedControl(),
                      const SizedBox(height: _sectionGap),
                      _buildSearchAndFilter(),
                      const SizedBox(height: _sectionGap),
                      _buildDoctorList(),
                      if (_isLoadingMore)
                        const Padding(
                          padding: EdgeInsets.symmetric(vertical: 16),
                          child: Center(
                            child: BouhOvalLoadingIndicator(
                              width: 28,
                              height: 20,
                              strokeWidth: 2.5,
                            ),
                          ),
                        ),
                      SizedBox(height: CaregiverBottomNav.barHeight + _cardGap),
                    ],
                  ),
                ),
              ),
            ],
          ),
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

  Widget _buildTitle() {
    return Padding(
      padding: const EdgeInsets.only(
        top: _titleTopPadding,
        bottom: _titleBottomPadding,
      ),
      child: Text(
        'المواعيد',
        textAlign: TextAlign.center,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 24,
          fontWeight: FontWeight.w600,
          color: _tabActiveColor,
        ),
      ),
    );
  }

  Widget _buildSegmentedControl() {
    return Container(
      height: _tabHeight + _tabContainerPadding * 2,
      padding: const EdgeInsets.all(_tabContainerPadding),
      decoration: BoxDecoration(
        color: _tabContainerBg,
        borderRadius: BorderRadius.circular(_tabRadius + _tabContainerPadding),
      ),
      child: Row(
        textDirection: TextDirection.rtl,
        children: [
          Expanded(child: _buildTabSegment(label: 'متاحة', active: true)),
          Expanded(
            child: GestureDetector(
              onTap: widget.onSwitchToBooked,
              behavior: HitTestBehavior.opaque,
              child: _buildTabSegment(label: 'محجوزة', active: false),
            ),
          ),
        ],
      ),
    );
  }

  Widget _buildTabSegment({required String label, required bool active}) {
    return Container(
      height: _tabHeight,
      alignment: Alignment.center,
      decoration: BoxDecoration(
        color: active ? _tabActiveBg : Colors.transparent,
        borderRadius: BorderRadius.circular(_tabRadius),
        boxShadow: active
            ? [
                BoxShadow(
                  color: Colors.black.withValues(alpha: 0.1),
                  offset: const Offset(0, 1),
                  blurRadius: 3,
                ),
              ]
            : null,
      ),
      child: Text(
        label,
        style: TextStyle(
          fontFamily: 'Markazi Text',
          fontSize: 16,
          fontWeight: active ? FontWeight.w600 : FontWeight.w400,
          color: active ? _tabActiveColor : _tabInactiveColor,
        ),
      ),
    );
  }

  Widget _buildSearchAndFilter() {
    return Row(
      textDirection: TextDirection.rtl,
      children: [
        PopupMenuButton<String>(
          color: BColors.white,
          onSelected: _onAreaSelected,
          itemBuilder: (_) => [
            for (final area in _areas)
              PopupMenuItem(
                value: area,
                child: Row(
                  children: [
                    if (_selectedArea == area)
                      const Icon(
                        Icons.check,
                        size: 16,
                        color: Color(0xFF5B8FA3),
                      ),
                    if (_selectedArea == area) const SizedBox(width: 6),
                    Text(area),
                  ],
                ),
              ),
          ],
          offset: const Offset(0, 50),
          child: Container(
            width: _filterButtonSize,
            height: _filterButtonSize,
            decoration: BoxDecoration(
              color: _filterButtonBg,
              borderRadius: BorderRadius.circular(_searchRadius),
            ),
            // ── shows selected area name or default icon ──
            child: _selectedArea != null
                ? Center(
                    child: Padding(
                      padding: const EdgeInsets.symmetric(horizontal: 4),
                      child: Text(
                        _selectedArea!,
                        textAlign: TextAlign.center,
                        textDirection: TextDirection.rtl,
                        maxLines: 2,
                        style: const TextStyle(
                          color: BColors.white,
                          fontSize: 10,
                          fontWeight: FontWeight.w600,
                        ),
                      ),
                    ),
                  )
                : const Icon(Icons.tune, color: BColors.white, size: 24),
          ),
        ),
        const SizedBox(width: _searchFilterGap),
        Expanded(
          child: SizedBox(
            height: _searchHeight,
            child: TextField(
              controller: _searchController,
              textDirection: TextDirection.rtl,
              decoration: InputDecoration(
                filled: true,
                fillColor: BColors.white,
                border: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_searchRadius),
                  borderSide: const BorderSide(color: _searchBorderColor),
                ),
                enabledBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_searchRadius),
                  borderSide: const BorderSide(color: _searchBorderColor),
                ),
                focusedBorder: OutlineInputBorder(
                  borderRadius: BorderRadius.circular(_searchRadius),
                  borderSide: const BorderSide(color: _searchBorderColor),
                ),
                contentPadding: const EdgeInsets.symmetric(
                  horizontal: 16,
                  vertical: 12,
                ),
                prefixIcon: const Icon(
                  Icons.search,
                  size: 22,
                  color: _tabInactiveColor,
                ),
                prefixIconConstraints: const BoxConstraints(
                  minWidth: 44,
                  minHeight: 44,
                ),
              ),
              style: TextStyle(
                fontFamily: 'Markazi Text',
                fontSize: 14,
                color: _tabActiveColor,
              ),
            ),
          ),
        ),
      ],
    );
  }

  Widget _buildDoctorList() {
    if (_isLoading) {
      return const Center(
        child: BouhLoadingOverlay(showBarrier: false, size: 48),
      );
    }

    if (_error != null) {
      return Center(
        child: Text(_error!, style: const TextStyle(color: Colors.red)),
      );
    }

    if (_filteredDoctors.isEmpty) {
      final q = _searchController.text.trim();
      if (q.isEmpty && _selectedArea == null) {
        return const Center(child: Text("لا يوجد أطباء حالياً"));
      }
      return const Center(child: Text("لا توجد نتائج مطابقة"));
    }

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        for (int i = 0; i < _filteredDoctors.length; i++) ...[
          InkWell(
            onTap: () => _openDoctorDetails(_filteredDoctors[i]),
            child: SuggestedDoctorCard(
              name: _filteredDoctors[i].name,
              specialty: _filteredDoctors[i].areaOfKnowledge,
              rating: _filteredDoctors[i].rating.toInt(),
              profileImage:
                  (_cachedPhotoUrls[_filteredDoctors[i].doctorId] ??
                          _filteredDoctors[i].profilePhotoURL) !=
                      null
                  ? NetworkImage(
                      _cachedPhotoUrls[_filteredDoctors[i].doctorId] ??
                          _filteredDoctors[i].profilePhotoURL!,
                    )
                  : null,
            ),
          ),
          if (i < _filteredDoctors.length - 1) const SizedBox(height: _cardGap),
        ],
      ],
    );
  }
}
