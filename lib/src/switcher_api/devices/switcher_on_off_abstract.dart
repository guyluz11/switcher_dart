import 'dart:convert';
import 'dart:typed_data';

import 'package:switcher_dart/src/switcher_api/devices/breeze/switcher_breeze.dart';
import 'package:switcher_dart/src/switcher_api/devices/switcher_water_heater.dart';
import 'package:switcher_dart/src/switcher_api/devices/switcher_power_plug.dart';
import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';
import 'package:switcher_dart/src/utils.dart';

abstract class SwitcherOnOffAbstract extends SwitcherApiObject {
  SwitcherOnOffAbstract({
    required super.deviceType,
    required super.deviceId,
    required super.switcherIp,
    required super.switcherName,
    required super.powerConsumption,
    required super.macAddress,
    required this.deviceState,
    super.devicePass = '00000000',
    super.phoneId = '0000',
    super.port = SwitcherApiObject.switcherTcpPort,
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
  });

  factory SwitcherOnOffAbstract.fromHexSeparatedLetters({
    required String deviceId,
    required String switcherIp,
    required SwitcherDevicesTypes type,
    required String switcherName,
    required int powerConsumption,
    required String macAddress,
    required String lastShutdownRemainingSecondsValue,
    required String remainingTimeForExecution,
    required Uint8List message,
  }) {
    final SwitcherDeviceState deviceState = getThermostatState(message);
    switch (type) {
      case SwitcherDevicesTypes.notRecognized:
        throw 'Unrecognized switcher device';
      case SwitcherDevicesTypes.switcherPowerPlug:
        return SwitcherPowerPlug(
          deviceType: type,
          deviceId: deviceId,
          switcherIp: switcherIp,
          switcherName: switcherName,
          powerConsumption: powerConsumption,
          macAddress: macAddress,
          deviceState: deviceState,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
        );
      case SwitcherDevicesTypes.switcherMini:
      case SwitcherDevicesTypes.switcherTouch:
      case SwitcherDevicesTypes.switcherV2Esp:
      case SwitcherDevicesTypes.switcherV2qualcomm:
      case SwitcherDevicesTypes.switcherV4:
        return SwitcherWaterHeater(
          deviceType: type,
          deviceId: deviceId,
          switcherIp: switcherIp,
          switcherName: switcherName,
          powerConsumption: powerConsumption,
          macAddress: macAddress,
          deviceState: deviceState,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
        );
      case SwitcherDevicesTypes.switcherBreeze:
        return SwitcherBreeze.fromHexSeparatedLetters(
          message: message,
          deviceType: type,
          deviceId: deviceId,
          switcherIp: switcherIp,
          switcherName: switcherName,
          macAddress: macAddress,
          powerConsumption: powerConsumption,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
          deviceState: deviceState,
        );
      default:
    }
    throw 'Switcher device does not exists for SwitcherOnOffAbstract name $switcherName type:$type id $deviceId ip $switcherIp ';
  }

  SwitcherDeviceState deviceState;

  static const offValue = '0';
  static const onValue = '1';

  static SwitcherDeviceState getThermostatState(Uint8List message) {
    String hexPower = ascii.decode(message.sublist(156, 158));
    return hexPower == SwitcherDeviceState.off.value
        ? SwitcherDeviceState.off
        : SwitcherDeviceState.on;
  }

  // static SwitcherDeviceState extractSwitchState(
  //   List<String> hexSeparatedLetters,
  // ) {
  //   SwitcherDeviceState switcherDeviceState = SwitcherDeviceState.cantGetState;

  //   final String hexModel = SwitcherApiObject.substrLikeInJavaScript(
  //       hexSeparatedLetters.join(), 266, 4);

  //   if (hexModel == '0100') {
  //     switcherDeviceState = SwitcherDeviceState.on;
  //   } else if (hexModel == '0000') {
  //     switcherDeviceState = SwitcherDeviceState.off;
  //   } else {
  //     loggerSwitcher.w('Switcher state is not recognized: $hexModel');
  //   }
  //   return switcherDeviceState;
  // }

  Future<void> turnOn({int duration = 0}) async {
    final String offCommand = '${onValue}00${timerValue(duration)}';

    await runPowerCommand(offCommand);
  }

  Future<void> turnOff() async {
    const String offCommand = '${offValue}0000000000';
    await runPowerCommand(offCommand);
  }

  Future<void> runPowerCommand(String commandType) async {
    pSession = await login();
    if (pSession == 'B') {
      loggerSwitcher.e('Switcher run power command error');
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
}
