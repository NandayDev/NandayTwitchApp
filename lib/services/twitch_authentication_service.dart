import 'package:flutter/services.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:url_launcher/url_launcher.dart';

abstract class TwitchAuthenticationService {
  ///
  /// Authenticates with the Twitch backend and returns a result
  ///
  Future<TwitchAuthenticationResult> authenticate(String clientId, int redirectPort, List<String> scopes);
}

class TwitchAuthenticationServiceImpl implements TwitchAuthenticationService {
  @override
  Future<TwitchAuthenticationResult> authenticate(String clientId, int redirectPort, List<String> scopes) async {

    TwitchAuthenticationResult? result;

    var handler = const Pipeline().addMiddleware(logRequests()).addHandler((request) async {
      if (request.requestedUri.queryParameters.containsKey('access_token')) {
        String accessToken = request.requestedUri.queryParameters['access_token']!;
        result = TwitchAuthenticationResult(token: accessToken);
        return Response.ok('You can now close this page');
      }

      String htmlPage = await rootBundle.loadString('assets/html/index_redirect_token.html');

      return Response.ok(htmlPage, headers: {'Content-Type': 'text/html'});
    });

    var server = await shelf_io.serve(handler, 'localhost', redirectPort);

    Uri url = Uri(
        scheme: 'https',
        host: 'id.twitch.tv',
        pathSegments: <String>['oauth2', 'authorize'],
        queryParameters: {
          'response_type': 'token',
          'client_id': clientId,
          'redirect_uri': 'http://localhost:$redirectPort',
          'scope': scopes.join(' '),
        },
    );
    await launchUrl(url);

    int retries = 0;

    while (result == null && retries < 60) {
      await Future.delayed(const Duration(seconds: 2));
      retries++;
      if (retries == 60) {
        result = TwitchAuthenticationResult(error: "Generic error"); //TODO error handling for timeout
      }
    }

    await server.close();

    return result!;
  }
}

class TwitchAuthenticationResult {
  TwitchAuthenticationResult({this.token, this.error});

  final String? token;
  final String? error;
}
