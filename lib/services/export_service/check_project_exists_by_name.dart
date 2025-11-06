import 'package:http/http.dart' as http;

/// Vérifie si un projet existe par son nom (HEAD /api/Projects/exists/{name})
Future<bool> checkProjectExistsByName({
  required http.Client client,
  required String baseUrl,
  required String projectName,
}) async {
  final encodedName = Uri.encodeComponent(projectName);
  final url = Uri.parse('$baseUrl/api/Projects/exists/$encodedName');
  final response = await client.head(url);
  if (response.statusCode == 200) return true;
  if (response.statusCode == 404) return false;
  throw Exception(
    'Erreur lors de la vérification par nom: ${response.statusCode}',
  );
}
