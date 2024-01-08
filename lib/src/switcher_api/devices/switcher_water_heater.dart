import 'package:switcher_dart/src/switcher_api/devices/switcher_on_off_abstract.dart';
import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';

class SwitcherWaterHeater extends SwitcherOnOffAbstract {
  SwitcherWaterHeater({
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
    super.deviceState = SwitcherDeviceState.cantGetState,
  });
}
