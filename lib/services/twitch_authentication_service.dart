import 'dart:convert';

import 'package:flutter/services.dart';
import 'package:nanday_twitch_app/services/logger_service.dart';
import 'package:nanday_twitch_app/services/persistent_storage_service.dart';
import 'package:nanday_twitch_app/services/twitch_keys_reader.dart';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
import 'package:url_launcher/url_launcher.dart';
import 'package:http/http.dart' as http;
import 'dart:io';

abstract class TwitchAuthenticationService {
  ///
  /// Authenticates with the Twitch backend and returns a result
  ///
  Future<TwitchAuthenticationResult> authenticate(int redirectPort, List<String> scopes);

  ///
  /// Generates a map with the headers for the Twitch APIs
  ///
  Map<String, String> generateApiHeaders();

  ///
  /// Access token provided by the authentication method. Null if not obtained yet
  ///
  String? accessToken;

  ///
  /// Twitch ID of the user
  ///
  int? userId;
}

class TwitchAuthenticationServiceImpl implements TwitchAuthenticationService {

  TwitchAuthenticationServiceImpl(this._twitchKeysReader, this._storageService, this._loggerService);

  final TwitchKeysReader _twitchKeysReader;
  final PersistentStorageService _storageService;
  final LoggerService _loggerService;

  @override
  String? accessToken;

  @override
  int? userId;

  late TwitchKeys _keys;

  @override
  Future<TwitchAuthenticationResult> authenticate(int redirectPort, List<String> scopes) async {

    if (accessToken != null) {
      return TwitchAuthenticationResult(token: accessToken);
    }

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
    _keys = await _twitchKeysReader.getTwitchKeys();
    String clientId = _keys.applicationClientId;

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
    String? browserExecutable = _storageService.currentProfile!.browserExecutable;
    if (browserExecutable != null) {
      await Process.run(browserExecutable, [ url.toString() ]);
    } else {
      await launchUrl(url);
    }

    int retries = 0;

    while (result == null && retries < 60) {
      await Future.delayed(const Duration(seconds: 2));
      retries++;
      if (retries == 60) {
        result = TwitchAuthenticationResult(error: "Generic error"); //TODO error handling for timeout
      }
    }

    await server.close();

    if (result!.token != null) {
      accessToken = result!.token;
    }

    userId = await _getUserId(
        _storageService.currentProfile!.channelName,
        generateApiHeaders()
    );

    if (userId == null) {
      result = TwitchAuthenticationResult(error: "Couldn't get user id"); //TODO error handling for timeout
    }

    return result!;
  }

  @override
  Map<String, String> generateApiHeaders() {
    return {'Authorization': 'Bearer $accessToken', 'Client-Id': _keys.applicationClientId};
  }

  Future<int?> _getUserId(String userLogin, Map<String, String> headers) async {
    int retries = 0;
    while (retries < 3) {
      try {
        http.Response response = await http.get(Uri.parse('https://api.twitch.tv/helix/users?$userLogin'), headers: headers);
        dynamic responseJson = jsonDecode(response.body);
        for (dynamic data in responseJson['data']) {
          _loggerService.d('Correctly fetched user id');
          return int.parse(data['id']);
        }
        retries++;
        await Future.delayed(const Duration(seconds: 5));
      } catch (e) {
        _loggerService.w('Could not get user id: ${e.toString()} retrying.');
      }
    }
    _loggerService.e('Could not get user id: aborting');
    return null;
  }
}

class TwitchAuthenticationResult {
  TwitchAuthenticationResult({this.token, this.error});

  final String? token;
  final String? error;

  bool get hasError { return error != null; }
}
