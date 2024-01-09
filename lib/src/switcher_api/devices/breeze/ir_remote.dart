import 'dart:convert';
import 'dart:io';

class IrRemote {
  final String irSetId;
  final int onOffType;
  final List<IRWave> irWaveList;

  IrRemote({
    required this.irSetId,
    required this.onOffType,
    required this.irWaveList,
  });

  factory IrRemote.fromJson(Map<String, dynamic> json) {
    List list = json['IRWaveList'] as List;
    List<IRWave> irWaveList = list.map((i) => IRWave.fromJson(i)).toList();
    return IrRemote(
      irSetId: json['IRSetID'],
      onOffType: json['OnOffType'],
      irWaveList: irWaveList,
    );
  }
}

class IRWave {
  final String key;
  final String para;
  final String hexCode;

  IRWave({required this.key, required this.para, required this.hexCode});

  factory IRWave.fromJson(Map<String, dynamic> json) {
    return IRWave(
      key: json['Key'],
      para: json['Para'],
      hexCode: json['HexCode'],
    );
  }
}

Map<String, IrRemote> _irRemoteMap = {};

Future<IrRemote?> getRemoteInfo(String id) async {
  if (_irRemoteMap.isEmpty) {
    try {
      final file = File('lib/src/switcher_api/devices/breeze/irset_db.json');
      // Read the file
      final contents = await file.readAsString();

      // Decode the JSON data
      final Map<String, dynamic> jsonData = jsonDecode(contents);

      // Create an instance of MainObject using the decoded data
      for (MapEntry<String, dynamic> entry in jsonData.entries) {
        _irRemoteMap
            .addEntries([MapEntry(entry.key, IrRemote.fromJson(entry.value))]);
      }
    } catch (e) {
      // Handle errors, e.g., file not found, invalid JSON, etc.
      print('An error occurred: $e');
      rethrow; // Or return a default value, depending on your error handling strategy
    }
  }
  return _irRemoteMap[id];
}
