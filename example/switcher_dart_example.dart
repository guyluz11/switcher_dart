import 'dart:collection';

import 'package:switcher_dart/switcher_dart.dart';

void main() {
  HashSet devicesId = HashSet();

  SwitcherDiscover.discover20002Devices().listen((switcherApiObject) {
    print('Found switcher 20002 device ${switcherApiObject.switcherName}');
    if (devicesId.contains(switcherApiObject.deviceId)) {
      return;
    }
    devicesId.add(switcherApiObject.deviceId);
    if (switcherApiObject is SwitcherOnOffAbstract) {
      switcherApiObject.turnOff();
    }
    if (switcherApiObject is SwitcherBreeze) {
      switcherApiObject.turnOff();
    }
  });
  SwitcherDiscover.discover20003Devices().listen((switcherApiObject) {
    print('Found switcher 20003 device ${switcherApiObject.switcherName}');
    if (devicesId.contains(switcherApiObject.deviceId)) {
      return;
    }
    devicesId.add(switcherApiObject.deviceId);
    if (switcherApiObject is SwitcherOnOffAbstract) {
      switcherApiObject.turnOff();
    }
    if (switcherApiObject is SwitcherBreeze) {
      switcherApiObject.turnOff();
    }
  });
}
