import 'dart:io';
import 'package:bouh/View/DrawingAnalysis/ProcessingAnalysisPage.dart';
import 'package:bouh/View/DrawingAnalysis/drawing_analysis_stepper.dart';
import 'package:flutter/material.dart';
import 'package:image_picker/image_picker.dart';
import 'package:bouh/theme/base_themes/colors.dart';
import 'package:bouh/theme/base_themes/radius.dart';
import 'package:bouh/theme/base_themes/typography.dart';
import 'package:permission_handler/permission_handler.dart';
//UPLOAD DRAWING PAGE (Step 1 of 3)
//Permissions: image_picker asks for camera/photo access when the user picks an image.
//BACKEND PHASE:
//we have: _selectedImageFile (image File) and widget.selectedChildName (String).
//Option A: Upload image here when user taps "التالي", then go to step 2 with an imageId or imageUrl instead of (or in addition to) imagePath.
//Option B: Keep passing imagePath + selectedChildName to ProcessingAnalysisPage;
//do the upload and analysis call in step 2 (see comments there).

class UploadDrawingPage extends StatefulWidget {
  //Child name chosen on the previous screen Passed along for future BACKEND.
  final String childId;
  final String childName;
  const UploadDrawingPage({
    super.key,
    required this.childId,
    required this.childName,
  });

  @override
  State<UploadDrawingPage> createState() => _UploadDrawingPageState();
}

class _UploadDrawingPageState extends State<UploadDrawingPage> {
  File?
  _selectedImageFile; //The image file the user selected from (gallery or camera). Null until they pick one.
  final ImagePicker _picker =
      ImagePicker(); //image_picker: opens native Android gallery/camera. It requests permissions when needed.

  @override
  void initState() {
    super.initState();
    _requestPermissions();
  }

  Future<void> _requestPermissions() async {
    await Permission.camera.request();
    await Permission.photos.request();
    await Permission.storage.request();
    await Permission.mediaLibrary.request();
  }

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
              const SizedBox(height: 6),

              _buildBackButton(context),

              //Stepper: step 0 = (Upload Drawing) is active
              const DrawingAnalysisStepper(currentStep: 0),

              const SizedBox(height: 48),

              Expanded(
                child: SingleChildScrollView(
                  padding: const EdgeInsets.symmetric(horizontal: 24),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.stretch,
                    children: [
                      //Title
                      Text(
                        'قم بإرفاق رسمه الطفل',
                        style: BTypography.sectionTitle,
                        textAlign: TextAlign.center,
                      ),

                      const SizedBox(height: 24),

                      //bottom sheet options
                      _buildUploadArea(context),

                      const SizedBox(height: 52),

                      _buildNextButton(context),
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

  //Back arrow (Upload Drawing). Pop goes back to ReqeustAnalysis page.
  Widget _buildBackButton(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.symmetric(horizontal: 32),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.start,
        children: [
          IconButton(
            onPressed: () => Navigator.of(context).pop(),
            icon: const Icon(
              Icons.arrow_back_ios,
              color: BColors.darkGrey,
              size: 22,
            ),
          ),
        ],
      ),
    );
  }

  //The upload rectangle. One tap shows bottom sheet: camera or gallery.
  Widget _buildUploadArea(BuildContext context) {
    return GestureDetector(
      onTap: () => _showImageSourceSheet(context), //bottom sheet options
      child: Container(
        width: double.infinity,
        height: 300,
        decoration: BoxDecoration(
          color: BColors.lightGrey,
          borderRadius: BorderRadius.circular(BRadius.cardLarge),
          border: Border.all(
            color: BColors.grey,
            width: 1.5,
            strokeAlign: BorderSide.strokeAlignOutside,
          ),
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(BRadius.cardLarge),
          child: _selectedImageFile != null
              ? Stack(
                  fit: StackFit.expand,
                  children: [
                    //taken Image showing inside the rectangle
                    Image.file(_selectedImageFile!, fit: BoxFit.cover),

                    //Overlay so user knows they can tap to change image
                    Positioned(
                      bottom: 0,
                      left: 0,
                      right: 0,
                      child: Material(
                        color: BColors.darkGrey,
                        child: InkWell(
                          onTap: () => _showImageSourceSheet(context),
                          child: Padding(
                            padding: const EdgeInsets.symmetric(vertical: 10),
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                Icon(
                                  Icons.edit,
                                  color: BColors.white,
                                  size: 20,
                                ),

                                const SizedBox(width: 8),

                                Text(
                                  'تغيير الصورة',
                                  style: BTypography.labelText.copyWith(
                                    color: BColors.white,
                                    fontWeight: FontWeight.w600,
                                  ),
                                  textDirection: TextDirection.rtl,
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ],
                )
              : _buildPlaceholderContent(),
        ),
      ),
    );
  }

  //Content shown inside the rectangle when no image is selected (icon + text)
  Widget _buildPlaceholderContent() {
    return Center(
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(Icons.upload_file_rounded, size: 52, color: BColors.primary),

          const SizedBox(height: 12),

          Padding(
            padding: const EdgeInsets.symmetric(horizontal: 24),
            child: Text(
              'يرجى تحميل الرسمة التي ترغب في تحليلها، مع التأكد من التقاطها بشكل واضح ودقيق',
              style: BTypography.bodyText.copyWith(color: BColors.darkGrey),
              textAlign: TextAlign.center,
            ),
          ),
        ],
      ),
    );
  }

  //Shows bottom sheet with options (camera or gallery)
  void _showImageSourceSheet(BuildContext context) {
    showModalBottomSheet<void>(
      context: context,
      backgroundColor: Colors.transparent,
      builder: (ctx) => Container(
        decoration: BoxDecoration(
          color: BColors.white,
          borderRadius: const BorderRadius.vertical(top: Radius.circular(20)),
        ),
        child: SafeArea(
          child: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              _sheetOption(
                ctx,
                label: 'تحميل من ألبوم الصور',
                icon: Icons.photo_album,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.gallery);
                },
              ),
              Divider(height: 1, color: BColors.grey),
              _sheetOption(
                ctx,
                label: 'التقاط صورة',
                icon: Icons.camera_alt,
                onTap: () {
                  Navigator.pop(ctx);
                  _pickImage(ImageSource.camera);
                },
              ),
            ],
          ),
        ),
      ),
    );
  }

  //builds each option in the bottom sheet
  Widget _sheetOption(
    BuildContext context, {
    required String label,
    required IconData icon,
    required VoidCallback onTap,
  }) {
    return ListTile(
      contentPadding: const EdgeInsets.symmetric(horizontal: 24, vertical: 12),
      trailing: Icon(icon, color: BColors.primary),
      title: Text(
        label,
        style: BTypography.bodyText,
        textAlign: TextAlign.right,
      ),
      onTap: onTap,
    );
  }

  //Picks image from [source] (camera or gallery). image_picker handles permissions.
  Future<void> _pickImage(ImageSource source) async {
    try {
      //Open native picker; returns null if user cancels
      final XFile? xFile = await _picker.pickImage(
        source: source,
        maxWidth: 1920, //Resize to avoid huge files
        maxHeight: 1920,
        imageQuality: 85,
      );
      //Only update state if we got a file and the widget is still on screen
      if (xFile != null && mounted) {
        setState(() {
          _selectedImageFile = File(xFile.path);
        });
      }
    } catch (e) {
      //Permission denied or picker error: show error message
      if (mounted) {
        ScaffoldMessenger.of(context).showSnackBar(
          SnackBar(
            content: Text(
              'لم نتمكن من فتح الصورة. تأكد من منح الصلاحيات (الكاميرا أو الألبوم).',
              textDirection: TextDirection.rtl,
            ),
            backgroundColor: const Color.fromARGB(255, 146, 47, 29),
          ),
        );
      }
    }
  }

  //Next button. Pushes to ProcessingAnalysisPage (step 2).
  Widget _buildNextButton(BuildContext context) {
    final isEnabled = _selectedImageFile != null;

    return SizedBox(
      width: double.infinity,
      child: ElevatedButton(
        onPressed: isEnabled
            ? () {
                //Go to step 2: loading
                //BACKEND: pass imagePath and selectedChildName; step 2 will use these
                //to call API (upload image, then get analysis). See ProcessingAnalysisPage.
                Navigator.of(context).push(
                  MaterialPageRoute<void>(
                    builder: (context) => ProcessingAnalysisPage(
                      imageFile: _selectedImageFile!,
                      childId: widget.childId,
                      childName: widget.childName,
                    ),
                  ),
                );
              }
            : null,
        style: ElevatedButton.styleFrom(
          backgroundColor: isEnabled ? BColors.accent : BColors.grey,
          disabledBackgroundColor: BColors.grey,
          padding: const EdgeInsets.symmetric(vertical: 10),
          shape: RoundedRectangleBorder(
            borderRadius: BRadius.buttonLargeRadius,
          ),
          elevation: 0,
        ),
        child: Text('التالي', style: BTypography.buttonText),
      ),
    );
  }
}
