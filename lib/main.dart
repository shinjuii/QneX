import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:supabase_flutter/supabase_flutter.dart';
import 'core/app_colors.dart';
import 'screens/splash_page.dart';

Future<void> main() async {
  // 1. Wajib ada agar binding Flutter siap sebelum inisialisasi async
  WidgetsFlutterBinding.ensureInitialized();

  // 2. Inisialisasi Supabase dengan Project ID QNEX kamu
  await Supabase.initialize(
    url: 'https://wapcrofwkmaqwpylkote.supabase.co',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6IndhcGNyb2Z3a21hcXdweWxrb3RlIiwicm9sZSI6ImFub24iLCJpYXQiOjE3OTI3MzQ3NTgsImV4cCI6MjEwODMxMDc1OH0.4z5Z9-74B0oe1XuPBQJ9hRi4TLSltqvGxLrJ5Udk_Rg',
  );

  runApp(const QnexApp());
}

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