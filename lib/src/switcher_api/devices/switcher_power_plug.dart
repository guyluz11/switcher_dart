import 'package:switcher_dart/src/switcher_api/devices/switcher_on_off_abstract.dart';
import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';

class SwitcherPowerPlug extends SwitcherOnOffAbstract {
  SwitcherPowerPlug({
    required super.deviceType,
    required super.deviceId,
    required super.switcherIp,
    required super.switcherName,
    required super.powerConsumption,
    required super.macAddress,
    required super.deviceState,
    super.devicePass = '00000000',
    super.phoneId = '0000',
    super.statusSocket,
    super.lastShutdownRemainingSecondsValue,
    super.remainingTimeForExecution,
    super.log,
  }) : super(
          port: SwitcherApiObject.switcherTcpPort,
        );
}
