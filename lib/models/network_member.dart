class NetworkMember {
  final String networkId;
  final String nodeId;
  final String name;
  final String description;
  final bool authorized;
  final List<String> zeroTierAddresses;
  final String physicalAddress;
  final DateTime? lastSeen;
  final String clientVersion;
  final bool hidden;

  const NetworkMember({
    required this.networkId,
    required this.nodeId,
    required this.name,
    required this.description,
    required this.authorized,
    required this.zeroTierAddresses,
    required this.physicalAddress,
    required this.lastSeen,
    required this.clientVersion,
    required this.hidden,
  });

  String get displayName => name.isEmpty ? 'Unnamed device' : name;

  NetworkMember copyWith({String? name, bool? authorized}) {
    return NetworkMember(
      networkId: networkId,
      nodeId: nodeId,
      name: name ?? this.name,
      description: description,
      authorized: authorized ?? this.authorized,
      zeroTierAddresses: zeroTierAddresses,
      physicalAddress: physicalAddress,
      lastSeen: lastSeen,
      clientVersion: clientVersion,
      hidden: hidden,
    );
  }

  /// Applies fields present in a partial Legacy Central response while
  /// retaining the last known value for fields the server omitted.
  NetworkMember mergeJson(Map<String, dynamic> json) {
    final parsed = NetworkMember.fromJson(json);
    final config = _stringMap(json['config']);
    return NetworkMember(
      networkId: json.containsKey('networkId') && parsed.networkId.isNotEmpty
          ? parsed.networkId
          : networkId,
      nodeId:
          (json.containsKey('nodeId') ||
                  json.containsKey('id') ||
                  config.containsKey('id')) &&
              parsed.nodeId.isNotEmpty
          ? parsed.nodeId
          : nodeId,
      name: json.containsKey('name') ? parsed.name : name,
      description: json.containsKey('description')
          ? parsed.description
          : description,
      authorized: config.containsKey('authorized')
          ? parsed.authorized
          : authorized,
      zeroTierAddresses: config.containsKey('ipAssignments')
          ? parsed.zeroTierAddresses
          : zeroTierAddresses,
      physicalAddress: json.containsKey('physicalAddress')
          ? parsed.physicalAddress
          : physicalAddress,
      lastSeen: json.containsKey('lastSeen') ? parsed.lastSeen : lastSeen,
      clientVersion: json.containsKey('clientVersion')
          ? parsed.clientVersion
          : clientVersion,
      hidden: json.containsKey('hidden') ? parsed.hidden : hidden,
    );
  }

  factory NetworkMember.fromJson(Map<String, dynamic> json) {
    final config = _stringMap(json['config']);
    final lastSeenMilliseconds = _integer(json['lastSeen']);
    return NetworkMember(
      networkId: _text(json['networkId']),
      nodeId: _nodeId(json, config),
      name: _text(json['name']),
      description: _text(json['description']),
      authorized: config['authorized'] == true,
      zeroTierAddresses: _stringList(config['ipAssignments']),
      physicalAddress: _text(json['physicalAddress']),
      lastSeen: lastSeenMilliseconds == null || lastSeenMilliseconds <= 0
          ? null
          : DateTime.fromMillisecondsSinceEpoch(
              lastSeenMilliseconds,
              isUtc: true,
            ),
      clientVersion: _text(json['clientVersion']),
      hidden: json['hidden'] == true,
    );
  }

  static String _nodeId(
    Map<String, dynamic> json,
    Map<String, dynamic> config,
  ) {
    final direct = _text(json['nodeId'] ?? config['id']);
    if (direct.isNotEmpty) return direct;
    final legacyId = _text(json['id']);
    final separator = legacyId.lastIndexOf('-');
    return separator < 0 ? legacyId : legacyId.substring(separator + 1);
  }
}

Map<String, dynamic> _stringMap(Object? value) {
  if (value is! Map) return const {};
  return value.map((key, value) => MapEntry(key.toString(), value));
}

List<String> _stringList(Object? value) {
  if (value is! List) return const [];
  return value
      .map((item) => item.toString().trim())
      .where((item) => item.isNotEmpty)
      .toList(growable: false);
}

String _text(Object? value) => value?.toString().trim() ?? '';

int? _integer(Object? value) => value is num ? value.toInt() : null;
