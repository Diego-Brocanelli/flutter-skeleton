import 'package:flutter/material.dart';
import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../controllers/home_notifier.dart';
import '../widgets/home_header_widget.dart';

class HomePage extends ConsumerWidget {
  const HomePage({super.key});

  @override
  Widget build(BuildContext context, WidgetRef ref) {
    final state = ref.watch(homeNotifierProvider);

    return Scaffold(
      appBar: AppBar(title: const Text('Flutter Skeleton')),
      body: Center(
        child: state.when(
          data: (data) => Column(
            mainAxisAlignment: MainAxisAlignment.center,
            children: [
              HomeHeaderWidget(message: data.welcomeMessage),
              const SizedBox(height: 16),
              Text(data.configuredPackages.join(' + ')),
              Text('${data.configuredPackages.length} pacotes configurados'),
            ],
          ),
          loading: () => const CircularProgressIndicator(),
          error: (error, _) => Text('Erro: $error'),
        ),
      ),
    );
  }
}
