import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class SignUpPage extends StatefulWidget {
  static const routeName = '/signup';
  const SignUpPage({super.key});

  @override
  State<SignUpPage> createState() => _SignUpPageState();
}

class _SignUpPageState extends State<SignUpPage> {
  final _emailCtrl = TextEditingController();
  final _passCtrl = TextEditingController();
  bool _loading = false;
  String? _error;
  String? _info;

  Future<void> _signUp() async {
    setState(() {
      _loading = true;
      _error = null;
      _info = null;
    });

    try {
      final email = _emailCtrl.text.trim();
      final password = _passCtrl.text;

      if (email.isEmpty || password.length < 6) {
        throw 'Email invalid sau parolă prea scurtă (min. 6 caractere).';
      }

      final res = await Supabase.instance.client.auth.signUp(
        email: email,
        password: password,
        // optional: data suplimentară la user metadata
        // data: {'role': 'player'},
        // emailRedirectTo: 'https://<domain-ul-tau>/auth/callback', // dacă folosești confirmare email
      );

      if (res.user == null) {
        throw 'Crearea contului a eșuat.';
      }

      // Dacă proiectul tău are "Email confirmations" ON, user-ul trebuie să-și confirme emailul.
      setState(() {
        _info = 'Cont creat. Verifică emailul pentru confirmare (dacă este activată).';
      });
    } catch (e) {
      setState(() => _error = e.toString());
    } finally {
      setState(() => _loading = false);
    }
  }

  @override
  void dispose() {
    _emailCtrl.dispose();
    _passCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    final canSubmit = !_loading;

    return Scaffold(
      appBar: AppBar(title: const Text('Creează cont')),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 420),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextField(
                  controller: _emailCtrl,
                  keyboardType: TextInputType.emailAddress,
                  decoration: const InputDecoration(
                    labelText: 'Email',
                    prefixIcon: Icon(Icons.email),
                  ),
                ),
                const SizedBox(height: 12),
                TextField(
                  controller: _passCtrl,
                  obscureText: true,
                  decoration: const InputDecoration(
                    labelText: 'Parolă',
                    prefixIcon: Icon(Icons.lock),
                  ),
                ),
                const SizedBox(height: 12),
                if (_error != null)
                  Text(_error!, style: const TextStyle(color: Colors.red)),
                if (_info != null)
                  Text(_info!, style: const TextStyle(color: Colors.green)),
                const SizedBox(height: 12),
                SizedBox(
                  width: double.infinity,
                  child: FilledButton(
                    onPressed: canSubmit ? _signUp : null,
                    child: _loading
                        ? const SizedBox(
                            width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Colors.white))
                        : const Text('Creează cont'),
                  ),
                ),
              ],
            ),
          ),
        ),
      ),
    );
  }
}