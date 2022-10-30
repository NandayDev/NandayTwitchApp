import 'package:flutter/material.dart';

abstract class NandayViewModel extends ChangeNotifier {
  void notifyPropertyChanged(Function? stateChangingFunction) {
    stateChangingFunction?.call();
    notifyListeners();
  }

  void notifyPropertyChangedAsync(Future Function() stateChangingFunction) async {
    await stateChangingFunction();
    notifyListeners();
  }
}
