import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/ui/login/login_page.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:provider/provider.dart';

void main() {
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'Flutter Demo',
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ChangeNotifierProvider(
          create: (context) => NandayDependencyInjector.instance.resolve<LoginPageViewModel>(),
          child: const LoginPage(),
        ));
  }
}
