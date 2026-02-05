import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'src/auth_gate.dart';
import 'src/login_page.dart';
import 'src/signup_page.dart';
import 'src/home_page.dart';

void main() async {
  WidgetsFlutterBinding.ensureInitialized();

  await Supabase.initialize(
    url: 'https://vypxxtbxxakkkglyveoh.supabase.co/',
    anonKey: 'eyJhbGciOiJIUzI1NiIsInR5cCI6IkpXVCJ9.eyJpc3MiOiJzdXBhYmFzZSIsInJlZiI6InZ5cHh4dGJ4eGFra2tnbHl2ZW9oIiwicm9sZSI6ImFub24iLCJpYXQiOjE3NjkzMDIyMTEsImV4cCI6MjA4NDg3ODIxMX0.Ar2cDWvD4PgD0R8VsUMncsW1RpYyHCsfPf1CjFtreVM',
  );

  runApp(const DinoApp());
}

class DinoApp extends StatelessWidget {
  const DinoApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'Dino FC',
      debugShowCheckedModeBanner: false,

      routes: {
        '/login': (_) => LoginPage(),
        '/signup': (_) => SignUpPage(),
        '/home': (_) => HomePage(),
      },

      home: const AuthGate(),
    );
  }
}