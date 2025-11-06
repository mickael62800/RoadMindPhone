import 'package:http/http.dart' as http;
import 'package:roadmindphone/session.dart';
import 'package:roadmindphone/services/export_service/export_single_session.dart';
import 'package:flutter/material.dart';

Future<bool> exportSessionData({
  required BuildContext context,
  required http.Client client,
  required String baseUrl,
  required Session session,
}) async {
  try {
    final response = await exportSingleSession(
      client: client,
      baseUrl: baseUrl,
      session: session,
    );
    if (response.statusCode == 200) {
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('Session exportée avec succès !')),
      );
      return true;
    } else {
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(
          content: Text(
            "Échec de l'exportation de la session: " +
                response.statusCode.toString(),
          ),
        ),
      );
      return false;
    }
  } catch (e) {
    ScaffoldMessenger.of(context).showSnackBar(
      SnackBar(content: Text("Erreur lors de l'exportation de la session: $e")),
    );
    return false;
  }
}
