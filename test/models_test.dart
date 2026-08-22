import 'package:flutter_test/flutter_test.dart';
import 'package:zerotier_central_manager/formatters.dart';
import 'package:zerotier_central_manager/models/account_snapshot.dart';
import 'package:zerotier_central_manager/models/central_network.dart';
import 'package:zerotier_central_manager/models/network_member.dart';

void main() {
  group('CentralNetwork', () {
    test('reads the Legacy Central network shape', () {
      final network = CentralNetwork.fromJson({
        'id': '8056c2e21c000001',
        'config': {'name': 'Home'},
        'description': 'Private devices',
        'authorizedMemberCount': 3,
        'totalMemberCount': 4,
      });

      expect(network.id, '8056c2e21c000001');
      expect(network.displayName, 'Home');
      expect(network.description, 'Private devices');
      expect(network.authorizedMemberCount, 3);
      expect(network.totalMemberCount, 4);
    });
  });

  group('NetworkMember', () {
    test('reads member identity, authorization, addresses, and last seen', () {
      final member = NetworkMember.fromJson({
        'networkId': '8056c2e21c000001',
        'nodeId': 'abcdef0123',
        'name': 'Pixel',
        'physicalAddress': '203.0.113.7/9993',
        'lastSeen': 1700000000000,
        'clientVersion': '1.16.2',
        'config': {
          'authorized': true,
          'ipAssignments': ['10.147.19.10', 'fd00::10'],
        },
      });

      expect(member.nodeId, 'abcdef0123');
      expect(member.displayName, 'Pixel');
      expect(member.authorized, isTrue);
      expect(member.zeroTierAddresses, ['10.147.19.10', 'fd00::10']);
      expect(member.physicalAddress, '203.0.113.7/9993');
      expect(
        member.lastSeen,
        DateTime.fromMillisecondsSinceEpoch(1700000000000, isUtc: true),
      );
    });

    test('supports old responses that only expose config.id', () {
      final member = NetworkMember.fromJson({
        'networkId': '8056c2e21c000001',
        'config': {'id': 'abcdef0123', 'authorized': false},
      });

      expect(member.nodeId, 'abcdef0123');
      expect(member.displayName, 'Unnamed device');
      expect(member.authorized, isFalse);
      expect(member.lastSeen, isNull);
    });

    test(
      'merges partial mutation responses without discarding known fields',
      () {
        final member = NetworkMember.fromJson({
          'networkId': '8056c2e21c000001',
          'nodeId': 'abcdef0123',
          'name': 'Old name',
          'description': 'Desk machine',
          'physicalAddress': '203.0.113.7/9993',
          'lastSeen': 1700000000000,
          'clientVersion': '1.16.2',
          'config': {
            'authorized': true,
            'ipAssignments': ['10.147.19.10'],
          },
        });

        final renamed = member.mergeJson({'name': 'New name'});
        final deauthorized = renamed.mergeJson({
          'config': {'authorized': false},
        });

        expect(deauthorized.name, 'New name');
        expect(deauthorized.authorized, isFalse);
        expect(deauthorized.networkId, member.networkId);
        expect(deauthorized.nodeId, member.nodeId);
        expect(deauthorized.zeroTierAddresses, member.zeroTierAddresses);
        expect(deauthorized.physicalAddress, member.physicalAddress);
        expect(deauthorized.lastSeen, member.lastSeen);
        expect(deauthorized.clientVersion, member.clientVersion);
      },
    );
  });

  test('account usage deduplicates authorized nodes across networks', () {
    NetworkMember member(String network, String node, bool authorized) {
      return NetworkMember(
        networkId: network,
        nodeId: node,
        name: '',
        description: '',
        authorized: authorized,
        zeroTierAddresses: const [],
        physicalAddress: '',
        lastSeen: null,
        clientVersion: '',
        hidden: false,
      );
    }

    final snapshot = AccountSnapshot(
      networks: const [],
      membersByNetwork: {
        'one': [member('one', 'aaaa', true), member('one', 'bbbb', true)],
        'two': [member('two', 'aaaa', true), member('two', 'cccc', false)],
      },
    );

    expect(snapshot.authorizedDeviceCount, 2);
  });

  test('last-seen formatter uses useful relative intervals', () {
    final now = DateTime(2026, 8, 22, 12);
    expect(
      formatLastSeen(now.subtract(const Duration(minutes: 8)), now: now),
      '8 min ago',
    );
    expect(formatLastSeen(null, now: now), 'Never seen');
  });
}
