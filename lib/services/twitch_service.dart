import 'dart:convert';
import 'dart:ffi';

import 'package:nanday_twitch_app/constants.dart';
import 'package:shelf_static/shelf_static.dart';
import 'package:twitch_api/twitch_api.dart';
import 'dart:io';
import 'package:shelf/shelf.dart';
import 'package:shelf/shelf_io.dart' as shelf_io;
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

    var handler = createStaticHandler('files', defaultDocument: 'index.html');

    var server = await shelf_io.serve(handler, Constants.REDIRECT_HOST, Constants.REDIRECT_PORT);

    // server.listen((request) {
    //   String requestedUri = request.requestedUri.toString();
    //   String fragment = request.requestedUri.fragment;
    //   String a = "";
    // });

    // ServerSocket socket = await ServerSocket.bind(
    //   Constants.REDIRECT_HOST,
    //   Constants.REDIRECT_PORT
    // );

    // Socket socket = await Socket.connect(
    //     Constants.REDIRECT_HOST,
    //     Constants.REDIRECT_PORT
    // );
    //
    // socket.listen((List<int> event) {
    //   String a = utf8.decode(event);
    //   String b = "";
    // });

    List<TwitchApiScope> scopes = const []; // TODO?
    Uri url = _twitchClient.authorizeUri(scopes);
    await launch(url.toString());

    return TwitchAuthenticationResult();
  }

  Response _echoRequest(Request request) {
    String uri = request.url.toString();
    String requestedUri = request.requestedUri.toString();
    String fragment = request.requestedUri.fragment;
    return Response.ok('<html><head><title>Test!</title><body></body></html>');
  }
}

class TwitchAuthenticationResult {
  TwitchAuthenticationResult({this.token, this.error});

  String? token;
  String? error;
}