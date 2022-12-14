import 'package:file_picker/file_picker.dart';
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
  late TextEditingController _botUsernameTextController;
  late TextEditingController _channelNameTextController;

  @override
  void initState() {
    super.initState();
    ProfileDialogViewModel viewModel = Provider.of<ProfileDialogViewModel>(context, listen: false);
    _botUsernameTextController = TextEditingController(text: viewModel.botUsername);
    _channelNameTextController = TextEditingController(text: viewModel.channelName);
  }

  @override
  Widget build(BuildContext context) {
    ProfileDialogViewModel viewModel = Provider.of<ProfileDialogViewModel>(context);
    bool? profileSavedSuccessfully = viewModel.profileSavedSuccessfully;
    if (profileSavedSuccessfully != null) {
      Future.delayed(const Duration(milliseconds: 250)).then((value) {
        switch (profileSavedSuccessfully) {
          case true:
            Navigator.of(context).pop();
            return Container();

          case false:
            AlertDialogUtility.showTextDialog(context, "Profile couldn't be saved. Please try again.");
            break;
        }
      });
    }
    return AlertDialog(
      title: Text(widget.profile == null ? "Create new profile" : "Edit profile"),
      content: Column(mainAxisSize: MainAxisSize.min, children: [
        const SizedBox(
          width: 400,
          height: 0,
        ),
        Row(
          children: [
            const Text("Bot username *"),
            const SizedBox(
              width: 20,
            ),
            SizedBox(
                width: 250.0,
                child: TextField(
                  controller: _botUsernameTextController,
                  onChanged: (newText) {
                    viewModel.botUsername = newText;
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
                  controller: _channelNameTextController,
                  onChanged: (newText) {
                    viewModel.channelName = newText;
                  },
                ))
          ],
        ),
        const SizedBox(
          height: 20,
        ),
        Row(children: [
          const Text("Browser executable"),
          const SizedBox(
            width: 20,
          ),
          MaterialButton(
              color: const Color(0xEEEEEEEE),
              child: const Text("..."),
              onPressed: () async {
                var result = await FilePicker.platform.pickFiles();
                if (result?.files.isNotEmpty == true) {
                  viewModel.browserExecutablePath = result!.files[0].path;
                }
              }),
          const SizedBox(
            width: 20,
          ),
          Text(viewModel.browserExecutablePath ?? "")
        ]),
        const SizedBox(
          height: 20,
        ),
        Row(children: [
          const Text("Bot language"),
          const SizedBox(
            width: 20,
          ),
          DropdownButton<String>(
              value: viewModel.selectedBotLanguage,
              items: viewModel.botLanguages.map((e) {
                return DropdownMenuItem<String>(value: e, child: Text(e));
              }).toList(),
              icon: const Icon(Icons.arrow_downward),
              elevation: 16,
              style: const TextStyle(fontSize: 20, color: Colors.black87),
              underline: Container(
                height: 2,
                color: Theme.of(context).primaryColor,
              ),
              onChanged: (e) {
                viewModel.selectedBotLanguage = e;
              })
        ])
      ]),
      actions: [
        TextButton(
            onPressed: viewModel.isLoading
                ? null
                : viewModel.isSaveButtonEnabled
                    ? viewModel.saveProfile
                    : null,
            child: viewModel.isLoading ? const CircularProgressIndicator() : const Text("Save")),
        TextButton(
            onPressed: viewModel.isLoading
                ? null
                : () {
                    Navigator.of(context).pop();
                  },
            child: const Text("Cancel"))
      ],
    );
  }
}
