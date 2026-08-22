import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:url_launcher/url_launcher.dart';

import '../services/central_api.dart';
import '../services/token_store.dart';

class SignInPage extends StatefulWidget {
  final TokenStore tokenStore;
  final ValueChanged<String> onSignedIn;

  const SignInPage({
    super.key,
    required this.tokenStore,
    required this.onSignedIn,
  });

  @override
  State<SignInPage> createState() => _SignInPageState();
}

class _SignInPageState extends State<SignInPage> {
  final _tokenController = TextEditingController();
  bool _busy = false;
  bool _obscureToken = true;
  String? _error;

  @override
  void dispose() {
    _tokenController.dispose();
    super.dispose();
  }

  Future<void> _paste() async {
    final data = await Clipboard.getData(Clipboard.kTextPlain);
    if (!mounted || data?.text == null) return;
    _tokenController.text = data!.text!.trim();
    setState(() => _error = null);
  }

  Future<void> _signIn() async {
    final token = _tokenController.text.trim();
    if (token.length < 32) {
      setState(() {
        _error = 'Legacy Central tokens are at least 32 characters.';
      });
      return;
    }
    setState(() {
      _busy = true;
      _error = null;
    });
    final api = CentralApi(token);
    try {
      await api.validateToken();
      await widget.tokenStore.write(token);
      if (mounted) widget.onSignedIn(token);
    } catch (error) {
      if (mounted) setState(() => _error = error.toString());
    } finally {
      api.close();
      if (mounted) setState(() => _busy = false);
    }
  }

  Future<void> _openAccountPage() async {
    final launched = await launchUrl(
      Uri.parse('https://my.zerotier.com/account'),
      mode: LaunchMode.externalApplication,
    );
    if (!launched && mounted) {
      setState(() => _error = 'Unable to open my.zerotier.com.');
    }
  }

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Center(
          child: SingleChildScrollView(
            padding: const EdgeInsets.all(24),
            child: ConstrainedBox(
              constraints: const BoxConstraints(maxWidth: 520),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.stretch,
                children: [
                  Icon(
                    Icons.hub_outlined,
                    size: 72,
                    color: Theme.of(context).colorScheme.primary,
                  ),
                  const SizedBox(height: 20),
                  Text(
                    'ZeroTier Central',
                    style: Theme.of(context).textTheme.headlineMedium,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 8),
                  Text(
                    'Manage members of a Legacy Central account. This app '
                    'does not run a VPN and does not require root.',
                    style: Theme.of(context).textTheme.bodyLarge,
                    textAlign: TextAlign.center,
                  ),
                  const SizedBox(height: 28),
                  TextField(
                    controller: _tokenController,
                    obscureText: _obscureToken,
                    autocorrect: false,
                    enableSuggestions: false,
                    keyboardType: TextInputType.visiblePassword,
                    textInputAction: TextInputAction.done,
                    onChanged: (_) => setState(() => _error = null),
                    onSubmitted: (_) {
                      if (!_busy) _signIn();
                    },
                    decoration: InputDecoration(
                      labelText: 'Legacy Central API token',
                      prefixIcon: const Icon(Icons.key_outlined),
                      suffixIcon: Row(
                        mainAxisSize: MainAxisSize.min,
                        children: [
                          IconButton(
                            tooltip: 'Paste',
                            onPressed: _busy ? null : _paste,
                            icon: const Icon(Icons.content_paste),
                          ),
                          IconButton(
                            tooltip: _obscureToken
                                ? 'Show token'
                                : 'Hide token',
                            onPressed: _busy
                                ? null
                                : () => setState(
                                    () => _obscureToken = !_obscureToken,
                                  ),
                            icon: Icon(
                              _obscureToken
                                  ? Icons.visibility_outlined
                                  : Icons.visibility_off_outlined,
                            ),
                          ),
                        ],
                      ),
                    ),
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
                  const SizedBox(height: 16),
                  FilledButton.icon(
                    onPressed: _busy ? null : _signIn,
                    icon: _busy
                        ? const SizedBox.square(
                            dimension: 18,
                            child: CircularProgressIndicator(strokeWidth: 2),
                          )
                        : const Icon(Icons.login),
                    label: const Text('Connect'),
                  ),
                  const SizedBox(height: 8),
                  TextButton.icon(
                    onPressed: _busy ? null : _openAccountPage,
                    icon: const Icon(Icons.open_in_new),
                    label: const Text('Create or copy a token'),
                  ),
                  const SizedBox(height: 16),
                  Text(
                    'The token is validated before it is stored. Android '
                    'Keystore-backed secure storage protects it at rest, and '
                    'app backups are disabled.',
                    style: Theme.of(context).textTheme.bodySmall,
                    textAlign: TextAlign.center,
                  ),
                ],
              ),
            ),
          ),
        ),
      ),
    );
  }
}
