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
    var list = json['IRWaveList'] as List;
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
