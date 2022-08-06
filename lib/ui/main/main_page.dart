import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/ui/main/chat_message_widget.dart';
import 'package:nanday_twitch_app/ui/main/main_page_view_model.dart';
import 'package:provider/provider.dart';

class MainPage extends StatefulWidget {
  const MainPage({Key? key}) : super(key: key);

  @override
  State<MainPage> createState() => _MainPageState();
}

class _MainPageState extends State<MainPage> {
  @override
  void initState() {
    super.initState();
    final viewModel = Provider.of<MainPageViewModel>(context, listen: false);
    viewModel.initialize();
  }

  @override
  Widget build(BuildContext context) {
    final viewModel = Provider.of<MainPageViewModel>(context);
    final chatMessages = viewModel.chatMessages.toList();
    return Scaffold(
      appBar: AppBar(
        title: const Text("Home"),
      ),
      body: viewModel.isLoading
          ? const Center(child: CircularProgressIndicator())
          : ListView.builder(
              padding: const EdgeInsets.all(8),
              itemCount: chatMessages.length,
              itemBuilder: (BuildContext context, int index) {
                var chatMessage = chatMessages[index];
                return ChatMessageWidget(chatMessage);
              }),
      // floatingActionButton: FloatingActionButton(
      //   onPressed: _incrementCounter,
      //   tooltip: 'Increment',
      //   child: const Icon(Icons.add),
      // ), // This trailing comma makes auto-formatting nicer for build methods.
    );

    return Container();
  }
}
