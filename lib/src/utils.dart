import 'package:logger/logger.dart';

/// Instance of logger for all the app
final loggerSwitcher = Logger(
  filter: ProductionFilter(),
  printer: PrettyPrinter(methodCount: 0, printTime: true),
);
