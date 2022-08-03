import 'package:flutter/services.dart';
import 'package:nanday_twitch_app/constants.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:twitch_api/twitch_api.dart';
import 'package:url_launcher/url_launcher.dart';

abstract class TwitchService {
  ///
  /// Authenticates with the Twitch backend and returns a result
  ///
  Future<TwitchAuthenticationResult> authenticate(String clientId);
}

class TwitchServiceImpl implements TwitchService {

  @override
  Future<TwitchAuthenticationResult> authenticate(String clientId) async {
    final _twitchClient = TwitchClient(
      clientId: clientId,
      redirectUri: Constants.REDIRECT_URI,
    );

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

    var server = await shelf_io.serve(handler, Constants.REDIRECT_HOST, Constants.REDIRECT_PORT);

    List<TwitchApiScope> scopes = const [];
    Uri url = _twitchClient.authorizeUri(scopes);
    await launchUrl(url);

    int retries = 0;

    while (result == null && retries < 60) {
      await Future.delayed(const Duration(seconds: 2));
      retries++;
    }

    await server.close();

    return result!;
  }
}

class TwitchAuthenticationResult {
  TwitchAuthenticationResult({this.token, this.error});

  String? token;
  String? error;
}
