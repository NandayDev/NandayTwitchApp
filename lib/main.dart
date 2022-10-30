import 'package:flutter/material.dart';
import 'package:flutter_gen/gen_l10n/app_localizations.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/services/service_initiator.dart';
import 'package:nanday_twitch_app/ui/login/login_page.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:provider/provider.dart';

void main() async {
  await ServiceInitiator.instance.initializeAtAppStartup();
  runApp(const MyApp());
}

class MyApp extends StatelessWidget {
  const MyApp({Key? key}) : super(key: key);

  // This widget is the root of your application.
  @override
  Widget build(BuildContext context) {
    return MaterialApp(
        title: 'NaNDay Twitch App',
        localizationsDelegates: AppLocalizations.localizationsDelegates,
        supportedLocales: AppLocalizations.supportedLocales,
        theme: ThemeData(
          primarySwatch: Colors.blue,
        ),
        home: ChangeNotifierProvider(
          create: (context) => NandayDependencyInjector.instance.resolve<LoginPageViewModel>(),
          child: const LoginPage(),
        ));
  }
}
