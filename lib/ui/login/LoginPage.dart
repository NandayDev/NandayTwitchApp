import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<LoginPage> {
  String _currentState = "";

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  _tryLogin();
                },
                child: const Text("LOGIN")),
            Padding(
              padding: const EdgeInsets.only(top: 20.0),
              child: Text(_currentState),
            )
          ],
        ),
      ),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );
  }

  void _tryLogin() async {
    String file = await rootBundle.loadString('assets/keys/twitch_keys.json');
    TwitchAuthenticationResult result = await TwitchAuthenticationServiceImpl()
        .authenticate(jsonDecode(file)['chatBotClientId'] as String, Constants.CHAT_REDIRECT_PORT, Constants.CHAT_SCOPES);
    if (result.token != null) {
      setState(() {
        _currentState = "Got token";
      });
      await TwitchChatServiceImpl().connect(result.token!);
    }
  }
}
