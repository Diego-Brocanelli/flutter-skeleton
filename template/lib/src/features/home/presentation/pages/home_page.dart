import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Skeleton')),
      body: const Center(
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            Text(
              'Bem-vindo ao Template!',
              style: TextStyle(fontSize: 24),
            ),
            SizedBox(height: 16),
            Text('Riverpod + go_router + Freezed configurados'),
          ],
        ),
      ),
    );
  }
}