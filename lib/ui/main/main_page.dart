import 'package:flutter/material.dart';
import 'package:nanday_twitch_app/services/nanday_dependency_injector.dart';
import 'package:nanday_twitch_app/ui/main/chat_message_view_model.dart';
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
            : Column(children: [
                viewModel.isLoadingLanguage
                    ? const CircularProgressIndicator()
                    : DropdownButton<String>(
                        value: viewModel.chosenLanguage,
                        icon: const Icon(Icons.arrow_downward),
                        elevation: 16,
                        style: const TextStyle(color: Colors.deepPurple),
                        underline: Container(
                          height: 2,
                          color: Colors.deepPurpleAccent,
                        ),
                        onChanged: (String? newValue) {
                          if (newValue != null) {
                            viewModel.setLanguage(newValue);
                          }
                        },
                        items: viewModel.languages.map<DropdownMenuItem<String>>((String value) {
                          String localizedString;
                          switch (value) {
                            case "it-IT":
                              localizedString = "Italian";
                              break;

                            case "en-US":
                              localizedString = "English (US)";
                              break;

                            case "en-UK":
                              localizedString = "English (UK)";
                              break;

                            default:
                              localizedString = value;
                              break;
                          }
                          return DropdownMenuItem<String>(
                            value: value,
                            child: Text(localizedString),
                          );
                        }).toList(),
                      ),
                Expanded(
                  child: chatMessages.isEmpty ? const Center(child: Text("No messages yet!", style: TextStyle(fontSize: 20.0),)) : ListView.builder(
                      padding: const EdgeInsets.all(8),
                      itemCount: chatMessages.length,
                      itemBuilder: (BuildContext context, int index) {
                        var chatMessage = chatMessages[index];
                        return ChangeNotifierProvider(
                          create: (context) => NandayDependencyInjector.instance
                              .resolve<ChatMessageViewModel>(additionalParameters: {ChatMessageViewModel.chatMessageParamName: chatMessage}),
                          child: ChatMessageWidget(chatMessage),
                        );
                      }),
                  // floatingActionButton: FloatingActionButton(
                  //   onPressed: _incrementCounter,
                  //   tooltip: 'Increment',
                  //   child: const Icon(Icons.add),
                  // ), // This trailing comma makes auto-formatting nicer for build methods.
                )
              ]));

    return Container();
  }
}
