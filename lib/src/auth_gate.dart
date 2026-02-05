import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'login_page.dart';
import 'home_page.dart';

class AuthGate extends StatefulWidget {
  const AuthGate({super.key});

  @override
  State<AuthGate> createState() => _AuthGateState();
}

class _AuthGateState extends State<AuthGate> {
  Session? _session;
  late final Stream<Session?> _authStream;

  @override
  void initState() {
    super.initState();

    _session = Supabase.instance.client.auth.currentSession;
    _authStream = Supabase.instance.client.auth.onAuthStateChange.map(
      (data) => data.session,
    );

    _authStream.listen((session) {
      setState(() {
        _session = session;
      });
    });
  }

  @override
  Widget build(BuildContext context) {
    // Dacă userul e logat → mergem la HomePage
    // Dacă nu → mergem la LoginPage
    return _session != null ? HomePage() : LoginPage();
  }
}