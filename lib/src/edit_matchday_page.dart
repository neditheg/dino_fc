import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class EditMatchdayPage extends StatefulWidget {
  final Map<String, dynamic> matchday;

  const EditMatchdayPage({
    super.key,
    required this.matchday,
  });

  @override
  State<EditMatchdayPage> createState() => _EditMatchdayPageState();
}

class _EditMatchdayPageState extends State<EditMatchdayPage> {
  final _formKey = GlobalKey<FormState>();

  late String _soccerField;
  late int _maxPlayers;
  late bool _isPrivate;
  late DateTime _date;
  late TimeOfDay _start;
  late TimeOfDay _end;

  late TextEditingController _roundCtrl;
  final _notesCtrl = TextEditingController();

  @override
  void initState() {
    super.initState();
    _initializeFromMatchday();
  }

  void _initializeFromMatchday() {
    final m = widget.matchday;

    // Parse date
    _date = DateTime.parse(m['match_date'] as String);

    // Parse times (default if not available)
    _start = const TimeOfDay(hour: 20, minute: 0);
    _end = const TimeOfDay(hour: 21, minute: 30);

    _soccerField = 'Nastase&Marica Sports Club - București';
    _maxPlayers = m['max_players'] as int? ?? 18;
    _isPrivate = true;

    _roundCtrl = TextEditingController(text: (m['round_no'] ?? 1).toString());
    _notesCtrl.text = m['notes'] as String? ?? '';
  }

  @override
  void dispose() {
    _roundCtrl.dispose();
    _notesCtrl.dispose();
    super.dispose();
  }

  Future<void> _pickDate() async {
    final picked = await showDatePicker(
      context: context,
      initialDate: _date,
      firstDate: DateTime(2020),
      lastDate: DateTime(2100),
    );
    if (picked != null) setState(() => _date = picked);
  }

  Future<void> _pickTimeStart() async {
    final picked = await showTimePicker(context: context, initialTime: _start);
    if (picked != null) setState(() => _start = picked);
  }

  Future<void> _pickTimeEnd() async {
    final picked = await showTimePicker(context: context, initialTime: _end);
    if (picked != null) setState(() => _end = picked);
  }

  @override
  Widget build(BuildContext context) {
    final dateStr =
        "${_date.year}-${_date.month.toString().padLeft(2, '0')}-${_date.day.toString().padLeft(2, '0')}";
    final startStr =
        "${_start.hour.toString().padLeft(2, '0')}:${_start.minute.toString().padLeft(2, '0')}";
    final endStr =
        "${_end.hour.toString().padLeft(2, '0')}:${_end.minute.toString().padLeft(2, '0')}";

    const String defaultClubId = "1";
    const String defaultSeasonIdBigint = "1";

    const updateMatchdayMutation = r'''
      mutation UpdateMatchday(
        $id: bigint!,
        $matchDate: date!,
        $roundNo: Int!,
        $notes: String,
        $maxPlayers: Int
      ) {
        update_matchdays_by_pk(
          pk_columns: {id: $id},
          _set: {
            match_date: $matchDate,
            round_no: $roundNo,
            notes: $notes,
            max_players: $maxPlayers
          }
        ) {
          id
          round_no
          match_date
        }
      }
    ''';

    return Scaffold(
      appBar: AppBar(title: const Text("Edit matchday")),
      body: Center(
        child: ConstrainedBox(
          constraints: const BoxConstraints(maxWidth: 680),
          child: Padding(
            padding: const EdgeInsets.all(16),
            child: Card(
              elevation: 8,
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Mutation(
                  options: MutationOptions(document: gql(updateMatchdayMutation)),
                  builder: (runMutation, result) {
                    final isSaving = result?.isLoading ?? false;

                    void onSave() {
                      if (!_formKey.currentState!.validate()) return;

                      final roundNo = int.tryParse(_roundCtrl.text.trim()) ?? 1;

                      runMutation({
                        "id": widget.matchday['id'].toString(),
                        "matchDate": dateStr,
                        "roundNo": roundNo,
                        "notes": _notesCtrl.text.trim().isEmpty
                            ? null
                            : _notesCtrl.text.trim(),
                        "maxPlayers": _maxPlayers,
                      });
                    }

                    WidgetsBinding.instance.addPostFrameCallback((_) {
                      if (result == null) return;
                      if (result.isLoading) return;

                      if (result.hasException) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(result.exception.toString()),
                            backgroundColor: Colors.red,
                          ),
                        );
                        return;
                      }

                      final updated = result.data?['update_matchdays_by_pk'];
                      if (updated != null) {
                        ScaffoldMessenger.of(context).showSnackBar(
                          SnackBar(
                            content: Text(
                              "Etapa actualizata ✅ (Round: ${updated['round_no']})",
                            ),
                          ),
                        );
                        Navigator.pop(context);
                      }
                    });

                    return Form(
                      key: _formKey,
                      child: ListView(
                        shrinkWrap: true,
                        children: [
                          const Text(
                            "Edit matchday",
                            style: TextStyle(fontSize: 22, fontWeight: FontWeight.w800),
                          ),
                          const SizedBox(height: 14),

                          const Text(
                            "Soccer field",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          DropdownButtonFormField<String>(
                            value: _soccerField,
                            items: const [
                              DropdownMenuItem(
                                value: 'Nastase&Marica Sports Club - București',
                                child: Text('Nastase&Marica Sports Club - București'),
                              ),
                              DropdownMenuItem(
                                value: 'Alt teren (demo)',
                                child: Text('Alt teren (demo)'),
                              ),
                            ],
                            onChanged: isSaving
                                ? null
                                : (v) => setState(() => _soccerField = v ?? _soccerField),
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Round (Etapa)",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _roundCtrl,
                            keyboardType: TextInputType.number,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                            ),
                            validator: (v) {
                              final n = int.tryParse(v ?? '');
                              if (n == null || n <= 0) return "Invalid round";
                              return null;
                            },
                            enabled: !isSaving,
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Max players",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              SizedBox(
                                width: 120,
                                child: TextFormField(
                                  initialValue: _maxPlayers.toString(),
                                  keyboardType: TextInputType.number,
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  validator: (v) {
                                    final n = int.tryParse(v ?? '');
                                    if (n == null || n <= 0) return "Invalid";
                                    return null;
                                  },
                                  enabled: !isSaving,
                                  onChanged: (v) {
                                    final n = int.tryParse(v);
                                    if (n != null) setState(() => _maxPlayers = n);
                                  },
                                ),
                              ),
                              const SizedBox(width: 10),
                              const Text("Players"),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Date",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(dateStr),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: isSaving ? null : _pickDate,
                                child: const Text("Pick"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Start time",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(startStr),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: isSaving ? null : _pickTimeStart,
                                child: const Text("Pick"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "End time",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          Row(
                            children: [
                              Expanded(
                                child: InputDecorator(
                                  decoration: const InputDecoration(
                                    border: OutlineInputBorder(),
                                  ),
                                  child: Text(endStr),
                                ),
                              ),
                              const SizedBox(width: 10),
                              OutlinedButton(
                                onPressed: isSaving ? null : _pickTimeEnd,
                                child: const Text("Pick"),
                              ),
                            ],
                          ),

                          const SizedBox(height: 16),
                          const Text(
                            "Notes",
                            style: TextStyle(fontWeight: FontWeight.w700),
                          ),
                          const SizedBox(height: 6),
                          TextFormField(
                            controller: _notesCtrl,
                            minLines: 3,
                            maxLines: 6,
                            enabled: !isSaving,
                            decoration: const InputDecoration(
                              border: OutlineInputBorder(),
                              hintText: "Detalii despre etapa…",
                            ),
                          ),

                          const SizedBox(height: 18),
                          ElevatedButton(
                            onPressed: isSaving ? null : onSave,
                            child: Row(
                              mainAxisAlignment: MainAxisAlignment.center,
                              children: [
                                if (isSaving) ...[
                                  const SizedBox(
                                    width: 18,
                                    height: 18,
                                    child: CircularProgressIndicator(strokeWidth: 2),
                                  ),
                                  const SizedBox(width: 10),
                                  const Text("Saving..."),
                                ] else
                                  const Text("Update matchday"),
                              ],
                            ),
                          ),
                        ],
                      ),
                    );
                  },
                ),
              ),
            ),
          ),
        ),
      ),
    );
  }
}
