import 'central_network.dart';
import 'network_member.dart';

class AccountSnapshot {
  final List<CentralNetwork> networks;
  final Map<String, List<NetworkMember>> membersByNetwork;

  const AccountSnapshot({
    required this.networks,
    required this.membersByNetwork,
  });

  int get authorizedDeviceCount {
    final nodeIds = <String>{};
    for (final members in membersByNetwork.values) {
      for (final member in members) {
        if (member.authorized && member.nodeId.isNotEmpty) {
          nodeIds.add(member.nodeId);
        }
      }
    }
    return nodeIds.length;
  }

  List<NetworkMember> membersFor(String networkId) =>
      membersByNetwork[networkId] ?? const [];
}
