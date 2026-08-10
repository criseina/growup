import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

import 'main.dart';

void main() => runApp(const HandwashPreviewApp());

class HandwashPreviewApp extends StatelessWidget {
  const HandwashPreviewApp({super.key});

  @override
  Widget build(BuildContext context) => MaterialApp(
    debugShowCheckedModeBanner: false,
    builder: (context, child) => AppViewport(child: child ?? const SizedBox()),
    theme: ThemeData(
      colorScheme: ColorScheme.fromSeed(seedColor: const Color(0xff3b7d6a)),
      scaffoldBackgroundColor: const Color(0xfffffbf5),
      useMaterial3: true,
    ),
    home: const _HandwashPreviewLoader(),
  );
}

class _HandwashPreviewLoader extends StatefulWidget {
  const _HandwashPreviewLoader();

  @override
  State<_HandwashPreviewLoader> createState() => _HandwashPreviewLoaderState();
}

class _HandwashPreviewLoaderState extends State<_HandwashPreviewLoader> {
  IndependenceLevel? _level;

  Future<List<ActionCard>> _loadCards() async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final cards =
        (jsonDecode(raw) as Map<String, dynamic>)['cards'] as List<dynamic>;
    return cards.cast<Map<String, dynamic>>().map(ActionCard.fromJson).toList();
  }

  @override
  Widget build(BuildContext context) => FutureBuilder<List<ActionCard>>(
    future: _loadCards(),
    builder: (context, snapshot) {
      if (!snapshot.hasData) {
        return const Scaffold(body: Center(child: CircularProgressIndicator()));
      }
      final cardById = {for (final card in snapshot.data!) card.id: card};
      final handwash = cardById['H-01']!;
      return ChildCardPage(
        card: handwash,
        initialLevel: _level,
        onLevelSelected: (level) => setState(() => _level = level),
        onOpenParentMode: () => Navigator.of(context).push<void>(
          MaterialPageRoute(
            builder: (_) => ParentCardPage(card: handwash, cardById: cardById),
          ),
        ),
      );
    },
  );
}
