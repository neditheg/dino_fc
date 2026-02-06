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
        final token =
            Supabase.instance.client.auth.currentSession?.accessToken;

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
