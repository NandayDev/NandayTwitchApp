import 'package:logger/logger.dart';

abstract class LoggerService {
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

  @override
  void d(String message) {
    logger.d(message);
  }

  @override
  void i(String message) {
    logger.i(message);
  }

  @override
  void w(String message) {
    logger.w(message);
  }

  @override
  void e(String message) {
    logger.e(message);
  }
}
