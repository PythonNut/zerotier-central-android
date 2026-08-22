import 'package:flutter/material.dart';

import 'screens/network_list_page.dart';
import 'screens/sign_in_page.dart';
import 'services/central_api.dart';
import 'services/settings_store.dart';
import 'services/token_store.dart';

void main() {
  WidgetsFlutterBinding.ensureInitialized();
  runApp(const ZeroTierCentralApp());
}

class ZeroTierCentralApp extends StatefulWidget {
  const ZeroTierCentralApp({super.key});

  @override
  State<ZeroTierCentralApp> createState() => _ZeroTierCentralAppState();
}

class _ZeroTierCentralAppState extends State<ZeroTierCentralApp> {
  final TokenStore _tokenStore = TokenStore();
  final SettingsStore _settingsStore = SettingsStore();
  CentralApi? _api;
  bool _loadingToken = true;

  @override
  void initState() {
    super.initState();
    _loadToken();
  }

  Future<void> _loadToken() async {
    final token = await _tokenStore.read();
    if (!mounted) return;
    _setToken(token);
    setState(() => _loadingToken = false);
  }

  void _setToken(String? token) {
    _api?.close();
    setState(() => _api = token == null ? null : CentralApi(token));
  }

  @override
  void dispose() {
    _api?.close();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'ZeroTier Central',
      debugShowCheckedModeBanner: false,
      themeMode: ThemeMode.system,
      theme: _theme(Brightness.light),
      darkTheme: _theme(Brightness.dark),
      home: _loadingToken
          ? const Scaffold(
              body: Center(child: CircularProgressIndicator.adaptive()),
            )
          : _api == null
          ? SignInPage(tokenStore: _tokenStore, onSignedIn: _setToken)
          : NetworkListPage(
              api: _api!,
              settingsStore: _settingsStore,
              onSignOut: () async {
                await _tokenStore.clear();
                _setToken(null);
              },
            ),
    );
  }

  ThemeData _theme(Brightness brightness) {
    final scheme = ColorScheme.fromSeed(
      seedColor: const Color(0xff43a047),
      brightness: brightness,
    );
    return ThemeData(
      colorScheme: scheme,
      useMaterial3: true,
      cardTheme: const CardThemeData(margin: EdgeInsets.zero),
      inputDecorationTheme: const InputDecorationTheme(
        border: OutlineInputBorder(),
      ),
    );
  }
}
