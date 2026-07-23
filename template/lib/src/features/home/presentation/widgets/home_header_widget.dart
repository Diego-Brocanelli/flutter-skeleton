import 'package:flutter/material.dart';

/// Mensagem de boas-vindas da tela inicial.
///
/// Extraído da página principal para manter `home_page.dart` enxuta e
/// este widget testável isoladamente.
class HomeHeaderWidget extends StatelessWidget {
  const HomeHeaderWidget({required this.message, super.key});

  final String message;

  @override
  Widget build(BuildContext context) {
    return Text(message, style: const TextStyle(fontSize: 24));
  }
}
