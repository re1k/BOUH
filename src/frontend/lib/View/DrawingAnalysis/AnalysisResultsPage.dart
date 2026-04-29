import 'package:bouh/View/BookAppointment/DoctorDetails.dart';
import 'package:bouh/dto/doctorDto.dart';
import 'package:bouh/dto/doctorSummaryDto.dart';
import 'package:bouh/services/doctorsService.dart';
import 'package:bouh/widgets/loading_overlay.dart';
import 'package:firebase_storage/firebase_storage.dart';
import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/radius.dart';
import 'package:bouh/theme/base_themes/typography.dart';
import 'package:bouh/View/DrawingAnalysis/drawing_analysis_stepper.dart';

class AnalysisResultsPage extends StatelessWidget {
  //When true, hide the top stepper and show only the back button (when called in drawing history).
  final bool hideStepper;
  final String emotionalInterpretation;
  final List<String> doctorIds;

  const AnalysisResultsPage({
    super.key,
    this.hideStepper = false,
    required this.emotionalInterpretation,
    required this.doctorIds,
  });

  //Main build
  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: BColors.white,
        body: SafeArea(
          child: Column(
            children: [
              SizedBox(height: hideStepper ? 8 : 38),

              //When opened from DrawingHistoryPage: back arrow
              if (hideStepper)
                Align(
                  alignment: Alignment.centerRight,
                  child: Padding(
                    padding: const EdgeInsets.only(right: 32),
                    child: IconButton(
                      onPressed: () => Navigator.of(context).pop(),
                      icon: const Icon(
                        Icons.arrow_back_ios,
                        color: BColors.darkGrey,
                        size: 22,
                      ),
                    ),
                  ),
                ),
              if (!hideStepper) ...[
                const SizedBox(height: 16),
                const DrawingAnalysisStepper(currentStep: 2),
              ],

              const SizedBox(height: 32),

              //Main content (interpretations and doctors)
              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //Interpretations section
                      _buildInterpretationsSection(),
                      if (doctorIds.isNotEmpty &&
                          emotionalInterpretation.isNotEmpty) ...[
                        _buildDoctorsSection(context),
                        const SizedBox(height: 32),
                      ],
                    ],
                  ),
                ),
              ),

              //Close button (hidden when results are opened from drawingHistoryPage)
              if (!hideStepper) _buildCloseButton(context),

              const SizedBox(height: 18),
            ],
          ),
        ),
      ),
    );
  }

  Widget _buildInterpretationsSection() {
    final text = emotionalInterpretation.isNotEmpty
        ? emotionalInterpretation
        : 'لم نتمكن من تحليل الرسمة في الوقت الحالي، يرجى المحاولة مرة أخرى لاحقاً.';

    return Column(
      crossAxisAlignment: CrossAxisAlignment.stretch,
      children: [
        Align(
          alignment: Alignment.centerRight,
          child: Text(
            'تفسيرات الرسمة',
            style: BTypography.sectionTitle,
            textAlign: TextAlign.right,
          ),
        ),

        const SizedBox(height: 16),

        _buildInterpretationCard(text),
      ],
    );
  }

  //Builds a single interpretation card
  Widget _buildInterpretationCard(String content) {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.all(16),
      decoration: BoxDecoration(
        color: BColors.secondry,
        borderRadius: BorderRadius.circular(BRadius.cardLarge),
      ),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Container(
            width: 26,
            height: 26,
            decoration: const BoxDecoration(
              shape: BoxShape.circle,
              color: BColors.accent,
            ),
            child: const Icon(Icons.lightbulb, color: BColors.white, size: 20),
          ),

          const SizedBox(width: 10),

          //Interpretation text
          Expanded(
            child: Text(
              content,
              style: BTypography.bodyText.copyWith(height: 1.3),
              textAlign: TextAlign.right,
            ),
          ),
        ],
      ),
    );
  }

  //helper
  Future<String?> _resolveImageUrl(String? rawUrl) async {
    if (rawUrl == null || rawUrl.isEmpty) return null;
    if (rawUrl.startsWith('http')) return rawUrl;
    try {
      return await FirebaseStorage.instance.ref(rawUrl).getDownloadURL();
    } catch (e) {
      return null;
    }
  }

  //Builds the recommended doctors section.
  Widget _buildDoctorsSection(BuildContext context) {
    return FutureBuilder<List<DoctorDto>>(
      future: Future.wait(
        doctorIds.map((id) async {
          final doctor = await DoctorsService.getDoctorDetails(id);
          doctor.profilePhotoURL = await _resolveImageUrl(
            doctor.profilePhotoURL,
          );
          return doctor;
        }),
      ),
      builder: (context, snapshot) {
        if (snapshot.connectionState == ConnectionState.waiting) {
          return const Center(child: BouhOvalLoadingIndicator());
        }
        if (!snapshot.hasData || snapshot.data!.isEmpty) {
          return const SizedBox();
        }
        return Column(
          crossAxisAlignment: CrossAxisAlignment.stretch,
          children: [
            Text('الأطباء المقترحين', style: BTypography.sectionTitle),
            const SizedBox(height: 16),
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: [
                  for (final d in snapshot.data!) ...[
                    _buildDoctorCard(
                      context,
                      d.name,
                      imageUrl: d.profilePhotoURL,
                      doctorId: d.doctorId,
                    ),
                    const SizedBox(width: 12),
                  ],
                ],
              ),
            ),
          ],
        );
      },
    );
  }

  Widget _buildDoctorCard(
    BuildContext context,
    String name, {
    String? imageUrl,
    required String doctorId,
  }) {
    return GestureDetector(
      onTap: () async {
        try {
          // Fetch full doctor details using the ID we already have
          final DoctorDto fullDoctor = await DoctorsService.getDoctorDetails(
            doctorId,
          );

          // Map DoctorDto → DoctorSummaryDto which DoctorDetailsView expects
          final DoctorSummaryDto summary = DoctorSummaryDto(
            doctorId: fullDoctor.doctorId,
            name: fullDoctor.name,
            areaOfKnowledge: fullDoctor.areaOfKnowledge,
            rating: fullDoctor.averageRating ?? 0.0,
          );

          if (!context.mounted) return;

          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => DoctorDetailsView(doctor: summary),
            ),
          );
        } catch (e) {
          if (!context.mounted) return;
          ScaffoldMessenger.of(context).showSnackBar(
            const SnackBar(
              content: Text(
                'تعذر تحميل بيانات الطبيب، يرجى المحاولة مرة أخرى',
                textDirection: TextDirection.rtl,
              ),
            ),
          );
        }
      },
      child: Container(
        padding: const EdgeInsets.symmetric(horizontal: 8, vertical: 12),
        decoration: BoxDecoration(
          color: BColors.secondry,
          borderRadius: BorderRadius.circular(BRadius.cardLarge),
        ),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            //Doctor image: network image if [imageUrl] provided, else placeholder icon
            Container(
              width: 70,
              height: 75,
              decoration: BoxDecoration(
                shape: BoxShape.circle,
                color: imageUrl == null ? BColors.softGrey : null,
                image: imageUrl != null
                    ? DecorationImage(
                        image: NetworkImage(imageUrl),
                        fit: BoxFit.cover,
                      )
                    : null,
                border: Border.all(color: BColors.primary, width: 3),
              ),
              child: imageUrl == null
                  ? const Icon(Icons.person, size: 40, color: BColors.darkGrey)
                  : null,
            ),
            const SizedBox(height: 16),

            //Doctor name with overflow handling
            SizedBox(
              width: 100,
              child: Text(
                name,
                style: BTypography.labelText.copyWith(
                  color: BColors.textDarkestBlue,
                  fontWeight: FontWeight.w600,
                ),
                textAlign: TextAlign.center,
                maxLines: 2,
                overflow: TextOverflow.ellipsis,
              ),
            ),
          ],
        ),
      ),
    );
  }

  //Builds the close button at the bottom
  Widget _buildCloseButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 88),
      child: SizedBox(
        width: double.infinity,
        child: ElevatedButton(
          onPressed: () {
            Navigator.of(context).pop(); // pop AnalysisResultsPage
            Navigator.of(context).pop(); // pop UploadDrawingPage
          },
          style: ElevatedButton.styleFrom(
            backgroundColor: BColors.accent,
            padding: const EdgeInsets.symmetric(vertical: 10),
            shape: RoundedRectangleBorder(
              borderRadius: BRadius.buttonLargeRadius,
            ),
            elevation: 0,
          ),
          child: Text('اغلاق', style: BTypography.buttonText),
        ),
      ),
    );
  }
}
