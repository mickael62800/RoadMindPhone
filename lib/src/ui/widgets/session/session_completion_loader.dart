import 'package:flutter/material.dart';

class SessionCompletionLoader extends StatelessWidget {
  const SessionCompletionLoader({Key? key}) : super(key: key);

  @override
  Widget build(BuildContext context) {
    return const Center(
      child: Column(
        mainAxisAlignment: MainAxisAlignment.center,
        children: [
          CircularProgressIndicator(),
          SizedBox(height: 16),
          Text('Initialisation en cours...'),
        ],
      ),
    );
  }
}
