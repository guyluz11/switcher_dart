import 'dart:typed_data';
import 'package:switcher_dart/src/switcher_api/devices/switcher_on_off_abstract.dart';
import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';

///  Switcher thermostat devices.
class SwitcherBreeze extends SwitcherOnOffAbstract {
  SwitcherBreeze({
    required super.deviceType,
    required super.deviceId,
    required super.switcherIp,
    required super.switcherName,
    required super.powerConsumption,
    required super.macAddress,
    required super.deviceState,
    required this.thermostatMode,
    required this.thermostatFanLevel,
    required this.thermostatSwing,
    required this.shutterPosition,
    required this.shutterDirection,
    required this.remoteId,
    required this.thermostatTemp,
    required this.thermostatTargetTemp,
    super.devicePass = '00000000',
    super.phoneId = '0000',
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
  }) : super(
          port: SwitcherApiObject.switcherTcpPort2,
        );

  factory SwitcherBreeze.fromHexSeparatedLetters({
    required Uint8List message,
    required String deviceId,
    required String switcherIp,
    required SwitcherDevicesTypes deviceType,
    required String switcherName,
    required int powerConsumption,
    required String macAddress,
    required String lastShutdownRemainingSecondsValue,
    required String remainingTimeForExecution,
    required SwitcherDeviceState deviceState,
  }) {
    String hexResponse = SwitcherApiObject.bytesToHex(message);

    SwitcherThermostatMode thermostatMode = getThermostatMode(hexResponse);
    double thermostatTemp = getThermostatTemp(hexResponse);
    int thermostatTargetTemp = getThermostatTargetTemp(hexResponse);
    SwitcherThermostatFanLevel thermostatFanLevel =
        getThermostatFanLevel(hexResponse);
    SwitcherThermostatSwing thermostatSwing = getThermostatSwing(hexResponse);
    int shutterPosition = getShutterPosition(hexResponse);
    SwitcherShutterDirection shutterDirection =
        getShutterDirection(hexResponse);
    String remoteId = getThermostatRemoteId(message);

    return SwitcherBreeze(
      deviceType: deviceType,
      deviceId: deviceId,
      switcherIp: switcherIp,
      switcherName: switcherName,
      powerConsumption: powerConsumption,
      macAddress: macAddress,
      lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
      remainingTimeForExecution: remainingTimeForExecution,
      thermostatMode: thermostatMode,
      thermostatTemp: thermostatTemp,
      thermostatTargetTemp: thermostatTargetTemp,
      thermostatFanLevel: thermostatFanLevel,
      thermostatSwing: thermostatSwing,
      shutterPosition: shutterPosition,
      shutterDirection: shutterDirection,
      remoteId: remoteId,
      deviceState: deviceState,
    );
  }

  final SwitcherThermostatMode thermostatMode;
  final SwitcherThermostatFanLevel thermostatFanLevel;
  final double thermostatTemp;
  final int thermostatTargetTemp;
  final SwitcherThermostatSwing thermostatSwing;
  final int shutterPosition;

  final SwitcherShutterDirection shutterDirection;
  final String remoteId;

  // /// The following are remote IDs (list provided by Switcher) which
  // /// behaves differently in commanding their swing.
  // /// with the following IDs, the swing is transmitted as a separate command.
  // List<String> specialSwingCommandRemoteIds() => [
  //       'ELEC7022',
  //       'ZM079055',
  //       'ZM079065',
  //       'ZM079049',
  //       // TODO: Check if this value should be twice
  //       'ZM079065',
  //     ];

  // @override
  // Future<void> turnOn({int duration = 0}) async {
  //   final String command =
  //       '${SwitcherOnOffAbstract.onValue}00${timerValue(duration)}';

  //   await runPowerCommand(command);
  // }

  // @override
  // Future<void> turnOff() async {
  //   pSession = await login2();
  //   IrRemote? irRemote = await getRemoteInfo(remoteId);
  //   if (irRemote == null) {
  //     loggerSwitcher.e('Can\'t be found, please check the code');
  //     return;
  //   }

  //   // TODO: incomplete 'RC72|21|32|26|4C|98|S|22|03|7272[22]|9014000080'

  //   final IRWave irWave =
  //       irRemote.irWaveList.firstWhere((element) => element.key == 'off');
  //   String command = "${irWave.para}|${irWave.hexCode}";

  //   // const String command = '00000000${SwitcherOnOffAbstract.offValue}0000000000';
  //   // String fullCommand = '00000000${'off'}0000000000';

  //   await runPowerCommand(command);
  // }

  /// format values are local session id, timestamp, device id, phone id, device-
  /// password, command length, command
  String breezeCommandPacket() =>
      "fef0000003050102${requestFormatBreeze()}{}${pad72Zeros()}3701{}{}";

  String requestFormatBreeze() =>
      "{}000001000000000000000000{}00000000000000000000f0fe";

  String pad72Zeros() => "0" * 72;

  @override
  Future<void> runPowerCommand(String commandType) async {
    pSession = await login();
    if (pSession == 'B') {
      return;
    }
    var data =
        'fef05d0002320102${pSession!}340001000000000000000000${getTimeStamp()}'
        '00000000000000000000f0fe${deviceId}00${phoneId}0000$devicePass'
        '000000000000000000000000000000000000000000000000000000000106000'
        '$commandType';

    data = await crcSignFullPacketComKey(data, SwitcherApiObject.pKey);

    socket = await getSocket();
    socket!.add(hexStringToDecimalList(data));
    await socket?.close();
    socket = null;
  }

  static SwitcherThermostatMode getThermostatMode(String hexResponse) {
    String hexMode = hexResponse.substring(158, 160);

    return SwitcherThermostatMode.values.firstWhere(
      (mode) => mode.value == hexMode,
      orElse: () => SwitcherThermostatMode.cool,
    );
  }

  static double getThermostatTemp(String hexResponse) {
    // Extract the relevant parts of the message and concatenate them
    String concatenatedHex =
        hexResponse.substring(154, 156) + hexResponse.substring(152, 154);

    // Convert to integer and then divide by 10 to get the temperature
    return int.parse(concatenatedHex, radix: 16) / 10.0;
  }

  static int getThermostatTargetTemp(String hexResponse) {
    // Convert the relevant part of the message to a hex string
    String hexTemp = hexResponse.substring(160, 162);

    // Convert hex string to integer
    return int.parse(hexTemp, radix: 16);
  }

  static SwitcherThermostatFanLevel getThermostatFanLevel(String hexResponse) {
    // Decode the relevant byte of the message
    String hexLevel = hexResponse.substring(162, 163);

    // Map the string to the corresponding enum value
    return SwitcherThermostatFanLevel.values.firstWhere(
      (level) => level.value == hexLevel,
      orElse: () =>
          SwitcherThermostatFanLevel.auto, // Provide a default case as needed
    );
  }

  static SwitcherThermostatSwing getThermostatSwing(String hexResponse) {
    String hexSwing = hexResponse.substring(163, 164);

    return SwitcherThermostatSwing.values.firstWhere(
      (swing) => swing.value == hexSwing,
      orElse: () =>
          SwitcherThermostatSwing.off, // Provide a default case as needed
    );
  }

  static String getThermostatRemoteId(Uint8List message)
      // TODO: Check if this ok to use it like this
      =>
      getStringFromUint8List(message, 143, 8);

  static String getStringFromUint8List(Uint8List list, int start, int length) {
    // Ensure the start and length are within the bounds of the list
    if (start < 0 || length < 0 || start + length > list.length) {
      return ''; // Return an empty string if the range is invalid
    }

    return String.fromCharCodes(list.sublist(start, start + length));
  }

  static int getShutterPosition(String hexResponse) =>
      int.parse(hexResponse.substring(152, 154), radix: 16);

  static SwitcherShutterDirection getShutterDirection(String hexResponse) {
    String hexDir = hexResponse.substring(156, 160);
    return SwitcherShutterDirection.values.firstWhere(
      (direction) => direction.value == hexDir,
      orElse: () =>
          SwitcherShutterDirection.stop, // Provide a default case as needed
    );
  }
}

/// Enum class representing the thermostat device's position.
enum SwitcherThermostatMode {
  auto, // "01", "auto"
  dry, // "02", "dry"
  fan, // "03", "fan"
  cool, // "04", "cool"
  heat, // "05", "heat"
}

extension ThermostatModeExtension on SwitcherThermostatMode {
  String get value {
    switch (this) {
      case SwitcherThermostatMode.auto:
        return "01";
      case SwitcherThermostatMode.dry:
        return "02";
      case SwitcherThermostatMode.fan:
        return "03";
      case SwitcherThermostatMode.cool:
        return "04";
      case SwitcherThermostatMode.heat:
        return "05";
      default:
        return "";
    }
  }
}

/// Enum class representing the thermostat device's fan level.
enum SwitcherThermostatFanLevel {
  low, // "1", "low"
  medium, // "2", "medium"
  high, // "3", "high"
  auto, // "0", "auto"
}

extension ThermostatFanLevelExtension on SwitcherThermostatFanLevel {
  String get value {
    switch (this) {
      case SwitcherThermostatFanLevel.low:
        return "1";
      case SwitcherThermostatFanLevel.medium:
        return "2";
      case SwitcherThermostatFanLevel.high:
        return "3";
      case SwitcherThermostatFanLevel.auto:
        return "0";
      default:
        return "";
    }
  }
}

/// Enum class representing the thermostat device's swing state.
enum SwitcherThermostatSwing {
  off, // "0", "off"
  on, // "1", "on"
}

extension ThermostatSwingExtension on SwitcherThermostatSwing {
  String get value {
    switch (this) {
      case SwitcherThermostatSwing.off:
        return "0";
      case SwitcherThermostatSwing.on:
        return "1";
      default:
        return "";
    }
  }
}

/// Enum class representing the shutter device's position.
enum SwitcherShutterDirection {
  stop, // "0000", "stop"
  up, // "0100", "up"
  down, // "0001", "down"
}

extension ShutterDirectionExtension on SwitcherShutterDirection {
  String get value {
    switch (this) {
      case SwitcherShutterDirection.stop:
        return "0000";
      case SwitcherShutterDirection.up:
        return "0100";
      case SwitcherShutterDirection.down:
        return "0001";
      default:
        return "";
    }
  }
}
