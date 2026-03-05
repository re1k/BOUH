import 'package:bouh/View/BookAppointment/BookAppointment.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/dto/doctorSummaryDto.dart';

class DoctorDetailsView extends StatefulWidget {
  final DoctorSummaryDto doctor;

  const DoctorDetailsView({super.key, required this.doctor});

  @override
  State<DoctorDetailsView> createState() => _DoctorDetailsViewState();
}

class _DoctorDetailsViewState extends State<DoctorDetailsView> {
  int tabIndex = 0;

  @override
  Widget build(BuildContext context) {
    final doctorName = widget.doctor.name;
    final doctorMajor = widget.doctor.areaOfKnowledge;
    final rating = widget.doctor.rating;

    // Keep years as dummy (until backend/DTO provides it)
    final years = 10;

    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        body: Stack(
          children: [
            SingleChildScrollView(
              padding: EdgeInsets.zero,
              child: Column(
                children: [
                  _DoctorInfoCard(
                    doctorName: doctorName,
                    doctorMajor: doctorMajor,
                    rating: rating,
                    years: years,
                    tabIndex: tabIndex,
                    onTapQualifications: () => setState(() => tabIndex = 0),
                    onTapBooking: () => setState(() => tabIndex = 1),
                  ),
                  const SizedBox(height: 18),
                  Padding(
                    padding: const EdgeInsets.symmetric(horizontal: 18),
                    child: Column(
                      children: [
                        if (tabIndex == 0) const _QualificationsSection(),
                        if (tabIndex == 1)
                          BookingView(
                            // doctorId: widget.doctor.doctorID,
                          ),
                        const SizedBox(height: 18),
                      ],
                    ),
                  ),
                ],
              ),
            ),
            SafeArea(
              child: Positioned(
                top: 8,
                right: 12,
                child: InkWell(
                  onTap: () => Navigator.pop(context),
                  child: const Icon(Icons.chevron_left, size: 34),
                ),
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _DoctorInfoCard extends StatelessWidget {
  final String doctorName;
  final String doctorMajor;
  final double rating;
  final int years;
  final int tabIndex;
  final VoidCallback onTapQualifications;
  final VoidCallback onTapBooking;

  const _DoctorInfoCard({
    required this.doctorName,
    required this.doctorMajor,
    required this.rating,
    required this.years,
    required this.tabIndex,
    required this.onTapQualifications,
    required this.onTapBooking,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.fromLTRB(16, 100, 16, 16),
      decoration: BoxDecoration(
        color: BColors.accent.withOpacity(0.01),
        borderRadius: const BorderRadius.only(
          bottomLeft: Radius.circular(40),
          bottomRight: Radius.circular(40),
        ),
        border: Border.all(color: BColors.accent.withOpacity(0.8)),
      ),
      child: Column(
        children: [
          Row(
            children: [
              Container(
                width: 70,
                height: 70,
                decoration: BoxDecoration(
                  shape: BoxShape.circle,
                  color: Colors.grey.shade200,
                  border: Border.all(color: Colors.white, width: 4),
                ),
                child: Icon(
                  Icons.person,
                  size: 34,
                  color: Colors.grey.shade600,
                ),
              ),
              const SizedBox(width: 7),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      doctorName,
                      style: TextStyle(
                        fontSize: 16,
                        fontWeight: FontWeight.w900,
                        color: Colors.black.withOpacity(0.78),
                      ),
                    ),
                    const SizedBox(height: 6),
                    Text(
                      doctorMajor,
                      style: TextStyle(
                        fontSize: 14,
                        fontWeight: FontWeight.w700,
                        color: Colors.black.withOpacity(0.55),
                      ),
                    ),
                  ],
                ),
              ),
              Row(
                children: [
                  _SmallStatCard(
                    icon: Icons.star_rounded,
                    iconBg: BColors.primary.withOpacity(0.75),
                    value: rating.toStringAsFixed(1),
                    label: "التقييم",
                  ),
                  const SizedBox(width: 12),
                  _SmallStatCard(
                    icon: Icons.workspace_premium,
                    iconBg: BColors.primary.withOpacity(0.35),
                    value: years.toString(),
                    label: "سنوات الخبرة",
                  ),
                ],
              ),
            ],
          ),
          const SizedBox(height: 14),
          Row(
            children: [
              Expanded(
                child: _SegmentBtn(
                  text: "المؤهلات",
                  selected: tabIndex == 0,
                  onTap: onTapQualifications,
                ),
              ),
              const SizedBox(width: 12),
              Expanded(
                child: _SegmentBtn(
                  text: "ابحث عن موعد",
                  selected: tabIndex == 1,
                  onTap: onTapBooking,
                ),
              ),
            ],
          ),
        ],
      ),
    );
  }
}

class _SmallStatCard extends StatelessWidget {
  final IconData icon;
  final Color iconBg;
  final String value;
  final String label;

  const _SmallStatCard({
    required this.icon,
    required this.iconBg,
    required this.value,
    required this.label,
  });

  @override
  Widget build(BuildContext context) {
    return Container(
      width: 64,
      height: 90,
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(9.52),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.08),
            blurRadius: 12,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Column(
        children: [
          Container(
            height: 34,
            width: 32,
            decoration: BoxDecoration(
              color: iconBg,
              borderRadius: const BorderRadius.only(
                bottomLeft: Radius.circular(10),
                bottomRight: Radius.circular(10),
              ),
            ),
            child: Icon(icon, color: Colors.white, size: 18),
          ),
          const SizedBox(height: 6),
          Text(
            value,
            style: TextStyle(
              fontSize: 13,
              fontWeight: FontWeight.w900,
              color: Colors.black.withOpacity(0.75),
            ),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            textAlign: TextAlign.center,
            style: TextStyle(
              fontSize: 10,
              fontWeight: FontWeight.w700,
              color: Colors.black.withOpacity(0.55),
            ),
          ),
        ],
      ),
    );
  }
}

class _SegmentBtn extends StatelessWidget {
  final String text;
  final bool selected;
  final VoidCallback onTap;

  const _SegmentBtn({
    required this.text,
    required this.selected,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(16),
      child: Container(
        height: 44,
        alignment: Alignment.center,
        decoration: BoxDecoration(
          color: Colors.white,
          borderRadius: BorderRadius.circular(14.67),
          border: Border.all(
            color: selected
                ? BColors.primary.withOpacity(0.35)
                : Colors.black.withOpacity(0.10),
          ),
          boxShadow: selected
              ? [
                  BoxShadow(
                    color: Colors.black.withOpacity(0.08),
                    blurRadius: 10,
                    offset: const Offset(0, 6),
                  ),
                ]
              : [],
        ),
        child: Text(
          text,
          style: TextStyle(
            fontSize: 18,
            fontWeight: FontWeight.w600,
            color: Colors.black.withOpacity(0.75),
          ),
        ),
      ),
    );
  }
}

class _QualificationsSection extends StatelessWidget {
  const _QualificationsSection();

  @override
  Widget build(BuildContext context) {
    // No dummy content here — backend will provide real qualifications later.
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(18),
      decoration: BoxDecoration(
        color: Colors.white,
        borderRadius: BorderRadius.circular(18),
        border: Border.all(color: Colors.black.withOpacity(0.06)),
        boxShadow: [
          BoxShadow(
            color: Colors.black.withOpacity(0.05),
            blurRadius: 14,
            offset: const Offset(0, 8),
          ),
        ],
      ),
      child: Text(
        "سيتم عرض المؤهلات هنا عند توفرها من الباكند.",
        style: TextStyle(
          fontSize: 14.5,
          height: 1.6,
          fontWeight: FontWeight.w600,
          color: Colors.black.withOpacity(0.60),
        ),
      ),
    );
  }
}
