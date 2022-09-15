import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/models/profile.dart';
import 'package:nanday_twitch_app/ui/login/profile_dialog_view_model.dart';
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
    TextEditingController botUsernameTextController = TextEditingController(viewModel.)
    return AlertDialog(
      title: const Text("Set broadcast messages here 👇"),
      content: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
        SizedBox(
            width: 400.0,
            height: 400.0,
            child: TextField()),
        Row(
          children: [
            SizedBox(
                width: 50.0,
                child: TextField(
                    controller: broadcastDelayController,
                    decoration: InputDecoration(errorText: _broadcastDelayHasError ? "Wrong input" : null))),
            IconButton(
              onPressed: () {
                viewModel.addNewMessage();
              },
              icon: const Icon(Icons.add),
            )
          ],
        )
      ]),
      actions: [
        TextButton(
            onPressed: () async {
              if (false == viewModel.isSaveButtonEnabled) {
                return;
              }
              if (false == await viewModel.saveBroadcastDelay(broadcastDelayController.text)) {
                setState(() {
                  _broadcastDelayHasError = true;
                });
                return;
              }
              await viewModel.saveMessages();
              Navigator.of(context).pop();
            },
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
