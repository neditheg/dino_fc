import 'package:flutter/foundation.dart';
import 'package:graphql_flutter/graphql_flutter.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class Gql {
  static const String endpoint =
      'https://dino-fc-api.hasura.app/v1/graphql';

  static ValueNotifier<GraphQLClient> initClient() {
    final httpLink = HttpLink(endpoint);

    final authLink = AuthLink(
      getToken: () async {
        final user = Supabase.instance.client.auth.currentUser;
        final session = Supabase.instance.client.auth.currentSession;
        final token = session?.accessToken;

        print('SUPABASE USER ID: ${user?.id}');
        print('APP METADATA: ${user?.appMetadata}');
        print('ACCESS TOKEN EXISTS: ${token != null}');

        if (token == null) return null;
        return 'Bearer $token';
      },
    );

    final link = authLink.concat(httpLink);

    return ValueNotifier(
      GraphQLClient(
        link: link,
        cache: GraphQLCache(store: InMemoryStore()),
      ),
    );
  }
}