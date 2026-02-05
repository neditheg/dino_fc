import 'dart:async'; // ✅ necesar pentru StreamSubscription
import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'home_page.dart';
import 'login_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  late final SupabaseClient _client;
  StreamSubscription<AuthState>? _authSub; // ✅ tip corect v2
  Session? _session;
  bool _loading = true;

  @override
  void initState() {
    super.initState();
    _client = Supabase.instance.client;

    // sesiunea curentă dacă user-ul a mai fost autentificat
    _session = _client.auth.currentSession;

    // ascultă evenimentele de autentificare (login, logout etc.)
    _authSub = _client.auth.onAuthStateChange.listen((AuthState data) {
      final event = data.event;
      final session = data.session;

      setState(() => _session = session);

      if (!mounted) return;

      if (event == AuthChangeEvent.signedIn) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const HomePage()),
          (_) => false,
        );
      } else if (event == AuthChangeEvent.signedOut) {
        Navigator.of(context).pushAndRemoveUntil(
          MaterialPageRoute(builder: (_) => const LoginPage()),
          (_) => false,
        );
      }
    });

    // mic splash
    Future.microtask(() {
      if (mounted) setState(() => _loading = false);
    });
  }

  @override
  void dispose() {
    _authSub?.cancel(); // ✅ anulăm stream-ul
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    if (_loading) {
      return const Scaffold(
        body: Center(child: CircularProgressIndicator()),
      );
    }

    // dacă avem sesiune, mergem la Home, altfel la Login
    return _session != null ? const HomePage() : const LoginPage();
  }
}