import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'core/app_colors.dart';
import 'screens/splash_page.dart';

void main() => runApp(const QnexApp());

class QnexApp extends StatelessWidget {
  const QnexApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Q-NEX',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        useMaterial3: true,
        colorScheme: ColorScheme.fromSeed(seedColor: AppColors.orange),
        textTheme: GoogleFonts.montserratTextTheme(),
        scaffoldBackgroundColor: Colors.white,
      ),
      home: const SplashPage(),
    );
  }
}
