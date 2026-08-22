import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import '../formatters.dart';
import '../models/network_member.dart';
import '../services/central_api.dart';

class MemberDetailsPage extends StatefulWidget {
  final CentralApi api;
  final NetworkMember member;

  const MemberDetailsPage({super.key, required this.api, required this.member});

  @override
  State<MemberDetailsPage> createState() => _MemberDetailsPageState();
}

class _MemberDetailsPageState extends State<MemberDetailsPage> {
  late NetworkMember _member;
  late final TextEditingController _nameController;
  bool _savingName = false;
  bool _changingAuthorization = false;

  @override
  void initState() {
    super.initState();
    _member = widget.member;
    _nameController = TextEditingController(text: _member.name);
  }

  @override
  void dispose() {
    _nameController.dispose();
    super.dispose();
  }

  Future<void> _saveName() async {
    setState(() => _savingName = true);
    try {
      final updated = await widget.api.renameMember(
        _member,
        _nameController.text,
      );
      if (!mounted) return;
      setState(() {
        _member = updated;
        _nameController.text = updated.name;
      });
      ScaffoldMessenger.of(context)
          .showSnackBar(const SnackBar(content: Text('Device name saved.')));
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _savingName = false);
    }
  }

  Future<bool> _confirmDeauthorize() async {
    return await showDialog<bool>(
          context: context,
          builder: (context) => AlertDialog(
            title: const Text('Deauthorize device?'),
            content: Text(
              '${_member.displayName} will immediately lose access to this '
              'network.',
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

  Future<void> _setAuthorized(bool value) async {
    if (!value && !await _confirmDeauthorize()) return;
    setState(() => _changingAuthorization = true);
    try {
      final updated = await widget.api.setAuthorized(_member, value);
      if (mounted) setState(() => _member = updated);
    } catch (error) {
      if (mounted) {
        ScaffoldMessenger.of(context)
            .showSnackBar(SnackBar(content: Text(error.toString())));
      }
    } finally {
      if (mounted) setState(() => _changingAuthorization = false);
    }
  }

  Future<void> _copy(String label, String value) async {
    await Clipboard.setData(ClipboardData(text: value));
    if (!mounted) return;
    ScaffoldMessenger.of(context)
        .showSnackBar(SnackBar(content: Text('$label copied.')));
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: Text(_member.displayName)),
      body: ListView(
        padding: const EdgeInsets.fromLTRB(16, 12, 16, 32),
        children: [
          Card(
            child: Padding(
              padding: const EdgeInsets.all(16),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  TextField(
                    controller: _nameController,
                    maxLength: 255,
                    enabled: !_savingName,
                    decoration: const InputDecoration(
                      labelText: 'Device name',
                      prefixIcon: Icon(Icons.edit_outlined),
                    ),
                  ),
                  const SizedBox(height: 8),
                  FilledButton.icon(
                    onPressed: _savingName ? null : _saveName,
                    icon: _savingName
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.save_outlined),
                    label: const Text('Save name'),
                  ),
                ],
              ),
            ),
          ),
          const SizedBox(height: 12),
          Card(
            child: SwitchListTile.adaptive(
              title: const Text('Authorized'),
              subtitle: Text(
                _member.authorized
                    ? 'This device can participate in the network.'
                    : 'This device is blocked from the network.',
              ),
              value: _member.authorized,
              onChanged: _changingAuthorization ? null : _setAuthorized,
              secondary: _changingAuthorization
                  ? const CircularProgressIndicator.adaptive()
                  : Icon(
                      _member.authorized
                          ? Icons.verified_user_outlined
                          : Icons.gpp_bad_outlined,
                    ),
            ),
          ),
          const SizedBox(height: 20),
          Text(
            'Connection details',
            style: Theme.of(context).textTheme.titleLarge,
          ),
          const SizedBox(height: 10),
          _DetailTile(
            icon: Icons.fingerprint,
            label: 'Node ID',
            value: _member.nodeId,
            monospace: true,
            onCopy: () => _copy('Node ID', _member.nodeId),
          ),
          _DetailTile(
            icon: Icons.lan_outlined,
            label: 'ZeroTier IP addresses',
            value: _member.zeroTierAddresses.isEmpty
                ? 'None assigned'
                : _member.zeroTierAddresses.join('\n'),
            monospace: true,
            onCopy: _member.zeroTierAddresses.isEmpty
                ? null
                : () => _copy(
                    'ZeroTier IP addresses',
                    _member.zeroTierAddresses.join('\n'),
                  ),
          ),
          _DetailTile(
            icon: Icons.public,
            label: 'Last physical address',
            value: valueOrUnavailable(_member.physicalAddress),
            monospace: true,
            onCopy: _member.physicalAddress.isEmpty
                ? null
                : () => _copy('Physical address', _member.physicalAddress),
          ),
          _DetailTile(
            icon: Icons.schedule,
            label: 'Last seen',
            value: formatLastSeen(_member.lastSeen),
          ),
          _DetailTile(
            icon: Icons.memory,
            label: 'Client version',
            value: valueOrUnavailable(_member.clientVersion),
          ),
        ],
      ),
    );
  }
}

class _DetailTile extends StatelessWidget {
  final IconData icon;
  final String label;
  final String value;
  final bool monospace;
  final VoidCallback? onCopy;

  const _DetailTile({
    required this.icon,
    required this.label,
    required this.value,
    this.monospace = false,
    this.onCopy,
  });

  @override
  Widget build(BuildContext context) {
    return Card(
      margin: const EdgeInsets.only(bottom: 8),
      child: ListTile(
        leading: Icon(icon),
        title: Text(label),
        subtitle: Text(
          value,
          style: monospace ? const TextStyle(fontFamily: 'monospace') : null,
        ),
        trailing: onCopy == null
            ? null
            : IconButton(
                tooltip: 'Copy',
                onPressed: onCopy,
                icon: const Icon(Icons.copy_outlined),
              ),
      ),
    );
  }
}
