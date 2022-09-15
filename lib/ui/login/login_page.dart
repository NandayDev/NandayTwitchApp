import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
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
  @override
  void initState() {
    super.initState();
    Provider.of<LoginPageViewModel>(context, listen: false).getProfiles();
  }

  @override
  Widget build(BuildContext context) {
    LoginPageViewModel viewModel = Provider.of<LoginPageViewModel>(context);
    if (viewModel.authenticationResult != null) {
      EmptyResult<String> authenticationResult = viewModel.authenticationResult!;
      if (authenticationResult.hasError) {
        showDialog(
            context: context,
            barrierDismissible: false, // user must tap button!
            builder: (BuildContext context) {
              return AlertDialog(
                title: const Text('Authentication failed'),
                content: SingleChildScrollView(
                  child: ListBody(
                    children: [
                      Text(authenticationResult.error!),
                    ],
                  ),
                ),
                actions: <Widget>[
                  TextButton(
                    child: const Text('Ok'),
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                  ),
                ],
              );
            });
      } else {
        // Goes to main page //
        Navigator.pop(context);
        Navigator.push(
          context,
          MaterialPageRoute(
              builder: (context) => ChangeNotifierProvider(
                    create: (context) => NandayDependencyInjector.instance.resolve<MainPageViewModel>(),
                    child: const MainPage(),
                  )),
        );
      }
    }
    const TextStyle textButtonFontStyle = TextStyle(fontSize: 18.0);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: Center(
            child: Column(
          children: [
            SizedBox(
                width: 200.0,
                height: 100.0,
                child: DropdownButton<Profile>(
                  value: viewModel.selectedProfile,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(color: Colors.deepPurple),
                  underline: Container(
                    height: 2,
                    color: Colors.deepPurpleAccent,
                  ),
                  onChanged: (Profile? newValue) {
                    viewModel.selectedProfile = newValue;
                  },
                  items: viewModel.profiles.map<DropdownMenuItem<Profile>>((Profile profile) {
                    return DropdownMenuItem<Profile>(child: Text('${profile.channelName} | ${profile.botUsername}'));
                  }).toList(),
                )),
            const SizedBox(
              height: 20.0,
            ),
            MaterialButton(
                onPressed: viewModel.isLoginButtonEnabled
                    ? () {
                        viewModel.authenticate();
                      }
                    : null,
                child: const Text('LOGIN', style: textButtonFontStyle)),
            const SizedBox(
              height: 20.0,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () {
                      // TODO
                    },
                    child: const Text("Create new profile", style: textButtonFontStyle,)),
                viewModel.selectedProfile == null
                    ? Container()
                    : Row(
                        children: [
                          const Text("  |  "),
                          TextButton(
                              onPressed: () {
                                // TODO
                              },
                              child: const Text("Edit profile", style: textButtonFontStyle))
                        ],
                      )
              ],
            )
          ],
        )));
  }
}
