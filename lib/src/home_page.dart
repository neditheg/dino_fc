import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class HomePage extends StatelessWidget {
  static const routeName = '/home';
  const HomePage({super.key});

  @override
  Widget build(BuildContext context) {
    final user = Supabase.instance.client.auth.currentUser;

    return Scaffold(
      appBar: AppBar(
        title: const Text('Dino FC — Home'),
        actions: [
          IconButton(
            tooltip: 'Logout',
            icon: const Icon(Icons.logout),
            onPressed: () async {
              await Supabase.instance.client.auth.signOut();
              // AuthGate te va trimite automat la Login
            },
          ),
        ],
      ),
      body: Center(
        child: user == null
            ? const Text('Niciun utilizator logat.')
            : Column(
                mainAxisSize: MainAxisSize.min,
                children: [
                  const Text('Ești autentificat ca:'),
                  const SizedBox(height: 8),
                  Text(
                    user.email ?? '(fără email)',
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                ],
              ),
      ),
    );
  }
}
