import 'package:flutter/material.dart';

import '../formatters.dart';
import '../models/central_network.dart';
import '../models/network_member.dart';
import '../services/central_api.dart';
import 'member_details_page.dart';

enum _MemberFilter { all, pending, authorized }

class MemberListPage extends StatefulWidget {
  final CentralApi api;
  final CentralNetwork network;
  final List<NetworkMember> initialMembers;

  const MemberListPage({
    super.key,
    required this.api,
    required this.network,
    required this.initialMembers,
  });

  @override
  State<MemberListPage> createState() => _MemberListPageState();
}

class _MemberListPageState extends State<MemberListPage> {
  final _searchController = TextEditingController();
  late List<NetworkMember> _members;
  final Set<String> _updating = {};
  _MemberFilter _filter = _MemberFilter.all;
  bool _loading = false;
  String? _error;

  @override
  void initState() {
    super.initState();
    _members = List.of(widget.initialMembers);
    _searchController.addListener(_refreshFilter);
  }

  @override
  void dispose() {
    _searchController
      ..removeListener(_refreshFilter)
      ..dispose();
    super.dispose();
  }

  void _refreshFilter() {
    if (mounted) setState(() {});
  }

  Future<void> _load() async {
    setState(() {
      _loading = true;
      _error = null;
    });
    try {
      final members = await widget.api.listMembers(widget.network.id);
      if (mounted) setState(() => _members = members);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  List<NetworkMember> get _visibleMembers {
    final query = _searchController.text.trim().toLowerCase();
    return _members
        .where((member) {
          final matchesFilter = switch (_filter) {
            _MemberFilter.all => true,
            _MemberFilter.pending => !member.authorized,
            _MemberFilter.authorized => member.authorized,
          };
          if (!matchesFilter) return false;
          if (query.isEmpty) return true;
          return member.name.toLowerCase().contains(query) ||
              member.nodeId.toLowerCase().contains(query) ||
              member.zeroTierAddresses.any(
                (address) => address.contains(query),
              ) ||
              member.physicalAddress.toLowerCase().contains(query);
        })
        .toList(growable: false);
  }

  void _replaceMember(NetworkMember replacement) {
    final index = _members.indexWhere(
      (member) => member.nodeId == replacement.nodeId,
    );
    if (index < 0) return;
    setState(() => _members[index] = replacement);
  }

  Future<bool> _confirmDeauthorize(NetworkMember member) async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Deauthorize device?'),
            content: Text(
              '${member.displayName} will immediately lose access to '
              '${widget.network.displayName}.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Deauthorize'),
              ),
            ],
          ),
        ) ??
        false;
  }

  Future<void> _setAuthorized(NetworkMember member, bool value) async {
    if (!value && !await _confirmDeauthorize(member)) return;
    setState(() => _updating.add(member.nodeId));
    try {
      final updated = await widget.api.setAuthorized(member, value);
      if (mounted) _replaceMember(updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _updating.remove(member.nodeId));
    }
  }

  Future<void> _openMember(NetworkMember member) async {
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemberDetailsPage(api: widget.api, member: member),
      ),
    );
    if (mounted) await _load();
  }

  @override
  Widget build(BuildContext context) {
    final authorized = _members.where((member) => member.authorized).length;
    final pending = _members.length - authorized;
    return Scaffold(
      appBar: AppBar(
        title: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Text(
              widget.network.displayName,
              maxLines: 1,
              overflow: TextOverflow.ellipsis,
            ),
            Text(
              widget.network.id,
              style: Theme.of(context).textTheme.labelSmall
                  ?.copyWith(fontFamily: 'monospace'),
            ),
          ],
        ),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
        ],
      ),
      body: RefreshIndicator(
        onRefresh: _load,
        child: CustomScrollView(
          slivers: [
            SliverToBoxAdapter(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 12, 16, 8),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.stretch,
                  children: [
                    Row(
                      children: [
                        Expanded(
                          child: _CountCard(
                            label: 'Authorized',
                            count: authorized,
                            icon: Icons.verified_user_outlined,
                          ),
                        ),
                        const SizedBox(width: 12),
                        Expanded(
                          child: _CountCard(
                            label: 'Pending',
                            count: pending,
                            icon: Icons.pending_outlined,
                          ),
                        ),
                      ],
                    ),
                    const SizedBox(height: 16),
                    TextField(
                      controller: _searchController,
                      decoration: InputDecoration(
                        labelText: 'Search members',
                        prefixIcon: const Icon(Icons.search),
                        suffixIcon: _searchController.text.isEmpty
                            ? null
                            : IconButton(
                                tooltip: 'Clear',
                                onPressed: _searchController.clear,
                                icon: const Icon(Icons.clear),
                              ),
                      ),
                    ),
                    const SizedBox(height: 12),
                    SegmentedButton<_MemberFilter>(
                      segments: const [
                        ButtonSegment(
                          value: _MemberFilter.all,
                          label: Text('All'),
                        ),
                        ButtonSegment(
                          value: _MemberFilter.pending,
                          label: Text('Pending'),
                        ),
                        ButtonSegment(
                          value: _MemberFilter.authorized,
                          label: Text('Authorized'),
                        ),
                      ],
                      selected: {_filter},
                      onSelectionChanged: (selection) {
                        setState(() => _filter = selection.single);
                      },
                    ),
                    if (_error != null) ...[
                      const SizedBox(height: 12),
                      Text(
                        _error!,
                        style: TextStyle(
                          color: Theme.of(context).colorScheme.error,
                        ),
                      ),
                    ],
                  ],
                ),
              ),
            ),
            if (_loading)
              const SliverToBoxAdapter(child: LinearProgressIndicator()),
            if (_visibleMembers.isEmpty)
              const SliverFillRemaining(
                hasScrollBody: false,
                child: Center(child: Text('No members match this view.')),
              )
            else
              SliverPadding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 32),
                sliver: SliverList.separated(
                  itemCount: _visibleMembers.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final member = _visibleMembers[index];
                    return _MemberCard(
                      member: member,
                      updating: _updating.contains(member.nodeId),
                      onTap: () => _openMember(member),
                      onAuthorizationChanged: (value) =>
                          _setAuthorized(member, value),
                    );
                  },
                ),
              ),
          ],
        ),
      ),
    );
  }
}

class _CountCard extends StatelessWidget {
  final String label;
  final int count;
  final IconData icon;

  const _CountCard({
    required this.label,
    required this.count,
    required this.icon,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            Icon(icon),
            const SizedBox(width: 10),
            Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text('$count', style: Theme.of(context).textTheme.titleLarge),
                Text(label, style: Theme.of(context).textTheme.bodySmall),
              ],
            ),
          ],
        ),
      ),
    );
  }
}

class _MemberCard extends StatelessWidget {
  final NetworkMember member;
  final bool updating;
  final VoidCallback onTap;
  final ValueChanged<bool> onAuthorizationChanged;

  const _MemberCard({
    required this.member,
    required this.updating,
    required this.onTap,
    required this.onAuthorizationChanged,
  });

  @override
  Widget build(BuildContext context) {
    final addresses = member.zeroTierAddresses.isEmpty
        ? 'No ZeroTier IP assigned'
        : member.zeroTierAddresses.join(', ');
    return Card(
      child: InkWell(
        borderRadius: BorderRadius.circular(12),
        onTap: onTap,
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 14, 10, 14),
          child: Row(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              CircleAvatar(
                backgroundColor: member.authorized
                    ? Theme.of(context).colorScheme.primaryContainer
                    : Theme.of(context).colorScheme.errorContainer,
                child: Icon(
                  member.authorized
                      ? Icons.devices_outlined
                      : Icons.device_unknown_outlined,
                ),
              ),
              const SizedBox(width: 14),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      member.displayName,
                      style: Theme.of(context).textTheme.titleMedium,
                      maxLines: 1,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 2),
                    Text(
                      member.nodeId,
                      style: Theme.of(context).textTheme.bodySmall
                          ?.copyWith(fontFamily: 'monospace'),
                    ),
                    const SizedBox(height: 8),
                    Text(
                      addresses,
                      maxLines: 2,
                      overflow: TextOverflow.ellipsis,
                    ),
                    const SizedBox(height: 3),
                    Text(
                      formatLastSeen(member.lastSeen),
                      style: Theme.of(context).textTheme.bodySmall,
                    ),
                  ],
                ),
              ),
              const SizedBox(width: 8),
              updating
                  ? const Padding(
                      padding: EdgeInsets.all(12),
                      child: SizedBox.square(
                        dimension: 22,
                        child: CircularProgressIndicator(strokeWidth: 2),
                      ),
                    )
                  : Switch.adaptive(
                      value: member.authorized,
                      onChanged: onAuthorizationChanged,
                    ),
            ],
          ),
        ),
      ),
    );
  }
}
