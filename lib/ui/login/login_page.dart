import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:nanday_twitch_app/constants.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/services/twitch_authentication_service.dart';
import 'package:nanday_twitch_app/services/twitch_chat_service.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:nanday_twitch_app/ui/main/main_page.dart';
import 'package:nanday_twitch_app/ui/main/main_page_view_model.dart';
import 'package:provider/provider.dart';

class LoginPage extends StatefulWidget {
  const LoginPage({Key? key}) : super(key: key);

  @override
  State<LoginPage> createState() => _MyHomePageState();
}

class _MyHomePageState extends State<LoginPage> {
  bool loading = false;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text("Login"),
      ),
      body: loading ? const Center(child: CircularProgressIndicator()) : Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            TextButton(
                onPressed: () {
                  _tryLogin();
                },
                child: const Text("LOGIN")),
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
    setState(() {
      loading = true;
    });
    bool authenticated = await Provider.of<LoginPageViewModel>(context, listen: false).authenticate();
    if (authenticated) {
      Navigator.push(
        context,
        MaterialPageRoute(builder: (context) => ChangeNotifierProvider(
          create: (context) => NandayDependencyInjector.instance.resolve<MainPageViewModel>(),
          child: const MainPage(),
        )),
      );
    }
    setState(() {
      // TODO show error
      loading = false;
    });
  }
}
