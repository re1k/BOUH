import 'package:bouh/View/DoctorAppointment/upAppointments.dart';
import 'package:flutter/material.dart';
import 'package:flutter_localizations/flutter_localizations.dart';
import 'package:intl/date_symbol_data_local.dart';

import 'package:bouh/View/DoctorAppointment/available_schedule_screen.dart';

// import 'package:bouh/View/BookAppointment/BookAppointment.dart';
// import 'package:bouh/View/BookAppointment/DoctorDetails.dart';
// import 'package:bouh/View/HomePage/doctorHomePage.dart';

Future<void> main() async {
  WidgetsFlutterBinding.ensureInitialized();

  // ✅ هذا اللي يحل LocaleDataException مع TableCalendar (ar)
  await initializeDateFormatting('ar');

  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      debugShowCheckedModeBanner: false,

      // ✅ دعم التعريب
      locale: const Locale('ar'),
      supportedLocales: const [Locale('ar'), Locale('en')],
      localizationsDelegates: const [
        GlobalMaterialLocalizations.delegate,
        GlobalWidgetsLocalizations.delegate,
        GlobalCupertinoLocalizations.delegate,
      ],

      title: 'BOUH',
      theme: ThemeData(useMaterial3: true),

      home: const AppointmentsScreen(),
    );
  }
}
