import 'package:flutter/material.dart';
import 'package:bouh/theme/base_themes/colors.dart';

/// About / contact screens from profile settings (card + footer layout).
class ProfileStaticInfoPage extends StatelessWidget {
  const ProfileStaticInfoPage({
    super.key,
    required this.title,
    required this.paragraphs,
  });

  final String title;
  final List<String> paragraphs;

  static const TextStyle _pageTitleStyle = TextStyle(
    fontSize: 22,
    fontWeight: FontWeight.w800,
    color: BColors.textDarkestBlue,
  );

  static const TextStyle _cardBodyStyle = TextStyle(
    fontSize: 16,
    height: 1.5,
    fontWeight: FontWeight.w400,
    color: BColors.textDarkestBlue,
  );

  static const TextStyle _footerStyle = TextStyle(
    fontSize: 14,
    height: 1.45,
    fontWeight: FontWeight.w400,
    color: BColors.darkerGrey,
  );

  static String _copyrightLine() {
    final year = DateTime.now().year;
    return 'جميع الحقوق محفوظة لفريق بَـوْح $year';
  }

  static const List<String> _aboutParagraphs = [
    'بَـوْح تطبيق يعتمد على الذكاء الاصطناعي لتحليل رسومات الأطفال واكتشاف حالاتهم العاطفية، '
        'لتقديم إرشادات ورؤى لمقدمي الرعاية وربطهم عند الحاجة بأطباء نفسيين مرخّصين.',
    'يساعد الأطفال على التعبير عن مشاعرهم عبر الرسم عندما يصعب عليهم وصفها بالكلمات، '
        'ويدعم متابعة الأنماط العاطفية بمرور الوقت.',
  ];

  static const List<String> _contactParagraphs = [
    'نرحب باستفساراتكم وملاحظاتكم حول تطبيق بَـوْح.',
    'للدعم الفني أو الاستفسارات العامة، يرجى التواصل معنا عبر البريد الإلكتروني:',
    'bouh1447@gmail.com',
  ];

  static void openAbout(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileStaticInfoPage(
          title: 'من نحن',
          paragraphs: _aboutParagraphs,
        ),
      ),
    );
  }

  static void openContact(BuildContext context) {
    Navigator.of(context).push(
      MaterialPageRoute(
        builder: (_) => const ProfileStaticInfoPage(
          title: 'تواصل معنا',
          paragraphs: _contactParagraphs,
        ),
      ),
    );
  }

  Widget _infoCard() {
    return Container(
      width: double.infinity,
      padding: const EdgeInsets.symmetric(horizontal: 16, vertical: 20),
      decoration: BoxDecoration(
        color: BColors.secondary,
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          for (var i = 0; i < paragraphs.length; i++) ...[
            if (i > 0) const SizedBox(height: 14),
            Text(
              paragraphs[i],
              textAlign: TextAlign.center,
              style: _cardBodyStyle,
            ),
          ],
        ],
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Directionality(
      textDirection: TextDirection.rtl,
      child: Scaffold(
        backgroundColor: Colors.white,
        appBar: AppBar(
          backgroundColor: Colors.white,
          elevation: 0,
          scrolledUnderElevation: 0,
          surfaceTintColor: Colors.transparent,
          foregroundColor: BColors.textDarkestBlue,
          centerTitle: true,
          leading: IconButton(
            icon: const Icon(
              Icons.arrow_back_ios_new_rounded,
              size: 20,
              color: BColors.textDarkestBlue,
            ),
            onPressed: () => Navigator.of(context).pop(),
          ),
          title: Text(title, style: _pageTitleStyle),
        ),
        body: SafeArea(
          top: false,
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Expanded(
                child: LayoutBuilder(
                  builder: (context, constraints) {
                    return SingleChildScrollView(
                      physics: const AlwaysScrollableScrollPhysics(),
                      padding: const EdgeInsets.symmetric(horizontal: 18),
                      child: ConstrainedBox(
                        constraints: BoxConstraints(
                          minHeight: constraints.maxHeight,
                        ),
                        child: Center(child: _infoCard()),
                      ),
                    );
                  },
                ),
              ),
              Padding(
                padding: const EdgeInsets.fromLTRB(18, 8, 18, 0),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    Image.asset(
                      'assets/images/bouh_logo_transparent.png',
                      width: 168,
                      fit: BoxFit.contain,
                      filterQuality: FilterQuality.high,
                    ),
                    const SizedBox(height: 12),
                    Text(
                      _copyrightLine(),
                      textAlign: TextAlign.center,
                      style: _footerStyle,
                    ),
                  ],
                ),
              ),
              const SizedBox(height: 20),
            ],
          ),
        ),
      ),
    );
  }
}
