import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/models/result.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/ui/login/login_page_view_model.dart';
import 'package:nanday_twitch_app/ui/login/profile_dialog.dart';
import 'package:nanday_twitch_app/ui/login/profile_dialog_view_model.dart';
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
      Future.delayed(const Duration(seconds: 1)).then((value) {
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
        };
      });
    }
    const TextStyle textButtonFontStyle = TextStyle(fontSize: 18.0);
    return Scaffold(
        appBar: AppBar(
          title: const Text("Login"),
        ),
        body: Center(
            child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            DropdownButton<Profile>(
                  value: viewModel.selectedProfile,
                  icon: const Icon(Icons.arrow_downward),
                  elevation: 16,
                  style: const TextStyle(fontSize: 20, color: Colors.black87),
                  underline: Container(
                    height: 2,
                    color: Theme.of(context).primaryColor,
                  ),
                  onChanged: (Profile? newValue) {
                    viewModel.selectedProfile = newValue;
                  },
                  items: viewModel.profiles.map<DropdownMenuItem<Profile>>((Profile profile) {
                    return DropdownMenuItem<Profile>(
                      child: Text('${profile.channelName} | ${profile.botUsername}'),
                      value: profile,
                    );
                  }).toList(),
                ),
            const SizedBox(
              height: 30.0,
            ),
            MaterialButton(
                color: Theme.of(context).primaryColor,
                textColor: Colors.white,
                onPressed: viewModel.isLoginButtonEnabled && !viewModel.isLoading
                    ? () {
                        viewModel.authenticate();
                      }
                    : null,
                child: Padding(
                    padding: const EdgeInsets.all(10.0),
                    child: viewModel.isLoading ? const CircularProgressIndicator() : const Text('LOGIN', style: TextStyle(fontSize: 20.0)))),
            const SizedBox(
              height: 30.0,
            ),
            Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                TextButton(
                    onPressed: () {
                      showProfileDialog();
                    },
                    child: const Text(
                      "Create new profile",
                      style: textButtonFontStyle,
                    )),
                viewModel.selectedProfile == null
                    ? Container()
                    : Row(
                        children: [
                          const Text("  |  "),
                          TextButton(
                              onPressed: () {
                                showProfileDialog(profile: viewModel.selectedProfile);
                              },
                              child: const Text("Edit profile", style: textButtonFontStyle))
                        ],
                      )
              ],
            )
          ],
        )));
  }

  void showProfileDialog({Profile? profile}) async {
    await showDialog(
        context: context,
        builder: (BuildContext context) {
          return ChangeNotifierProvider(
            create: (context) => NandayDependencyInjector.instance
                .resolve<ProfileDialogViewModel>(additionalParameters: {ProfileDialogViewModel.profileParamName: profile}),
            child: ProfileDialog(profile: profile),
          );
        });
    // Reloads profiles once the showDialog future is completed //
    Provider.of<LoginPageViewModel>(context, listen: false).getProfiles();
  }
}
