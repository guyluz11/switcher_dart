import 'package:switcher_dart/switcher_dart.dart';

void main() {
  SwitcherDiscover.discover20002Devices().listen((switcherApiObject) {
    print('Found switcher 20002 device ${switcherApiObject.switcherName}');
  });
  SwitcherDiscover.discover20003Devices().listen((switcherApiObject) {
    print('Found switcher 20003 device ${switcherApiObject.switcherName}');
  });
}
