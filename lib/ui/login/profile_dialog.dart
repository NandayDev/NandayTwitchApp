import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/ui/login/profile_dialog_view_model.dart';
import 'package:nanday_twitch_app/utilities/AlertDialogUtility.dart';
import 'package:provider/provider.dart';

class ProfileDialog extends StatefulWidget {
  const ProfileDialog({this.profile, Key? key}) : super(key: key);

  final Profile? profile;

  @override
  State<ProfileDialog> createState() => _ProfileDialogState();
}

class _ProfileDialogState extends State<ProfileDialog> {
  @override
  Widget build(BuildContext context) {
    ProfileDialogViewModel viewModel = Provider.of<ProfileDialogViewModel>(context);
    TextEditingController botUsernameTextController = TextEditingController(text: viewModel.botUsername);
    TextEditingController channelNameTextController = TextEditingController(text: viewModel.channelName);
    bool? profileSavedSuccessfully = viewModel.profileSavedSuccessfully;
    switch(profileSavedSuccessfully) {
      case true:
        Navigator.of(context).pop();
        // TODO notify the login page a profile was changed
        return Container();

      case false:
        AlertDialogUtility.showTextDialog(context, "Profile couldn't be saved. Please try again.");
        break;
    }
    return AlertDialog(
      title: Text(widget.profile == null ? "Create new profile" : "Edit profile"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(width: 400, height: 0,),
        Row(
          children: [
            const Text("Bot username *"),
            const SizedBox(
              width: 20,
            ),
            SizedBox(
              width: 250.0,
              child: TextField(
              controller: botUsernameTextController,
                onChanged: (newText) {
                  viewModel.botUsername = newText;
                  setState(() {

                  });
                },
            ))
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(
          children: [
            const Text("Channel name *"),
            const SizedBox(
              width: 20,
            ),
            SizedBox(
              width: 250.0,
              child: TextField(
              controller: channelNameTextController,
                onChanged: (newText) {
                  viewModel.channelName = newText;
                  setState(() {

                  });
                },
            ))
          ],
        )
      ]),
      actions: [
        TextButton(
            onPressed: viewModel.isSaveButtonEnabled ? viewModel.saveProfile : null,
            child: const Text("Save")),
        TextButton(
            onPressed: () {
              Navigator.of(context).pop();
            },
            child: const Text("Cancel"))
      ],
    );
  }
}
