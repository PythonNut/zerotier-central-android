import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../models/account_snapshot.dart';
import '../models/central_network.dart';
import '../services/central_api.dart';
import '../services/settings_store.dart';
import 'member_list_page.dart';

enum _MenuAction { deviceLimit, signOut }

class NetworkListPage extends StatefulWidget {
  final CentralApi api;
  final SettingsStore settingsStore;
  final Future<void> Function() onSignOut;

  const NetworkListPage({
    super.key,
    required this.api,
    required this.settingsStore,
    required this.onSignOut,
  });

  @override
  State<NetworkListPage> createState() => _NetworkListPageState();
}

class _NetworkListPageState extends State<NetworkListPage> {
  AccountSnapshot? _snapshot;
  int _deviceLimit = SettingsStore.defaultDeviceLimit;
  bool _loading = true;
  String? _error;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    if (mounted) {
      setState(() {
        _loading = true;
        _error = null;
      });
    }
    try {
      final results = await Future.wait<Object>([
        widget.api.loadAccount(),
        widget.settingsStore.readDeviceLimit(),
      ]);
      if (!mounted) return;
      setState(() {
        _snapshot = results[0] as AccountSnapshot;
        _deviceLimit = results[1] as int;
      });
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      if (mounted) setState(() => _loading = false);
    }
  }

  Future<void> _openNetwork(CentralNetwork network) async {
    final snapshot = _snapshot;
    if (snapshot == null) return;
    await Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => MemberListPage(
          api: widget.api,
          network: network,
          initialMembers: snapshot.membersFor(network.id),
        ),
      ),
    );
    await _load();
  }

  Future<void> _changeDeviceLimit() async {
    final controller = TextEditingController(text: '$_deviceLimit');
    final value = await showDialog<int>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('Account device allowance'),
        content: Column(
          mainAxisSize: MainAxisSize.min,
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const Text(
              'Legacy Central does not report the subscription allowance '
              'through its API. Grandfathered free accounts normally use 25.',
            ),
            const SizedBox(height: 16),
            TextField(
              controller: controller,
              autofocus: true,
              keyboardType: TextInputType.number,
              decoration: const InputDecoration(labelText: 'Device limit'),
            ),
          ],
        ),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context),
            child: const Text('Cancel'),
          ),
          FilledButton(
            onPressed: () {
              final parsed = int.tryParse(controller.text.trim());
              if (parsed != null && parsed > 0) Navigator.pop(context, parsed);
            },
            child: const Text('Save'),
          ),
        ],
      ),
    );
    controller.dispose();
    if (value == null) return;
    await widget.settingsStore.writeDeviceLimit(value);
    if (mounted) setState(() => _deviceLimit = value);
  }

  Future<void> _handleMenu(_MenuAction action) async {
    switch (action) {
      case _MenuAction.deviceLimit:
        await _changeDeviceLimit();
      case _MenuAction.signOut:
        final confirmed = await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Remove API token?'),
            content: const Text(
              'This signs out and deletes the stored Legacy Central token '
              'from this device.',
            ),
            actions: [
              TextButton(
                onPressed: () => Navigator.pop(context, false),
                child: const Text('Cancel'),
              ),
              FilledButton(
                onPressed: () => Navigator.pop(context, true),
                child: const Text('Sign out'),
              ),
            ],
          ),
        );
        if (confirmed == true) await widget.onSignOut();
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: const Text('ZeroTier Central'),
        actions: [
          IconButton(
            tooltip: 'Refresh',
            onPressed: _loading ? null : _load,
            icon: const Icon(Icons.refresh),
          ),
          PopupMenuButton<_MenuAction>(
            onSelected: _handleMenu,
            itemBuilder: (context) => const [
              PopupMenuItem(
                value: _MenuAction.deviceLimit,
                child: ListTile(
                  leading: Icon(Icons.speed_outlined),
                  title: Text('Device allowance'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
              PopupMenuItem(
                value: _MenuAction.signOut,
                child: ListTile(
                  leading: Icon(Icons.logout),
                  title: Text('Sign out'),
                  contentPadding: EdgeInsets.zero,
                ),
              ),
            ],
          ),
        ],
      ),
      body: _body(context),
    );
  }

  Widget _body(BuildContext context) {
    if (_loading && _snapshot == null) {
      return const Center(child: CircularProgressIndicator.adaptive());
    }
    if (_error != null && _snapshot == null) {
      return _ErrorState(message: _error!, onRetry: _load);
    }
    final snapshot = _snapshot;
    if (snapshot == null) return const SizedBox.shrink();
    return RefreshIndicator(
      onRefresh: _load,
      child: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          _UsageCard(used: snapshot.authorizedDeviceCount, limit: _deviceLimit),
          if (_error != null) ...[
            const SizedBox(height: 12),
            MaterialBanner(
              content: Text(_error!),
              actions: [
                TextButton(onPressed: _load, child: const Text('Retry')),
              ],
            ),
          ],
          const SizedBox(height: 24),
          Text('Networks', style: Theme.of(context).textTheme.titleLarge),
          const SizedBox(height: 12),
          if (snapshot.networks.isEmpty)
            const _EmptyState()
          else
            for (final network in snapshot.networks) ...[
              _NetworkCard(
                network: network,
                authorizedCount: snapshot
                    .membersFor(network.id)
                    .where((member) => member.authorized)
                    .length,
                totalCount: snapshot.membersFor(network.id).length,
                onTap: () => _openNetwork(network),
              ),
              const SizedBox(height: 12),
            ],
        ],
      ),
    );
  }
}

class _UsageCard extends StatelessWidget {
  final int used;
  final int limit;

  const _UsageCard({required this.used, required this.limit});

  @override
  Widget build(BuildContext context) {
    final ratio = limit == 0 ? 0.0 : math.min(used / limit, 1.0);
    final overLimit = used > limit;
    final color = overLimit ? Theme.of(context).colorScheme.error : null;
    return Card(
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            Row(
              children: [
                Icon(Icons.devices_other, color: color),
                const SizedBox(width: 12),
                Expanded(
                  child: Text(
                    '$used of $limit devices authorized',
                    style: Theme.of(context).textTheme.titleMedium
                        ?.copyWith(color: color),
                  ),
                ),
              ],
            ),
            const SizedBox(height: 14),
            LinearProgressIndicator(
              value: ratio,
              color: color,
              minHeight: 8,
              borderRadius: BorderRadius.circular(99),
            ),
            const SizedBox(height: 10),
            Text(
              'Unique authorized node IDs across all accessible networks.',
              style: Theme.of(context).textTheme.bodySmall,
            ),
          ],
        ),
      ),
    );
  }
}

class _NetworkCard extends StatelessWidget {
  final CentralNetwork network;
  final int authorizedCount;
  final int totalCount;
  final VoidCallback onTap;

  const _NetworkCard({
    required this.network,
    required this.authorizedCount,
    required this.totalCount,
    required this.onTap,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      child: ListTile(
        onTap: onTap,
        contentPadding: const EdgeInsets.symmetric(horizontal: 18, vertical: 8),
        leading: CircleAvatar(
          backgroundColor: Theme.of(context).colorScheme.primaryContainer,
          child: const Icon(Icons.lan_outlined),
        ),
        title: Text(
          network.displayName,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
        ),
        subtitle: Text(
          '${network.id}\n$authorizedCount authorized · $totalCount total',
          style: const TextStyle(fontFamily: 'monospace'),
        ),
        isThreeLine: true,
        trailing: const Icon(Icons.chevron_right),
      ),
    );
  }
}

class _ErrorState extends StatelessWidget {
  final String message;
  final VoidCallback onRetry;

  const _ErrorState({required this.message, required this.onRetry});

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Icon(
              Icons.cloud_off_outlined,
              size: 52,
              color: Theme.of(context).colorScheme.error,
            ),
            const SizedBox(height: 16),
            Text(message, textAlign: TextAlign.center),
            const SizedBox(height: 16),
            FilledButton.icon(
              onPressed: onRetry,
              icon: const Icon(Icons.refresh),
              label: const Text('Retry'),
            ),
          ],
        ),
      ),
    );
  }
}

class _EmptyState extends StatelessWidget {
  const _EmptyState();

  @override
  Widget build(BuildContext context) {
    return const Card(
      child: Padding(
        padding: EdgeInsets.all(24),
        child: Text(
          'No networks are accessible to this token.',
          textAlign: TextAlign.center,
        ),
      ),
    );
  }
}
