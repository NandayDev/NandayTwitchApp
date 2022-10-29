import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/ui/main/online_message_dialog/online_message_dialog_view_model.dart';
import 'package:provider/provider.dart';

class OnlineMessageDialog extends StatefulWidget {
  const OnlineMessageDialog({Key? key}) : super(key: key);

  @override
  State<OnlineMessageDialog> createState() => _OnlineMessageDialogState();
}

class _OnlineMessageDialogState extends State<OnlineMessageDialog> {
  @override
  void initState() {
    super.initState();
    OnlineMessageDialogViewModel viewModel = Provider.of<OnlineMessageDialogViewModel>(context, listen: false);
    viewModel.loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    OnlineMessageDialogViewModel viewModel = Provider.of<OnlineMessageDialogViewModel>(context);
    final goesOnlineMessageController = TextEditingController(text: viewModel.goesOnlineMessage);
    goesOnlineMessageController.addListener(() {
      viewModel.goesOnlineMessage = goesOnlineMessageController.text;
    });
    final goesOfflineMessageController = TextEditingController(text: viewModel.goesOfflineMessage);
    goesOfflineMessageController.addListener(() {
      viewModel.goesOfflineMessage = goesOfflineMessageController.text;
    });

    return AlertDialog(
      title: const Text("Discord online/offline messages"),
      content: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              SizedBox(
                  width: 400.0,
                  height: 400.0,
                  child: Column(
                    children: [
                      Row(children: [Expanded(child: TextField(controller: goesOnlineMessageController))]),
                      Row(children: [Expanded(child: TextField(controller: goesOfflineMessageController))])
                    ],
                  )),
            ]),
      actions: [
        TextButton(
            onPressed: () async {
              if (false == await viewModel.saveMessages()) {
                setState(() {});
                return;
              }
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
