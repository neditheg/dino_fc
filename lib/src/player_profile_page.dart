import 'package:flutter/material.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

import 'app_background.dart';

class PlayerProfilePage extends StatefulWidget {
  final String email;
  final String password;

  const PlayerProfilePage({
    super.key,
    required this.email,
    required this.password,
  });

  @override
  State<PlayerProfilePage> createState() => _PlayerProfilePageState();
}

class _PlayerProfilePageState extends State<PlayerProfilePage> {
  final nameCtrl = TextEditingController();
  final nicknameCtrl = TextEditingController();
  final phoneCtrl = TextEditingController();
  final numberCtrl = TextEditingController();

  // NEW: birth date
  final birthDateCtrl = TextEditingController();
  DateTime? birthDate;

  String position = "MID";
  bool loading = false;
  String? error;

  String _yyyyMmDd(DateTime d) =>
      '${d.year.toString().padLeft(4, '0')}-'
      '${d.month.toString().padLeft(2, '0')}-'
      '${d.day.toString().padLeft(2, '0')}';

  Future<void> _pickBirthDate() async {
    FocusScope.of(context).unfocus();
    final now = DateTime.now();

    final picked = await showDatePicker(
      context: context,
      initialDate: birthDate ?? DateTime(now.year - 25, 1, 1),
      firstDate: DateTime(1950, 1, 1),
      lastDate: now,
    );

    if (picked != null) {
      setState(() {
        birthDate = picked;
        birthDateCtrl.text = _yyyyMmDd(picked);
      });
    }
  }

  Future<void> _finishRegistration() async {
    // Validări minime
    if (nameCtrl.text.trim().isEmpty) {
      setState(() => error = "Completează numele complet.");
      return;
    }
    if (birthDate == null) {
      setState(() => error = "Selectează data nașterii.");
      return;
    }

    setState(() {
      loading = true;
      error = null;
    });

    try {
      final supabase = Supabase.instance.client;

      // 1) Creăm userul în Supabase Auth
      final authRes = await supabase.auth.signUp(
        email: widget.email,
        password: widget.password,
      );

      final user = authRes.user;
      if (user == null) {
        throw "Nu s-a putut crea contul.";
      }

      // join_date = azi (YYYY-MM-DD)
      final joinDate = _yyyyMmDd(DateTime.now());

      // 2) Inserăm jucătorul în tabela players
      final playerRes = await supabase
          .from('players')
          .insert({
            'club_id': 1,
            'name': nameCtrl.text.trim(),
            'nickname': nicknameCtrl.text.trim(),
            'position': position,
            'back_number': int.tryParse(numberCtrl.text.trim()),
            'email': widget.email,
            'phone': phoneCtrl.text.trim(),

            // NEW:
            'birth_date': birthDateCtrl.text, // YYYY-MM-DD
            'join_date': joinDate,            // YYYY-MM-DD
          })
          .select()
          .single();

      final playerId = playerRes['id'];

      // 3) Legăm userul de jucător
      await supabase.from('player_accounts').insert({
        'player_id': playerId,
        'user_id': user.id,
      });

      // 4) Adăugăm userul în club
      await supabase.from('club_members').insert({
        'club_id': 1,
        'user_id': user.id,
        'role': 'member',
      });

      if (!mounted) return;
      Navigator.of(context).pushReplacementNamed('/home');
    } catch (e) {
      setState(() => error = e.toString());
    } finally {
      if (mounted) setState(() => loading = false);
    }
  }

  @override
  void dispose() {
    nameCtrl.dispose();
    nicknameCtrl.dispose();
    phoneCtrl.dispose();
    numberCtrl.dispose();
    birthDateCtrl.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text("Profil jucător")),
      body: AppBackground(
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 520),
            child: Card(
              elevation: 10,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: SingleChildScrollView(
                  child: Column(
                    mainAxisSize: MainAxisSize.min,
                    children: [
                      TextField(
                        controller: nameCtrl,
                        decoration:
                            AppInputStyle.inputDecoration("Nume complet", Icons.person),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: nicknameCtrl,
                        decoration:
                            AppInputStyle.inputDecoration("Poreclă", Icons.tag),
                      ),
                      const SizedBox(height: 12),
                      DropdownButtonFormField<String>(
                        value: position,
                        items: ["GK", "DEF", "MID", "FWD"]
                            .map((p) => DropdownMenuItem(value: p, child: Text(p)))
                            .toList(),
                        onChanged: (v) => setState(() => position = v ?? "MID"),
                        decoration:
                            AppInputStyle.inputDecoration("Poziție", Icons.sports_soccer),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: numberCtrl,
                        keyboardType: TextInputType.number,
                        decoration:
                            AppInputStyle.inputDecoration("Număr tricou", Icons.confirmation_number),
                      ),
                      const SizedBox(height: 12),
                      TextField(
                        controller: phoneCtrl,
                        keyboardType: TextInputType.phone,
                        decoration:
                            AppInputStyle.inputDecoration("Telefon", Icons.phone),
                      ),
                      const SizedBox(height: 12),

                      // NEW: Birth date
                      TextField(
                        controller: birthDateCtrl,
                        readOnly: true,
                        decoration: AppInputStyle.inputDecoration(
                          "Data nașterii",
                          Icons.cake,
                        ),
                        onTap: _pickBirthDate,
                      ),

                      const SizedBox(height: 16),
                      if (error != null)
                        Text(error!, style: const TextStyle(color: Colors.red)),
                      const SizedBox(height: 16),

                      SizedBox(
                        width: double.infinity,
                        child: FilledButton(
                          onPressed: loading ? null : _finishRegistration,
                          child: loading
                              ? const SizedBox(
                                  width: 20,
                                  height: 20,
                                  child: CircularProgressIndicator(
                                    strokeWidth: 2,
                                    color: Colors.white,
                                  ),
                                )
                              : const Text("Finalizează înregistrarea"),
                        ),
                      ),
                    ],
                  ),
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}

/// Mic helper ca să păstrăm input-urile consistente (optional, dar arată mai bine)
class AppInputStyle {
  static InputDecoration inputDecoration(String label, IconData icon) {
    return InputDecoration(
      labelText: label,
      prefixIcon: Icon(icon),
    );
  }
}
