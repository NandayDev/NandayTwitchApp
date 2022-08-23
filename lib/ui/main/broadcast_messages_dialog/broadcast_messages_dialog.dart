import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/ui/main/broadcast_messages_dialog/broadcast_messages_view_model.dart';
import 'package:provider/provider.dart';

class BroadcastMessagesDialog extends StatefulWidget {
  const BroadcastMessagesDialog({Key? key}) : super(key: key);

  @override
  State<BroadcastMessagesDialog> createState() => _BroadcastMessagesDialogState();
}

class _BroadcastMessagesDialogState extends State<BroadcastMessagesDialog> {
  @override
  void initState() {
    super.initState();
    BroadcastMessagesViewModel viewModel = Provider.of<BroadcastMessagesViewModel>(context, listen: false);
    viewModel.loadMessages();
  }

  @override
  Widget build(BuildContext context) {
    BroadcastMessagesViewModel viewModel = Provider.of<BroadcastMessagesViewModel>(context);
    var messages = viewModel.messages;
    return AlertDialog(
      title: const Text("Set broadcast messages here"),
      content: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : Column(children: [
              SizedBox(
                  width: 400.0,
                  height: 400.0,
                  child: ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: messages.length,
                      itemBuilder: (BuildContext context, int index) {
                        var message = messages[index];
                        var textController = TextEditingController(text: message);
                        textController.addListener(() {
                          viewModel.messageEditedAtIndex(index, textController.text);
                        });
                        return Row(children: [
                          Expanded(child: TextField(controller: textController)),
                          IconButton(
                              onPressed: () {
                                viewModel.messageDeletedAtIndex(index);
                              },
                              icon: const Icon(Icons.delete))
                        ]);
                      })),
              Align(
                  alignment: Alignment.centerRight,
                  child: IconButton(
                    onPressed: () {
                      viewModel.addNewMessage();
                    },
                    icon: const Icon(Icons.add),
                  ))
            ]),
      actions: [
        TextButton(
            onPressed: () async {
              if (false == viewModel.isSaveButtonEnabled) {
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
