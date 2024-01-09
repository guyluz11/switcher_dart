import 'dart:typed_data';

import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';
import 'package:switcher_dart/src/utils.dart';

class SwitcherRunner extends SwitcherApiObject {
  SwitcherRunner({
    required super.deviceType,
    required super.deviceId,
    required super.switcherIp,
    required super.switcherName,
    required super.powerConsumption,
    required super.macAddress,
    super.devicePass = '00000000',
    super.phoneId = '0000',
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
    this.deviceDirection = SwitcherDeviceDirection.cantGetState,
    required this.shutterPosition,
  }) : super(
          port: SwitcherApiObject.switcherTcpPort2,
        );

  factory SwitcherRunner.fromHexSeparatedLetters({
    required Uint8List message,
    required String deviceId,
    required String switcherIp,
    required SwitcherDevicesTypes deviceType,
    required String switcherName,
    required int powerConsumption,
    required String macAddress,
    required String lastShutdownRemainingSecondsValue,
    required String remainingTimeForExecution,
  }) {
    final SwitcherDeviceDirection deviceDirection =
        getShutterDirection(message);

    int shutterPosition = getShutterPosition(message);

    return SwitcherRunner(
      deviceType: deviceType,
      deviceId: deviceId,
      switcherIp: switcherIp,
      switcherName: switcherName,
      powerConsumption: powerConsumption,
      shutterPosition: shutterPosition,
      macAddress: macAddress,
      deviceDirection: deviceDirection,
      lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
      remainingTimeForExecution: remainingTimeForExecution,
    );
  }

  final SwitcherDeviceDirection deviceDirection;
  final int shutterPosition;

  /// Stops the blinds
  Future<void> stopBlinds() async {
    if (deviceType != SwitcherDevicesTypes.switcherRunner &&
        deviceType != SwitcherDevicesTypes.switcherRunnerMini) {
      loggerSwitcher.t('Stop blinds support only for blinds');
      return;
    }

    pSession = await login2();
    if (pSession == 'B') {
      loggerSwitcher.e('Switcher run position command error');
      return;
    }
    var data =
        'fef0590003050102${pSession!}232301000000000000000000${getTimeStamp()}'
        '00000000000000000000f0fe${deviceId}00${phoneId}0000$devicePass'
        '000000000000000000000000000000000000000000000000000000370202000000';

    data = await crcSignFullPacketComKey(data, SwitcherApiObject.pKey);

    socket = await getSocket();
    socket!.add(hexStringToDecimalList(data));
    await socket?.close();
    socket = null;
  }

  /// Sets the position of the blinds, 0 is down 100 is up
  Future<void> setPosition({int pos = 0}) async {
    if (deviceType != SwitcherDevicesTypes.switcherRunner &&
        deviceType != SwitcherDevicesTypes.switcherRunnerMini) {
      loggerSwitcher.t('Set position support only blinds');
      return;
    }

    final String positionCommand = _getHexPos(pos: pos);
    _runPositionCommand(positionCommand);
  }

  String _getHexPos({int pos = 0}) {
    String posAsHex = SwitcherApiObject.intListToHex([pos]).join();
    if (posAsHex.length < 2) {
      posAsHex = '0$posAsHex';
    }
    return posAsHex;
  }

  Future<void> _runPositionCommand(String positionCommand) async {
    // final int pos = int.parse(positionCommand, radix: 16);
    pSession = await login2();
    if (pSession == 'B') {
      loggerSwitcher.e('Switcher run position command error');
      return;
    }
    var data =
        'fef0580003050102${pSession!}290401000000000000000000${getTimeStamp()}'
        '00000000000000000000f0fe${deviceId}00${phoneId}0000$devicePass'
        '00000000000000000000000000000000000000000000000000000037010100'
        '$positionCommand';

    data = await crcSignFullPacketComKey(data, SwitcherApiObject.pKey);

    socket = await getSocket();
    socket!.add(hexStringToDecimalList(data));
    await socket?.close();
    socket = null;
  }

  static int getShutterPosition(Uint8List message) {
    final String hexModel =
        SwitcherApiObject.bytesToHex(message.sublist(135, 137));
    return int.parse(hexModel.substring(2, 4)) +
        int.parse(hexModel.substring(0, 2), radix: 16);
  }

  static SwitcherDeviceDirection getShutterDirection(Uint8List message) {
    // Convert the relevant part of the message to a hex string
    String hexDirection =
        SwitcherApiObject.bytesToHex(message.sublist(137, 139));

    // Map the hex string to the corresponding enum value
    return SwitcherShutterDirectionExtension.fromValue(hexDirection);
  }
}

enum SwitcherDeviceDirection {
  cantGetState,
  stop, // '0000'
  up, // '0100'
  down, // '0001'
}

extension SwitcherShutterDirectionExtension on SwitcherDeviceDirection {
  String get value {
    switch (this) {
      case SwitcherDeviceDirection.stop:
        return "0000";
      case SwitcherDeviceDirection.up:
        return "0100";
      case SwitcherDeviceDirection.down:
        return "0001";
      default:
        return "";
    }
  }

  static SwitcherDeviceDirection fromValue(String value) {
    switch (value) {
      case "0000":
        return SwitcherDeviceDirection.stop;
      case "0100":
        return SwitcherDeviceDirection.up;
      case "0001":
        return SwitcherDeviceDirection.down;
      default:
        throw FormatException('Unknown shutter direction value: $value');
    }
  }
}
