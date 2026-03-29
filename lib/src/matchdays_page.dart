import 'package:flutter/material.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class MatchdaysPage extends StatelessWidget {
  const MatchdaysPage({super.key});

  static const queryData = r'''
  query MatchdaysPageData($userId: uuid!) {
    player_accounts(where: {user_id: {_eq: $userId}}, limit: 1) {
      player_id
    }
    players(
      where: {status: {_eq: guest}}
      order_by: {id: asc}
    ) {
      id
      name
      nickname
      back_number
      status
    }
    matchdays(order_by: {match_date: desc}) {
      id
      round_no
      match_date
      max_players
      match_players_aggregate {
        aggregate {
          count
        }
      }
      match_players {
        id
        player_id
        player {
          id
          name
          nickname
          back_number
          status
        }
      }
    }
  }
  ''';

  static const joinMutation = r'''
  mutation JoinMatch($matchdayId: bigint!, $playerId: bigint!) {
    insert_match_players_one(
      object: {
        matchday_id: $matchdayId,
        player_id: $playerId,
        present: true,
        wants_captain: false,
        is_captain: false
      },
      on_conflict: {
        constraint: uq_matchday_player,
        update_columns: []
      }
    ) {
      id
    }
  }
  ''';

  static const leaveMutation = r'''
  mutation LeaveMatch($matchdayId: bigint!, $playerId: bigint!) {
    delete_match_players(
      where: {
        matchday_id: {_eq: $matchdayId},
        player_id: {_eq: $playerId}
      }
    ) {
      affected_rows
    }
  }
  ''';

  static const deleteMatchdayMutation = r'''
  mutation DeleteMatchday($id: bigint!) {
    delete_matchdays_by_pk(id: $id) {
      id
    }
  }
  ''';

  bool _isAdmin() {
    final user = Supabase.instance.client.auth.currentUser;
    final hasura = user?.appMetadata['hasura'];

    if (hasura is Map) {
      final defaultRole = hasura['x-hasura-default-role']?.toString();
      final allowedRoles = hasura['x-hasura-allowed-roles'];

      if (defaultRole == 'admin') return true;
      if (allowedRoles is List &&
          allowedRoles.map((e) => e.toString()).contains('admin')) {
        return true;
      }
    }

    return false;
  }

  void _showDeleteConfirmation(
    BuildContext context,
    String matchdayId,
    int roundNo,
    Function()? refetch,
  ) {
    showDialog(
      context: context,
      builder: (ctx) => AlertDialog(
        title: const Text("Șterge etapa?"),
        content: Text("Ești sigur că vrei să ștergi Etapa $roundNo?"),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(ctx),
            child: const Text("Anulează"),
          ),
          Mutation(
            options: MutationOptions(
              document: gql(deleteMatchdayMutation),
              onCompleted: (_) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  const SnackBar(
                    content: Text("Etapa ștearsă ✅"),
                  ),
                );
                refetch?.call();
              },
              onError: (error) {
                Navigator.pop(ctx);
                ScaffoldMessenger.of(context).showSnackBar(
                  SnackBar(
                    content: Text("Eroare: ${error.toString()}"),
                    backgroundColor: Colors.red,
                  ),
                );
              },
            ),
            builder: (runMutation, result) {
              return TextButton(
                onPressed: result?.isLoading ?? false
                    ? null
                    : () {
                        runMutation({"id": matchdayId});
                      },
                style: TextButton.styleFrom(
                  foregroundColor: Colors.red,
                ),
                child: result?.isLoading ?? false
                    ? const SizedBox(
                        width: 20,
                        height: 20,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      )
                    : const Text("Șterge"),
              );
            },
          ),
        ],
      ),
    );
  }

  bool _isMatchdayInPast(String matchDateStr) {
    try {
      final matchDate = DateTime.parse(matchDateStr);
      final now = DateTime.now();
      // Comparare doar pe zile (ignor orele)
      return matchDate.isBefore(DateTime(now.year, now.month, now.day));
    } catch (e) {
      print('Error parsing match date: $e');
      return false;
    }
  }

  bool _isGuest(Map<String, dynamic>? p) {
    return p?['status']?.toString() == 'guest';
  }

  String _playerLabel(Map<String, dynamic>? p) {
    final name = p?['name'] ?? 'Fara nume';
    final nickname = p?['nickname'];
    final number = p?['back_number'];
    final status = p?['status'];

    String line = name.toString();

    if (nickname != null && nickname.toString().isNotEmpty) {
      line += ' ($nickname)';
    }
    if (number != null) {
      line += ' - #$number';
    }
    if (status == 'guest') {
      line += ' [Guest]';
    }

    return line;
  }

  @override
  Widget build(BuildContext context) {
    final userId = Supabase.instance.client.auth.currentUser?.id;
    final isAdmin = _isAdmin();

    if (userId == null) {
      return Scaffold(
        appBar: AppBar(title: const Text("Etape")),
        body: const Center(child: Text("Nu esti logat.")),
      );
    }

    return Scaffold(
      appBar: AppBar(title: const Text("Etape")),
      body: Query(
        options: QueryOptions(
          document: gql(queryData),
          variables: {"userId": userId},
          fetchPolicy: FetchPolicy.networkOnly,
        ),
        builder: (result, {fetchMore, refetch}) {
          if (result.isLoading) {
            return const Center(child: CircularProgressIndicator());
          }

          if (result.hasException) {
            return Center(
              child: Padding(
                padding: const EdgeInsets.all(16),
                child: Text(result.exception.toString()),
              ),
            );
          }

          final playerAccounts = result.data?['player_accounts'] as List? ?? [];
          if (playerAccounts.isEmpty) {
            return const Center(
              child: Text("Userul logat nu este legat de niciun player."),
            );
          }

          final currentPlayerId = playerAccounts.first['player_id'].toString();
          final List matchdays = result.data?['matchdays'] ?? [];
          final List guestPlayers = result.data?['players'] ?? [];

          if (matchdays.isEmpty) {
            return const Center(child: Text("Nu exista etape disponibile."));
          }

          return ListView.builder(
            itemCount: matchdays.length,
            itemBuilder: (context, index) {
              final m = matchdays[index];
              final count =
                  m['match_players_aggregate']?['aggregate']?['count'] ?? 0;
              final List players = m['match_players'] ?? [];

              final isJoined = players.any(
                (mp) => mp['player_id'].toString() == currentPlayerId,
              );

              final usedPlayerIds =
                  players.map((mp) => mp['player_id'].toString()).toSet();

              Map<String, dynamic>? firstFreeGuest;
              for (final g in guestPlayers) {
                if (!usedPlayerIds.contains(g['id'].toString())) {
                  firstFreeGuest = Map<String, dynamic>.from(g);
                  break;
                }
              }

              return Card(
                margin: const EdgeInsets.all(10),
                child: Padding(
                  padding: const EdgeInsets.all(16),
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        "Etapa ${m['round_no']}",
                        style: const TextStyle(
                          fontSize: 18,
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      const SizedBox(height: 6),
                      Text("Data: ${m['match_date']}"),
                      Text("Inscrisi: $count / ${m['max_players']}"),
                      const SizedBox(height: 10),

                      if (!isJoined)
                        Mutation(
                          options: MutationOptions(
                            document: gql(joinMutation),
                            onCompleted: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                const SnackBar(
                                  content: Text("Inscriere salvata ✅"),
                                ),
                              );
                              refetch?.call();
                            },
                            onError: (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                          builder: (runMutation, joinResult) {
                            return ElevatedButton(
                              onPressed: () {
                                runMutation({
                                  "matchdayId": m['id'].toString(),
                                  "playerId": currentPlayerId,
                                });
                              },
                              child: const Text("Join"),
                            );
                          },
                        )
                      else
                        Row(
                          children: [
                            const Chip(label: Text("Joined")),
                            const SizedBox(width: 10),
                            Mutation(
                              options: MutationOptions(
                                document: gql(leaveMutation),
                                onCompleted: (_) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    const SnackBar(
                                      content: Text("Te-ai retras din etapa."),
                                    ),
                                  );
                                  refetch?.call();
                                },
                                onError: (error) {
                                  ScaffoldMessenger.of(context).showSnackBar(
                                    SnackBar(
                                      content: Text(error.toString()),
                                      backgroundColor: Colors.red,
                                    ),
                                  );
                                },
                              ),
                              builder: (runMutation, leaveResult) {
                                return OutlinedButton(
                                  onPressed: () {
                                    runMutation({
                                      "matchdayId": m['id'].toString(),
                                      "playerId": currentPlayerId,
                                    });
                                  },
                                  child: const Text("Leave"),
                                );
                              },
                            ),
                          ],
                        ),

                      if (isAdmin) ...[
                        const SizedBox(height: 10),
                        Mutation(
                          options: MutationOptions(
                            document: gql(joinMutation),
                            onCompleted: (_) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(
                                    firstFreeGuest == null
                                        ? "Nu mai exista guest liber."
                                        : "Guest adaugat ✅",
                                  ),
                                ),
                              );
                              refetch?.call();
                            },
                            onError: (error) {
                              ScaffoldMessenger.of(context).showSnackBar(
                                SnackBar(
                                  content: Text(error.toString()),
                                  backgroundColor: Colors.red,
                                ),
                              );
                            },
                          ),
                          builder: (runMutation, guestResult) {
                            return OutlinedButton.icon(
                              onPressed: firstFreeGuest == null
                                  ? null
                                  : () {
                                      runMutation({
                                        "matchdayId": m['id'].toString(),
                                        "playerId":
                                            firstFreeGuest!['id'].toString(),
                                      });
                                    },
                              icon: const Icon(Icons.person_add_alt_1),
                              label: Text(
                                firstFreeGuest == null
                                    ? "No free guest"
                                    : "Add Guest (${firstFreeGuest['name']})",
                              ),
                            );
                          },
                        ),
                        const SizedBox(height: 12),
                        Row(
                          children: [
                            Expanded(
                              child: OutlinedButton.icon(
                                onPressed: () {
                                  Navigator.pushNamed(
                                    context,
                                    '/matchday/edit',
                                    arguments: m,
                                  );
                                },
                                icon: const Icon(Icons.edit),
                                label: const Text("Edit"),
                              ),
                            ),
                            const SizedBox(width: 10),
                            Expanded(
                              child: Tooltip(
                                message: _isMatchdayInPast(m['match_date'])
                                    ? "Nu poți șterge etape jucate!"
                                    : "Șterge etapa",
                                child: OutlinedButton.icon(
                                  onPressed: _isMatchdayInPast(m['match_date'])
                                      ? null
                                      : () {
                                          _showDeleteConfirmation(
                                            context,
                                            m['id'].toString(),
                                            m['round_no'],
                                            refetch,
                                          );
                                        },
                                  icon: const Icon(Icons.delete),
                                  label: const Text("Delete"),
                                  style: OutlinedButton.styleFrom(
                                    foregroundColor: _isMatchdayInPast(m['match_date'])
                                        ? Colors.grey
                                        : Colors.red,
                                  ),
                                ),
                              ),
                            ),
                          ],
                        ),
                      ],

                      const SizedBox(height: 14),
                      const Text(
                        "Jucatori inscrisi:",
                        style: TextStyle(fontWeight: FontWeight.w700),
                      ),
                      const SizedBox(height: 8),

                      if (players.isEmpty)
                        const Text("Niciun jucator inscris momentan.")
                      else
                        ...players.map<Widget>((mp) {
                          final p = mp['player'] as Map<String, dynamic>?;
                          final playerIdToRemove = mp['player_id'].toString();
                          final guestRow = _isGuest(p);

                          if (isAdmin && guestRow) {
                            return Padding(
                              padding: const EdgeInsets.only(bottom: 6),
                              child: Row(
                                children: [
                                  Expanded(
                                    child: Text("• ${_playerLabel(p)}"),
                                  ),
                                  Mutation(
                                    options: MutationOptions(
                                      document: gql(leaveMutation),
                                      onCompleted: (_) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          const SnackBar(
                                            content: Text("Guest eliminat."),
                                          ),
                                        );
                                        refetch?.call();
                                      },
                                      onError: (error) {
                                        ScaffoldMessenger.of(context)
                                            .showSnackBar(
                                          SnackBar(
                                            content: Text(error.toString()),
                                            backgroundColor: Colors.red,
                                          ),
                                        );
                                      },
                                    ),
                                    builder: (runMutation, removeResult) {
                                      final isMatchdayPast =
                                          _isMatchdayInPast(m['match_date']);
                                      return IconButton(
                                        onPressed: isMatchdayPast
                                            ? null
                                            : () {
                                                runMutation({
                                                  "matchdayId":
                                                      m['id'].toString(),
                                                  "playerId": playerIdToRemove,
                                                });
                                              },
                                        icon: Icon(
                                          Icons.close,
                                          size: 18,
                                          color: isMatchdayPast
                                              ? Colors.grey
                                              : Colors.red,
                                        ),
                                        tooltip: isMatchdayPast
                                            ? "Nu poți șterge din etape jucate"
                                            : "Elimină guest",
                                        padding: EdgeInsets.zero,
                                        constraints: const BoxConstraints(
                                          minWidth: 32,
                                          minHeight: 32,
                                        ),
                                      );
                                    },
                                  ),
                                ],
                              ),
                            );
                          }

                          return Padding(
                            padding: const EdgeInsets.only(bottom: 4),
                            child: Text("• ${_playerLabel(p)}"),
                          );
                        }).toList(),
                    ],
                  ),
                ),
              );
            },
          );
        },
      ),
    );
  }
}