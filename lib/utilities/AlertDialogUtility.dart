import 'package:flutter/material.dart';

class AlertDialogUtility {
  ///
  /// Shows a simple text dialog with given text
  ///
  static void showTextDialog(BuildContext context, String text) {
    showDialog(
        context: context,
        barrierDismissible: false, // user must tap button!
        builder: (BuildContext context) {
          return AlertDialog(
            title: const Text('Authentication failed'),
            content: SingleChildScrollView(
              child: ListBody(
                children: [
                  Text(text),
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
  }
}
