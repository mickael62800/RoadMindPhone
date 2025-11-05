import 'package:shared_preferences/shared_preferences.dart';

/// Utilitaire pour récupérer l'URL de l'API depuis les settings (SharedPreferences)
Future<String> getApiBaseUrlFromSettings() async {
  final prefs = await SharedPreferences.getInstance();
  final ip = prefs.getString('db_server_address') ?? 'localhost';
  final port = prefs.getString('db_port') ?? '5439';
  return 'http://$ip:$port';
}
