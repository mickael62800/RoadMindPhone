// Ajout temporaire pour restaurer la fonctionnalité d'exportation de projet
import 'package:http/http.dart' as http;
import 'dart:io' as io;
import 'dart:convert' as json;
import 'package:flutter/material.dart';

mixin ExportProjectMixin<T extends StatefulWidget> on State<T> {
  Future<void> _createProject() async {
    // TODO: Implémenter la logique d'exportation de création de projet ici
    // Cette méthode doit ressembler à _updateProject mais utiliser POST et gérer la création
    debugPrint(
      '[EXPORT] Appel API création projet (méthode temporaire à compléter)',
    );
    setState(() {
      // Utilisé pour afficher l'état d'exportation
      // ignore: invalid_use_of_protected_member
      if (this.mounted) {
        // ignore: invalid_use_of_protected_member
        // setState(() {});
      }
    });
  }
}
