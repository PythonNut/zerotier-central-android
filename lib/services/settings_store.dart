import 'package:shared_preferences/shared_preferences.dart';

class SettingsStore {
  static const defaultDeviceLimit = 25;
  static const _deviceLimitKey = 'account_device_limit';

  Future<int> readDeviceLimit() async {
    final preferences = await SharedPreferences.getInstance();
    final value = preferences.getInt(_deviceLimitKey);
    return value == null || value < 1 ? defaultDeviceLimit : value;
  }

  Future<void> writeDeviceLimit(int value) async {
    if (value < 1) throw ArgumentError.value(value, 'value');
    final preferences = await SharedPreferences.getInstance();
    await preferences.setInt(_deviceLimitKey, value);
  }
}
