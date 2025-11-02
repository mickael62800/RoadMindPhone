
import 'package:flutter/material.dart';
import 'package:roadmindphone/src/ui/atoms/atoms.dart';

class InfoCard extends StatelessWidget {
  final String title;
  final String value;

  const InfoCard({super.key, required this.title, required this.value});

  @override
  Widget build(BuildContext context) {
    return AppCard(
      child: Padding(
        padding: const EdgeInsets.all(16.0),
        child: FittedBox(
          fit: BoxFit.scaleDown,
          child: Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              SubtitleText(text: title),
              const SizedBox(height: 8),
              TitleText(text: value),
            ],
          ),
        ),
      ),
    );
  }
}
