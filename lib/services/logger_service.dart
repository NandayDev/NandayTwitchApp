import 'dart:collection';
import 'dart:ui';

import 'package:intl/date_symbol_data_file.dart';
import 'package:intl/intl.dart';
import 'package:logger/logger.dart';
import 'dart:io';

import 'package:path_provider/path_provider.dart';

abstract class LoggerService {

  void initializeFile();

  ///
  /// Logs a debug message
  ///
  void d(String message);

  ///
  /// Logs an info message
  ///
  void i(String message);

  ///
  /// Logs a warning message
  ///
  void w(String message);

  ///
  /// Logs an error message
  ///
  void e(String message);
}

class LoggerServiceImpl implements LoggerService {
  var logger = Logger(
    printer: PrettyPrinter(),
  );

  late File _logFile;
  final _dateFormat = DateFormat("yyyyMMdd", null);
  final _timeFormat = DateFormat.yMd().add_jm();

  final Queue<String> _logQueue = Queue();

  @override
  void initializeFile() async {
    var directory = await getApplicationDocumentsDirectory();
    _logFile = File("${directory.path}\\${_dateFormat.format(DateTime.now())}.log");

    await _writeToFile("-----------------------");

    while (true) {
      while (_logQueue.isNotEmpty) {
        String log = _logQueue.removeFirst();
        await _writeToFile(log);
      }
      await Future.delayed(const Duration(milliseconds: 500));
    }
  }

  @override
  void d(String message) {
    logger.d(message);
    _addToQueue("DEBUG", message);
  }

  @override
  void i(String message) {
    logger.i(message);
    _addToQueue("INFO", message);
  }

  @override
  void w(String message) {
    logger.w(message);
    _addToQueue("WARNING", message);
  }

  @override
  void e(String message) {
    logger.e(message);
    _addToQueue("ERROR", message);
  }

  void _addToQueue(String prefix, String message) {
    _logQueue.addLast("$prefix - ${_timeFormat.format(DateTime.now())} - $message");
  }

  Future _writeToFile(String logMessage) {
    return _logFile.writeAsString(logMessage + "\n", mode: FileMode.append);
  }
}
