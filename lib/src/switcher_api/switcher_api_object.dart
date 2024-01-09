import 'dart:convert';
import 'dart:io';
import 'dart:typed_data';

import 'package:crclib/crclib.dart';
import 'package:switcher_dart/src/switcher_api/devices/switcher_on_off_abstract.dart';
import 'package:switcher_dart/src/switcher_api/devices/switcher_runner.dart';
import 'package:switcher_dart/src/utils.dart';

abstract class SwitcherApiObject {
  SwitcherApiObject({
    required this.deviceType,
    required this.deviceId,
    required this.switcherIp,
    required this.switcherName,
    required this.powerConsumption,
    required this.macAddress,
    this.devicePass = '00000000',
    this.phoneId = '0000',
    this.port = switcherTcpPort,
    this.statusSocket,
    this.lastShutdownRemainingSecondsValue,
    this.remainingTimeForExecution,
    this.log,
  });

  factory SwitcherApiObject.createWithBytes(Datagram datagram) {
    final Uint8List message = datagram.data;

    if (!isSwitcherOriginator(message)) {
      loggerSwitcher.w('Not a switcher message arrived to here');
    }

    final SwitcherDevicesTypes type = getDeviceType(message);
    final String deviceId = extractDeviceId(message);

    final String switcherIp = datagram.address.address;
    final String switcherMac = getMac(message);
    final int powerConsumption = extractPowerConsumption(message);

    final String switcherName = extractDeviceName(message);

    final String remainingTimeForExecution = getRemaining(message);
    final String lastShutdownRemainingSecondsValue = getAutoShutdown(message);

    switch (type) {
      case SwitcherDevicesTypes.switcherMini:
      case SwitcherDevicesTypes.switcherPowerPlug:
      case SwitcherDevicesTypes.switcherTouch:
      case SwitcherDevicesTypes.switcherV2Esp:
      case SwitcherDevicesTypes.switcherV2qualcomm:
      case SwitcherDevicesTypes.switcherV4:
      case SwitcherDevicesTypes.switcherBreeze:
        return SwitcherOnOffAbstract.fromHexSeparatedLetters(
          type: type,
          deviceId: deviceId,
          switcherIp: switcherIp,
          switcherName: switcherName,
          macAddress: switcherMac,
          powerConsumption: powerConsumption,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
          message: message,
        );

      case SwitcherDevicesTypes.switcherRunner:
      case SwitcherDevicesTypes.switcherRunnerMini:
        return SwitcherRunner.fromHexSeparatedLetters(
          message: message,
          deviceType: type,
          deviceId: deviceId,
          switcherIp: switcherIp,
          switcherName: switcherName,
          macAddress: switcherMac,
          powerConsumption: powerConsumption,
          lastShutdownRemainingSecondsValue: lastShutdownRemainingSecondsValue,
          remainingTimeForExecution: remainingTimeForExecution,
        );
      case SwitcherDevicesTypes.notRecognized:
    }

    throw 'Switcher device type isn\'t supported name $switcherName id $deviceId ip $switcherIp ';
  }

  String deviceId;
  String switcherIp;
  SwitcherDevicesTypes deviceType;
  int port;
  String switcherName;
  String phoneId;
  int powerConsumption;
  String devicePass;
  String macAddress;
  String? remainingTimeForExecution;
  String? log;
  String? statusSocket;
  String? lastShutdownRemainingSecondsValue;

  Socket? socket;

  String? pSession;

  static const switcherTcpPort = 9957;
  static const switcherTcpPort2 = 10000;

  static const pSessionValue = '00000000';
  static const pKey = '00000000000000000000000000000000';

  static const statusEvent = 'status';
  static const readyEvent = 'ready';
  static const errorEvent = 'error';
  static const stateChangedEvent = 'state';

  static const switcherUdpIp = '0.0.0.0';
  static const switcherUdpPort = 20002;

  static bool isSwitcherOriginator(Uint8List message) {
    // Convert the start of the message to a hex string
    String hexStart = bytesToHex(message.sublist(0, 2));

    // Check if the hex string matches the specific value and length conditions
    return hexStart == "fef0" &&
        (message.length == 165 ||
            message.length == 168 ||
            message.length == 159);
  }

  // Helper method to convert bytes to hex string
  static String bytesToHex(Uint8List bytes) =>
      bytes.map((byte) => byte.toRadixString(16).padLeft(2, '0')).join();

  static SwitcherDevicesTypes getDeviceType(Uint8List message) {
    String hexModel = bytesToHex(message.sublist(74, 76));
    return SwitcherDevicesTypes.values.firstWhere(
      (type) => type.hexRep == hexModel,
      orElse: () => SwitcherDevicesTypes.switcherMini, // Define a default case
    );
  }

  /// Used for sending actions to the device
  void sendState({required SwitcherDeviceState command, int minutes = 0}) {
    _getFullState();
  }

  /// Used for sending the get state packet to the device.
  /// Returns a tuple of hex timestamp,
  /// session id and an instance of SwitcherStateResponse
  Future<String> _getFullState() async {
    return login();
  }

  /// Used for sending the login packet to the device.
  Future<String> login() async {
    try {
      String data = 'fef052000232a100${pSessionValue}340001000000000000000000'
          '${getTimeStamp()}00000000000000000000f0fe1c00${phoneId}0000'
          '$devicePass'
          '00000000000000000000000000000000000000000000000000000000';

      data = await crcSignFullPacketComKey(data, pKey);
      socket = await getSocket();
      if (socket == null) {
        throw 'Error';
      }

      socket!.add(hexStringToDecimalList(data));

      final Uint8List firstData = await socket!.first;
      final String resultSession =
          substrLikeInJavaScript(intListToHex(firstData).join(), 16, 8);

      return resultSession;
    } catch (error) {
      loggerSwitcher.e('Switcher login failed due to an error\n$error');
      pSession = 'B';
    }
    return pSession!;
  }

  /// Used for sending the login packet to switcher runner.
  Future<String> login2() async {
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
      loggerSwitcher.e('login2 failed due to an error\n$error');
      pSession = 'B';
    }
    return pSession!;
  }

  Future<String> crcSignFullPacketComKey(
    String pData,
    String pKey,
  ) async {
    String pDataTemp = pData;
    final List<int> bufferHex = hexStringToDecimalList(pDataTemp);

    String crc = intListToHex(
      packBigEndian(
        int.parse(Crc16XmodemWith0x1021().convert(bufferHex).toString()),
      ),
    ).join();

    pDataTemp = pDataTemp +
        substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2);

    crc = substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2) +
        getUtf8Encoded(pKey);

    crc = intListToHex(
      packBigEndian(
        int.parse(
          Crc16XmodemWith0x1021()
              .convert(hexStringToDecimalList(crc))
              .toString(),
        ),
      ),
    ).join();

    return pDataTemp +
        substrLikeInJavaScript(crc, 6, 2) +
        substrLikeInJavaScript(crc, 4, 2);
  }

  String getTimeStamp() {
    final int timeInSeconds = DateTime.now().millisecondsSinceEpoch ~/ 1000;

    final List<int> timeInBytes = packLittleEndian(timeInSeconds);

    return intListToHex(timeInBytes).join();
  }

  /// Same as Buffer.from(value, 'hex') in JavaScript
  List<int> hexStringToDecimalList(String hex) {
    final List<int> decimalIntList = [];
    String twoNumbers = '';

    for (int i = 0; i < hex.length; i++) {
      if (twoNumbers == '') {
        twoNumbers = twoNumbers + hex[i];
        continue;
      } else {
        twoNumbers = twoNumbers + hex[i];
        decimalIntList.add(int.parse(twoNumbers, radix: 16));
        twoNumbers = '';
      }
    }
    return decimalIntList;
  }

  /// Convert number to unsigned integer as little-endian sequence of bytes
  /// Same as struct.pack('<I', value) in JavaScript
  static List<int> packLittleEndian(int valueToConvert) {
    final ByteData sendValueBytes = ByteData(8);

    try {
      sendValueBytes.setUint64(0, valueToConvert, Endian.little);
    } on Exception {
      sendValueBytes.setUint32(0, valueToConvert, Endian.little);
    }

    final Uint8List timeInBytes = sendValueBytes.buffer.asUint8List();
    return timeInBytes.sublist(0, timeInBytes.length - 4);
  }

  /// Convert number to unsigned integer as big-endian sequence of bytes
  /// Same as struct.pack('>I', value) in JavaScript
  static List<int> packBigEndian(int valueToConvert) {
    final ByteData sendValueBytes = ByteData(8);

    try {
      sendValueBytes.setUint64(0, valueToConvert);
    } on Exception {
      sendValueBytes.setUint32(0, valueToConvert);
    }

    final Uint8List timeInBytes = sendValueBytes.buffer.asUint8List();
    return timeInBytes.sublist(4);
  }

  /// Convert list of bytes/integers into their hex 16 value with padding 2 of 0
  /// Same as .toString('hex'); in JavaScript
  static List<String> intListToHex(List<int> bytes) {
    final List<String> messageBuffer = [];

    for (final int unit8 in bytes) {
      messageBuffer.add(unit8.toRadixString(16).padLeft(2, '0'));
    }
    return messageBuffer;
  }

  /// Generate hexadecimal representation of the current timestamp.
  /// Return: Hexadecimal representation of the current
  /// unix time retrieved by ``time.time``.
  String currentTimestampToHexadecimal() {
    final String currentTimeSinceEpoch =
        DateTime.now().millisecondsSinceEpoch.toString();
    final String currentTimeRounded =
        currentTimeSinceEpoch.substring(0, currentTimeSinceEpoch.length - 3);

    final int currentTimeInt = int.parse(currentTimeRounded);

    return currentTimeInt.toRadixString(16).padLeft(2, '0');
  }

  /// Extract the IP address from the broadcast message.
  static String extractIpAddr(List<String> hexSeparatedLetters) {
    final String ipAddrSection =
        substrLikeInJavaScript(hexSeparatedLetters.join(), 152, 8);

    final int ipAddrInt = int.parse(
      substrLikeInJavaScript(ipAddrSection, 0, 2) +
          substrLikeInJavaScript(ipAddrSection, 2, 2) +
          substrLikeInJavaScript(ipAddrSection, 4, 2) +
          substrLikeInJavaScript(ipAddrSection, 6, 2),
      radix: 16,
    );
    return ipAddrInt.toString();
  }

  static int extractPowerConsumption(Uint8List message) {
    // Convert the relevant part of the message to a hex string
    String hexPowerConsumption = bytesToHex(message).substring(270, 278);

    // Rearrange the hex string and convert it to an integer
    return int.parse(
        hexPowerConsumption.substring(2, 4) +
            hexPowerConsumption.substring(0, 2),
        radix: 16);
  }

  ///  Extract the time remains for the current execution.
  static String getRemaining(Uint8List message) {
    // Convert the relevant part of the message to a hex string
    String hexRemainingTime = bytesToHex(message).substring(294, 302);

    // Rearrange the hex string and convert it to an integer (time in seconds)
    int intRemainingTimeSeconds = int.parse(
        hexRemainingTime.substring(6, 8) +
            hexRemainingTime.substring(4, 6) +
            hexRemainingTime.substring(2, 4) +
            hexRemainingTime.substring(0, 2),
        radix: 16);

    // Convert seconds to ISO time format
    return secondsToIsoTime(intRemainingTimeSeconds);
  }

  /// Substring like in JavaScript
  /// If first index is bigger than second index than it will cut until the
  /// first and will get the second index number of characters from there
  static String substrLikeInJavaScript(
    String text,
    int firstIndex,
    int secondIndex,
  ) {
    String tempText = text;
    if (firstIndex > secondIndex) {
      tempText = tempText.substring(firstIndex);
      tempText = tempText.substring(0, secondIndex);
    } else {
      tempText = tempText.substring(firstIndex, secondIndex);
    }
    return tempText;
  }

  static String getMac(Uint8List message) {
    // Convert the relevant part of the message to a hex string
    String hexMac = bytesToHex(message).substring(160, 172).toUpperCase();

    // Format the string as a MAC address
    return '${hexMac.substring(0, 2)}:${hexMac.substring(2, 4)}:${hexMac.substring(4, 6)}:${hexMac.substring(6, 8)}:${hexMac.substring(8, 10)}:${hexMac.substring(10, 12)}';
  }

  static String extractDeviceName(Uint8List message) =>
      utf8.decode(message.sublist(42, 74)).replaceAll(RegExp(r'\x00+$'), '');

  /// Same as Buffer.from(value) in javascript
  /// Not to be confused with Buffer.from(value, 'hex')
  static String getUtf8Encoded(String list) {
    final List<int> encoded = utf8.encode(list);

    return intListToHex(encoded).join();
  }

  static String getAutoShutdown(Uint8List message) {
    // Convert the relevant part of the message to a hex string
    String hexAutoShutdownVal = bytesToHex(message).substring(310, 318);

    // Rearrange the hex string and convert it to an integer (time in seconds)
    int intAutoShutdownValSecs = int.parse(
        hexAutoShutdownVal.substring(6, 8) +
            hexAutoShutdownVal.substring(4, 6) +
            hexAutoShutdownVal.substring(2, 4) +
            hexAutoShutdownVal.substring(0, 2),
        radix: 16);

    // Convert seconds to ISO time format
    return secondsToIsoTime(intAutoShutdownValSecs);
  }

  // Helper method to convert seconds to ISO time format
  static String secondsToIsoTime(int seconds) {
    int hours = seconds ~/ 3600;
    int minutes = (seconds % 3600) ~/ 60;
    int remainingSeconds = seconds % 60;

    return '${hours.toString().padLeft(2, '0')}:${minutes.toString().padLeft(2, '0')}:${remainingSeconds.toString().padLeft(2, '0')}';
  }

  static String extractDeviceId(Uint8List message) =>
      bytesToHex(message).substring(36, 42);

  Future<Socket> getSocket() async {
    if (socket != null) {
      return socket!;
    }

    try {
      final Socket socket = await Socket.connect(switcherIp, port);
      return socket;
    } catch (e) {
      socket = null;
      loggerSwitcher.e(
          'Error connecting to socket for switcher device  type $deviceType Error:\n$e');
      rethrow;
    }
  }

  String timerValue(int minutes) {
    if (minutes == 0) {
      // when duration set to zero, Switcher sends regular on command
      return '00000000';
    }
    final seconds = minutes * 60;
    return intListToHex(packLittleEndian(seconds)).join();
  }
}

class Crc16XmodemWith0x1021 extends ParametricCrc {
  Crc16XmodemWith0x1021()
      : super(
          16,
          0x1021,
          0x1021,
          0x0000,
          inputReflected: false,
          outputReflected: false,
        );
}

/// Enum class representing the device's state.
enum SwitcherDeviceState {
  on, // "01", "on"
  off, // "00", "off"
}

extension DeviceStateExtension on SwitcherDeviceState {
  String get value {
    switch (this) {
      case SwitcherDeviceState.on:
        return "01";
      case SwitcherDeviceState.off:
        return "00";
      default:
        return "";
    }
  }
}

/// Enum for relaying the type of the switcher devices.
enum SwitcherDevicesTypes {
  notRecognized,
  switcherMini, // MINI = "Switcher Mini", "030f", 1, DeviceCategory.WATER_HEATER
  switcherPowerPlug, // POWER_PLUG = "Switcher Power Plug", "01a8", 1, DeviceCategory.POWER_PLUG
  switcherTouch, // TOUCH = "Switcher Touch", "030b", 1, DeviceCategory.WATER_HEATER
  switcherV2Esp, // V2_ESP = "Switcher V2 (esp)", "01a7", 1, DeviceCategory.WATER_HEATER
  switcherV2qualcomm, // V2_QCA = "Switcher V2 (qualcomm)", "01a1", 1, DeviceCategory.WATER_HEATER
  switcherV4, // V4 = "Switcher V4", "0317", 1, DeviceCategory.WATER_HEATER
  switcherBreeze, // BREEZE = "Switcher Breeze", "0e01", 2, DeviceCategory.THERMOSTAT
  switcherRunner, // RUNNER = "Switcher Runner", "0c01", 2, DeviceCategory.SHUTTER
  switcherRunnerMini, // RUNNER_MINI = "Switcher Runner Mini", "0c02", 2, DeviceCategory.SHUTTER
}

extension SwitcherDevicesTypesExtension on SwitcherDevicesTypes {
  String get hexRep {
    switch (this) {
      case SwitcherDevicesTypes.switcherMini:
        return "030f";
      case SwitcherDevicesTypes.switcherPowerPlug:
        return "01a8";
      case SwitcherDevicesTypes.switcherTouch:
        return "030b";
      case SwitcherDevicesTypes.switcherV2Esp:
        return "01a7";
      case SwitcherDevicesTypes.switcherV2qualcomm:
        return "01a1";
      case SwitcherDevicesTypes.switcherV4:
        return "0317";
      case SwitcherDevicesTypes.switcherBreeze:
        return "0e01";
      case SwitcherDevicesTypes.switcherRunner:
        return "0c01";
      case SwitcherDevicesTypes.switcherRunnerMini:
        return "0c02";
      default:
        return "";
    }
  }
}
