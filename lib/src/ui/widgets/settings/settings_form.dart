import 'package:flutter/material.dart';

class SettingsForm extends StatelessWidget {
  final TextEditingController serverAddressController;
  final TextEditingController portController;
  final VoidCallback onSave;

  const SettingsForm({
    super.key,
    required this.serverAddressController,
    required this.portController,
    required this.onSave,
  });

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.all(16.0),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          TextField(
            controller: serverAddressController,
            decoration: const InputDecoration(
              labelText: 'Database Server Address',
            ),
          ),
          const SizedBox(height: 16.0),
          TextField(
            controller: portController,
            decoration: const InputDecoration(labelText: 'Database Port'),
            keyboardType: TextInputType.number,
          ),
          const SizedBox(height: 24.0),
          SizedBox(
            width: double.infinity,
            child: ElevatedButton(
              onPressed: onSave,
              child: const Text('Sauver'),
            ),
          ),
        ],
      ),
    );
  }
}
