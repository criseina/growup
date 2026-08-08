import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';

void main() {
  runApp(const GrowUpApp());
}

class GrowUpApp extends StatelessWidget {
  const GrowUpApp({super.key});

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      title: 'GrowUp',
      debugShowCheckedModeBanner: false,
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3b7d6a),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffffbf5),
        useMaterial3: true,
      ),
      home: const ActionLibraryPage(),
    );
  }
}

enum IndependenceLevel { independent, withSupport, notYet }

class ActionCard {
  const ActionCard({
    required this.id,
    required this.category,
    required this.title,
    required this.childTitle,
    required this.parentGuide,
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) => ActionCard(
    id: json['cardId'] as String,
    category: json['category'] as String,
    title: json['titleKo'] as String,
    childTitle: json['childTitle'] as String,
    parentGuide: json['parentGuide'] as String,
  );

  final String id;
  final String category;
  final String title;
  final String childTitle;
  final String parentGuide;
}

class ActionLibraryPage extends StatefulWidget {
  const ActionLibraryPage({super.key});

  @override
  State<ActionLibraryPage> createState() => _ActionLibraryPageState();
}

class _ActionLibraryPageState extends State<ActionLibraryPage> {
  static const categoryLabels = <String, String>{
    'hygiene': '개인 위생',
    'dressing': '옷 입기',
    'meals': '식사',
    'belongings_home': '물건과 집안일',
    'outing': '외출 준비',
    'safety_help': '안전과 도움 요청',
  };

  late final Future<List<ActionCard>> _cardsFuture = _loadCards();
  final Map<String, IndependenceLevel> _levels = {};
  String? _selectedCategory;

  Future<List<ActionCard>> _loadCards() async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['cards'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ActionCard.fromJson)
        .toList(growable: false);
  }

  void _selectLevel(ActionCard card) async {
    final selected = await showModalBottomSheet<IndependenceLevel>(
      context: context,
      showDragHandle: true,
      builder: (context) => SafeArea(
        child: Padding(
          padding: const EdgeInsets.fromLTRB(24, 0, 24, 24),
          child: Column(
            mainAxisSize: MainAxisSize.min,
            crossAxisAlignment: CrossAxisAlignment.stretch,
            children: [
              Text(
                card.childTitle,
                style: Theme.of(context).textTheme.headlineSmall,
              ),
              const SizedBox(height: 8),
              const Text('오늘은 어떻게 해봤나요?'),
              const SizedBox(height: 16),
              for (final level in IndependenceLevel.values)
                Padding(
                  padding: const EdgeInsets.only(bottom: 8),
                  child: FilledButton.tonal(
                    onPressed: () => Navigator.pop(context, level),
                    child: Text(_levelLabel(level)),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
    if (selected != null) {
      setState(() => _levels[card.id] = selected);
    }
  }

  String _levelLabel(IndependenceLevel level) => switch (level) {
    IndependenceLevel.independent => '🟢 혼자 해봤어요',
    IndependenceLevel.withSupport => '🟡 같이 해봤어요',
    IndependenceLevel.notYet => '⚪ 아직 안 해봤어요',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(title: const Text('GrowUp'), centerTitle: false),
      body: FutureBuilder<List<ActionCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('카드를 불러오지 못했어요.'));
          }
          if (!snapshot.hasData) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snapshot.data!;
          final visibleCards = _selectedCategory == null
              ? cards
              : cards
                    .where((card) => card.category == _selectedCategory)
                    .toList();
          return Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Padding(
                padding: const EdgeInsets.fromLTRB(20, 12, 20, 4),
                child: Text(
                  '오늘 어떤 행동을 해볼까요?',
                  style: Theme.of(context).textTheme.headlineSmall,
                ),
              ),
              Padding(
                padding: const EdgeInsets.symmetric(horizontal: 16),
                child: SingleChildScrollView(
                  scrollDirection: Axis.horizontal,
                  child: Row(
                    children: [
                      ChoiceChip(
                        label: const Text('전체'),
                        selected: _selectedCategory == null,
                        onSelected: (_) =>
                            setState(() => _selectedCategory = null),
                      ),
                      for (final entry in categoryLabels.entries)
                        Padding(
                          padding: const EdgeInsets.only(left: 8),
                          child: ChoiceChip(
                            label: Text(entry.value),
                            selected: _selectedCategory == entry.key,
                            onSelected: (_) =>
                                setState(() => _selectedCategory = entry.key),
                          ),
                        ),
                    ],
                  ),
                ),
              ),
              Expanded(
                child: ListView.separated(
                  padding: const EdgeInsets.all(16),
                  itemCount: visibleCards.length,
                  separatorBuilder: (_, _) => const SizedBox(height: 10),
                  itemBuilder: (context, index) {
                    final card = visibleCards[index];
                    final level = _levels[card.id];
                    return Card(
                      clipBehavior: Clip.antiAlias,
                      child: ListTile(
                        contentPadding: const EdgeInsets.all(18),
                        leading: CircleAvatar(
                          backgroundColor: Theme.of(
                            context,
                          ).colorScheme.primaryContainer,
                          child: Icon(_categoryIcon(card.category)),
                        ),
                        title: Text(
                          card.childTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            level == null ? '눌러서 상태를 골라요' : _levelLabel(level),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _selectLevel(card),
                      ),
                    );
                  },
                ),
              ),
            ],
          );
        },
      ),
    );
  }

  IconData _categoryIcon(String category) => switch (category) {
    'hygiene' => Icons.water_drop_outlined,
    'dressing' => Icons.checkroom_outlined,
    'meals' => Icons.restaurant_outlined,
    'belongings_home' => Icons.home_outlined,
    'outing' => Icons.backpack_outlined,
    'safety_help' => Icons.health_and_safety_outlined,
    _ => Icons.star_outline,
  };
}
