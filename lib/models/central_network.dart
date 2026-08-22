class CentralNetwork {
  final String id;
  final String name;
  final String description;
  final int? authorizedMemberCount;
  final int? totalMemberCount;

  const CentralNetwork({
    required this.id,
    required this.name,
    required this.description,
    this.authorizedMemberCount,
    this.totalMemberCount,
  });

  String get displayName => name.isEmpty ? 'Unnamed network' : name;

  factory CentralNetwork.fromJson(Map<String, dynamic> json) {
    final config = _stringMap(json['config']);
    return CentralNetwork(
      id: _text(json['id'] ?? config['id']),
      name: _text(config['name'] ?? json['name']),
      description: _text(json['description'] ?? config['description']),
      authorizedMemberCount: _integer(json['authorizedMemberCount']),
      totalMemberCount: _integer(json['totalMemberCount']),
    );
  }
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

String _text(Object? value) => value?.toString().trim() ?? '';

int? _integer(Object? value) => value is num ? value.toInt() : null;
