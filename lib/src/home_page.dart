import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_background.dart';

class HomePage extends StatelessWidget {
  const HomePage({super.key});

  Future<void> _logout(BuildContext context) async {
    await Supabase.instance.client.auth.signOut();
    if (!context.mounted) return;
    Navigator.pushNamedAndRemoveUntil(context, '/login', (_) => false);
  }

  bool _isAdmin() {
    final session = Supabase.instance.client.auth.currentSession;
    final hasura = session?.user.appMetadata['hasura'];

    // app_metadata.hasura poate fi Map sau null
    if (hasura is Map) {
      final role = hasura['x-hasura-default-role']?.toString();
      return role == 'admin';
    }
    return false;
  }

  @override
  Widget build(BuildContext context) {
    final isAdmin = _isAdmin();

    return Scaffold(
      appBar: AppBar(
        title: const Text("Dino FC"),
        actions: [
          IconButton(
            icon: const Icon(Icons.logout),
            onPressed: () => _logout(context),
          ),
        ],
      ),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(18),
                child: Column(
                  mainAxisSize: MainAxisSize.min,
                  children: [
                    const Text(
                      "Bine ai venit la Dino FC!",
                      style: TextStyle(fontSize: 22, fontWeight: FontWeight.w700),
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 10),
                    const Text(
                      "În curând: profil, echipă, antrenamente, statistici ⚽",
                      textAlign: TextAlign.center,
                    ),
                    const SizedBox(height: 18),
                    const Divider(),
                    const SizedBox(height: 14),

                    if (isAdmin)
                      ElevatedButton.icon(
                        onPressed: () {
                          Navigator.pushNamed(context, '/matchday/new');
                        },
                        icon: const Icon(Icons.add),
                        label: const Text("New matchday"),
                      )
                    else
                      const Text(
                        "Nu ai acces de admin pentru a crea o etapă.",
                        textAlign: TextAlign.center,
                      ),
                  ],
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
