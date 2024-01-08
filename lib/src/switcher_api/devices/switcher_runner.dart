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
    super.port = SwitcherApiObject.switcherTcpPort,
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
    this.deviceDirection = SwitcherDeviceDirection.cantGetState,
  });

  factory SwitcherRunner.fromHexSeparatedLetters({
    required List<String> hexSeparatedLetters,
    required String deviceId,
    required String switcherIp,
    required SwitcherDevicesTypes deviceType,
    required int port,
    required String switcherName,
    required String powerConsumption,
    required String macAddress,
    required String lastShutdownRemainingSecondsValue,
    required String remainingTimeForExecution,
  }) {
    final SwitcherDeviceDirection deviceDirection =
        SwitcherApiObject.extractSwitchDirection(hexSeparatedLetters);

    return SwitcherRunner(
      deviceType: deviceType,
      deviceId: deviceId,
      switcherIp: switcherIp,
      switcherName: switcherName,
      powerConsumption: powerConsumption,
      port: port,
      macAddress: macAddress,
      deviceDirection: deviceDirection,
      lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
      remainingTimeForExecution: remainingTimeForExecution,
    );
  }

  SwitcherDeviceDirection deviceDirection;

  /// Stops the blinds
  Future<void> stopBlinds() async {
    if (deviceType != SwitcherDevicesTypes.switcherRunner &&
        deviceType != SwitcherDevicesTypes.switcherRunnerMini) {
      logger.t('Stop blinds support only for blinds');
      return;
    }

    pSession = await _login2();
    if (pSession == 'B') {
      logger.e('Switcher run position command error');
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
      logger.t('Set position support only blinds');
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
    pSession = await _login2();
    if (pSession == 'B') {
      logger.e('Switcher run position command error');
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

  /// Used for sending the login packet to switcher runner.
  Future<String> _login2() async {
    // if (pSession != null) return pSession!;

    try {
      String data =
          'fef030000305a600${SwitcherApiObject.pSessionValue}ff0301000000$phoneId'
          '00000000${getTimeStamp()}00000000000000000000f0fe${deviceId}00';

      data = await crcSignFullPacketComKey(data, SwitcherApiObject.pKey);
      socket = await getSocket();
      if (socket == null) {
        throw 'Error';
      }

      socket!.add(hexStringToDecimalList(data));

      final Uint8List firstData = await socket!.first;

      final String resultSession = SwitcherApiObject.substrLikeInJavaScript(
          SwitcherApiObject.intListToHex(firstData).join(), 16, 8);

      return resultSession;
    } catch (error) {
      logger.e('login2 failed due to an error\n$error');
      pSession = 'B';
    }
    return pSession!;
  }
}
