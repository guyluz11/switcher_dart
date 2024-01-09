import 'dart:io';

import 'package:switcher_dart/src/switcher_api/switcher_api_object.dart';
import 'package:switcher_dart/src/utils.dart';

class SwitcherDiscover {
  static const switcherUdpPort = 20002;
  static const switcherUdpPort2 = 20003;

  static Stream<SwitcherApiObject> discover20002Devices() async* {
    try {
      final RawDatagramSocket socket20002 = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        switcherUdpPort,
      );

      await for (final _ in socket20002) {
        final Datagram? datagram = socket20002.receive();
        if (datagram == null) continue;
        try {
          final SwitcherApiObject switcherApiObject =
              SwitcherApiObject.createWithBytes(datagram);

          yield switcherApiObject;
        } catch (e) {
          loggerSwitcher.e(e);
        }
      }
    } catch (e) {
      loggerSwitcher.e('Switcher discover devices got and exception: $e');
    }
  }

  /// Blinds 20003 includes blinds for example
  static Stream<SwitcherApiObject> discover20003Devices() async* {
    try {
      final RawDatagramSocket socket20003 = await RawDatagramSocket.bind(
        InternetAddress.anyIPv4,
        switcherUdpPort2,
      );

      await for (final _ in socket20003) {
        final Datagram? datagram = socket20003.receive();
        if (datagram == null) continue;
        try {
          final SwitcherApiObject switcherApiObject =
              SwitcherApiObject.createWithBytes(datagram);

          yield switcherApiObject;
        } catch (e) {
          loggerSwitcher.e(e);
        }
      }
    } catch (e) {
      loggerSwitcher.e('Switcher discover devices got and exception: $e');
    }
  }
}
