import 'package:switcher_dart/src/switcher_api/devices/switcher_water_heater.dart';
import 'package:switcher_dart/src/switcher_api/devices/switcher_water_power_plug.dart';
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
    super.devicePass = '00000000',
    super.phoneId = '0000',
    super.port = SwitcherApiObject.switcherTcpPort,
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
    this.deviceState = SwitcherDeviceState.cantGetState,
  });

  factory SwitcherOnOffAbstract.fromHexSeparatedLetters({
    required List<String> hexSeparatedLetters,
    required String deviceId,
    required String switcherIp,
    required SwitcherDevicesTypes type,
    required int port,
    required String switcherName,
    required String powerConsumption,
    required String macAddress,
    required String lastShutdownRemainingSecondsValue,
    required String remainingTimeForExecution,
  }) {
    final SwitcherDeviceState deviceState =
        extractSwitchState(hexSeparatedLetters);
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
          port: port,
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
          port: port,
          macAddress: macAddress,
          deviceState: deviceState,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
        );
      default:
    }
    throw 'Switcher device does not exists for SwitcherOnOffAbstract name $switcherName type:$type id $deviceId ip $switcherIp ';
  }

  SwitcherDeviceState deviceState;

  static const offValue = '0';
  static const onValue = '1';

  static SwitcherDeviceState extractSwitchState(
    List<String> hexSeparatedLetters,
  ) {
    SwitcherDeviceState switcherDeviceState = SwitcherDeviceState.cantGetState;

    final String hexModel = SwitcherApiObject.substrLikeInJavaScript(
        hexSeparatedLetters.join(), 266, 4);

    if (hexModel == '0100') {
      switcherDeviceState = SwitcherDeviceState.on;
    } else if (hexModel == '0000') {
      switcherDeviceState = SwitcherDeviceState.off;
    } else {
      logger.w('Switcher state is not recognized: $hexModel');
    }
    return switcherDeviceState;
  }

  Future<void> turnOn({int duration = 0}) async {
    final String offCommand = '${onValue}00${timerValue(duration)}';

    await _runPowerCommand(offCommand);
  }

  Future<void> turnOff() async {
    const String offCommand = '${offValue}0000000000';
    await _runPowerCommand(offCommand);
  }

  Future<void> _runPowerCommand(String commandType) async {
    pSession = await login();
    if (pSession == 'B') {
      logger.e('Switcher run power command error');
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
