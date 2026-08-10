import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

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
    required this.prerequisiteCardIds,
    required this.nextActionCardIds,
  });

  factory ActionCard.fromJson(Map<String, dynamic> json) => ActionCard(
    id: json['cardId'] as String,
    category: json['category'] as String,
    title: json['titleKo'] as String,
    childTitle: json['childTitle'] as String,
    parentGuide: json['parentGuide'] as String,
    prerequisiteCardIds: List<String>.from(
      json['prerequisiteCardIds'] as List<dynamic>,
    ),
    nextActionCardIds: List<String>.from(
      json['nextActionCardIds'] as List<dynamic>,
    ),
  );

  final String id;
  final String category;
  final String title;
  final String childTitle;
  final String parentGuide;
  final List<String> prerequisiteCardIds;
  final List<String> nextActionCardIds;
}

class ActionLibraryPage extends StatefulWidget {
  const ActionLibraryPage({super.key});

  @override
  State<ActionLibraryPage> createState() => _ActionLibraryPageState();
}

class _ActionLibraryPageState extends State<ActionLibraryPage> {
  static const _storageKey = 'action_card_levels_v1';
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
  bool _parentMode = false;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _loadProgress();
  }

  Future<List<ActionCard>> _loadCards() async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final decoded = jsonDecode(raw) as Map<String, dynamic>;
    return (decoded['cards'] as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .map(ActionCard.fromJson)
        .toList(growable: false);
  }

  Future<void> _loadProgress() async {
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString(_storageKey);
    if (saved != null) {
      final values = jsonDecode(saved) as Map<String, dynamic>;
      for (final entry in values.entries) {
        final level = IndependenceLevel.values.where(
          (item) => item.name == entry.value,
        );
        if (level.isNotEmpty) {
          _levels[entry.key] = level.first;
        }
      }
    }
    if (mounted) {
      setState(() => _isLoadingProgress = false);
    }
  }

  Future<void> _saveLevel(ActionCard card, IndependenceLevel level) async {
    setState(() => _levels[card.id] = level);
    final preferences = await SharedPreferences.getInstance();
    final encoded = _levels.map((id, value) => MapEntry(id, value.name));
    await preferences.setString(_storageKey, jsonEncode(encoded));
  }

  Future<void> _selectLevel(ActionCard card) async {
    final selected = await Navigator.of(context).push<IndependenceLevel>(
      MaterialPageRoute(
        builder: (_) =>
            ChildCardPage(card: card, initialLevel: _levels[card.id]),
      ),
    );
    if (selected != null) {
      await _saveLevel(card, selected);
    }
  }

  void _showParentGuide(ActionCard card, Map<String, ActionCard> cardById) {
    Navigator.of(context).push<void>(
      MaterialPageRoute(
        builder: (_) => ParentCardPage(card: card, cardById: cardById),
      ),
    );
  }

  String _levelLabel(IndependenceLevel level) => switch (level) {
    IndependenceLevel.independent => '🟢 혼자 해봤어요',
    IndependenceLevel.withSupport => '🟡 같이 해봤어요',
    IndependenceLevel.notYet => '⚪ 아직 안 해봤어요',
  };

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      appBar: AppBar(
        title: Text(_parentMode ? 'GrowUp 부모 모드' : 'GrowUp'),
        centerTitle: false,
        actions: [
          TextButton.icon(
            onPressed: () => setState(() => _parentMode = !_parentMode),
            icon: Icon(_parentMode ? Icons.child_care : Icons.family_restroom),
            label: Text(_parentMode ? '아이 모드' : '부모 모드'),
          ),
        ],
      ),
      body: FutureBuilder<List<ActionCard>>(
        future: _cardsFuture,
        builder: (context, snapshot) {
          if (snapshot.hasError) {
            return const Center(child: Text('카드를 불러오지 못했어요.'));
          }
          if (!snapshot.hasData || _isLoadingProgress) {
            return const Center(child: CircularProgressIndicator());
          }
          final cards = snapshot.data!;
          final cardById = {for (final card in cards) card.id: card};
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
                  _parentMode ? '행동을 관찰하고 다음을 살펴보세요.' : '오늘 어떤 행동을 해볼까요?',
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
                          _parentMode ? card.title : card.childTitle,
                          style: Theme.of(context).textTheme.titleLarge,
                        ),
                        subtitle: Padding(
                          padding: const EdgeInsets.only(top: 6),
                          child: Text(
                            _parentMode
                                ? level == null
                                      ? '아직 기록이 없어요 · 눌러서 가이드를 봐요'
                                      : _levelLabel(level)
                                : level == null
                                ? '눌러서 상태를 골라요'
                                : _levelLabel(level),
                          ),
                        ),
                        trailing: const Icon(Icons.chevron_right),
                        onTap: () => _parentMode
                            ? _showParentGuide(card, cardById)
                            : _selectLevel(card),
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

class _RelatedActions extends StatelessWidget {
  const _RelatedActions({
    required this.title,
    required this.ids,
    required this.cardById,
  });

  final String title;
  final List<String> ids;
  final Map<String, ActionCard> cardById;

  @override
  Widget build(BuildContext context) {
    final labels = ids.map((id) => cardById[id]?.title ?? id).toList();
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Text(title, style: Theme.of(context).textTheme.titleMedium),
        const SizedBox(height: 8),
        Text(labels.isEmpty ? '없음' : labels.join(' · ')),
      ],
    );
  }
}

class ChildCardPage extends StatelessWidget {
  const ChildCardPage({
    super.key,
    required this.card,
    required this.initialLevel,
  });

  final ActionCard card;
  final IndependenceLevel? initialLevel;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: Padding(
          padding: const EdgeInsets.all(20),
          child: Column(
            children: [
              Row(
                children: [
                  IconButton(
                    onPressed: () => Navigator.pop(context),
                    icon: const Icon(Icons.arrow_back),
                  ),
                  const Expanded(child: _ProgressDots()),
                  const Icon(Icons.star_rounded, color: Color(0xffffc943)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(child: ActionIllustration(card: card, large: true)),
              Text(
                card.childTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _ChildStatusButton(
                    level: IndependenceLevel.independent,
                    selected: initialLevel,
                    onTap: () =>
                        Navigator.pop(context, IndependenceLevel.independent),
                  ),
                  _ChildStatusButton(
                    level: IndependenceLevel.withSupport,
                    selected: initialLevel,
                    onTap: () =>
                        Navigator.pop(context, IndependenceLevel.withSupport),
                  ),
                  _ChildStatusButton(
                    level: IndependenceLevel.notYet,
                    selected: initialLevel,
                    onTap: () =>
                        Navigator.pop(context, IndependenceLevel.notYet),
                  ),
                ],
              ),
            ],
          ),
        ),
      ),
    );
  }
}

class ParentCardPage extends StatelessWidget {
  const ParentCardPage({super.key, required this.card, required this.cardById});

  final ActionCard card;
  final Map<String, ActionCard> cardById;

  @override
  Widget build(BuildContext context) {
    return Scaffold(
      body: SafeArea(
        child: ListView(
          padding: const EdgeInsets.all(24),
          children: [
            Row(
              children: [
                IconButton(
                  onPressed: () => Navigator.pop(context),
                  icon: const Icon(Icons.arrow_back),
                ),
                const Spacer(),
                const Icon(Icons.edit_outlined),
              ],
            ),
            const SizedBox(height: 12),
            Row(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                SizedBox(
                  width: 150,
                  height: 150,
                  child: ActionIllustration(card: card),
                ),
                const SizedBox(width: 18),
                Expanded(
                  child: Column(
                    crossAxisAlignment: CrossAxisAlignment.start,
                    children: [
                      Text(
                        card.id,
                        style: const TextStyle(
                          color: Color(0xff378b45),
                          fontWeight: FontWeight.bold,
                        ),
                      ),
                      Text(
                        card.title,
                        style: Theme.of(context).textTheme.headlineMedium,
                      ),
                      const SizedBox(height: 8),
                      Text(card.parentGuide),
                    ],
                  ),
                ),
              ],
            ),
            const Divider(height: 36),
            Text('성공 기준', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 12),
            const Row(
              children: [
                Expanded(
                  child: _Criterion(
                    color: Color(0xff55ae52),
                    title: '혼자',
                    text: '모든 과정을 스스로 해요.',
                  ),
                ),
                Expanded(
                  child: _Criterion(
                    color: Color(0xffffc63d),
                    title: '같이',
                    text: '안내나 도움과 함께 해요.',
                  ),
                ),
                Expanded(
                  child: _Criterion(
                    color: Color(0xffc9c9c4),
                    title: '안 해봤어요',
                    text: '아직 시도해 본 적이 없어요.',
                  ),
                ),
              ],
            ),
            const Divider(height: 36),
            _RelatedActions(
              title: '선행 행동',
              ids: card.prerequisiteCardIds,
              cardById: cardById,
            ),
            const Divider(height: 28),
            _RelatedActions(
              title: '다음 추천 행동',
              ids: card.nextActionCardIds,
              cardById: cardById,
            ),
            const Divider(height: 28),
            Text('부모 팁', style: Theme.of(context).textTheme.titleMedium),
            const SizedBox(height: 8),
            Container(
              padding: const EdgeInsets.all(16),
              decoration: BoxDecoration(
                color: const Color(0xffeff8e9),
                borderRadius: BorderRadius.circular(12),
              ),
              child: const Text(
                '처음부터 완벽하게 해내는 것이 목표는 아니에요. 아이가 스스로 시도할 시간을 충분히 기다려 주세요.',
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class ActionIllustration extends StatelessWidget {
  const ActionIllustration({super.key, required this.card, this.large = false});
  final ActionCard card;
  final bool large;
  @override
  Widget build(BuildContext context) => Container(
    decoration: BoxDecoration(
      color: const Color(0xfff4f0e8),
      borderRadius: BorderRadius.circular(28),
    ),
    child: Center(
      child: Icon(
        _iconFor(card.category),
        size: large ? 150 : 72,
        color: const Color(0xff478bc2),
      ),
    ),
  );
  IconData _iconFor(String category) => switch (category) {
    'hygiene' => Icons.soap_outlined,
    'dressing' => Icons.checkroom_outlined,
    'meals' => Icons.restaurant_outlined,
    'belongings_home' => Icons.home_outlined,
    'outing' => Icons.backpack_outlined,
    _ => Icons.health_and_safety_outlined,
  };
}

class _ChildStatusButton extends StatelessWidget {
  const _ChildStatusButton({
    required this.level,
    required this.selected,
    required this.onTap,
  });
  final IndependenceLevel level;
  final IndependenceLevel? selected;
  final VoidCallback onTap;
  @override
  Widget build(BuildContext context) {
    final (color, icon, label) = switch (level) {
      IndependenceLevel.independent => (
        const Color(0xff55ae52),
        Icons.sentiment_satisfied_alt,
        '혼자\n할 수 있어요',
      ),
      IndependenceLevel.withSupport => (
        const Color(0xffffc63d),
        Icons.group,
        '같이\n하면 좋아요',
      ),
      IndependenceLevel.notYet => (
        const Color(0xffc9c9c4),
        Icons.question_mark,
        '안 해봤어요',
      ),
    };
    return Expanded(
      child: InkWell(
        onTap: onTap,
        child: Column(
          children: [
            CircleAvatar(
              radius: 42,
              backgroundColor: color,
              child: Icon(icon, color: Colors.white, size: 42),
            ),
            const SizedBox(height: 10),
            Text(
              label,
              textAlign: TextAlign.center,
              style: TextStyle(
                fontWeight: selected == level
                    ? FontWeight.bold
                    : FontWeight.normal,
              ),
            ),
          ],
        ),
      ),
    );
  }
}

class _Criterion extends StatelessWidget {
  const _Criterion({
    required this.color,
    required this.title,
    required this.text,
  });
  final Color color;
  final String title;
  final String text;
  @override
  Widget build(BuildContext context) => Padding(
    padding: const EdgeInsets.symmetric(horizontal: 6),
    child: Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            CircleAvatar(radius: 7, backgroundColor: color),
            const SizedBox(width: 6),
            Text(
              title,
              style: TextStyle(color: color, fontWeight: FontWeight.bold),
            ),
          ],
        ),
        const SizedBox(height: 8),
        Text(text),
      ],
    ),
  );
}

class _ProgressDots extends StatelessWidget {
  const _ProgressDots();
  @override
  Widget build(BuildContext context) => Row(
    mainAxisAlignment: MainAxisAlignment.center,
    children: List.generate(
      4,
      (index) => Container(
        margin: const EdgeInsets.symmetric(horizontal: 3),
        height: 8,
        width: 52,
        decoration: BoxDecoration(
          color: index == 0 ? const Color(0xff55ae52) : const Color(0xffeceae2),
          borderRadius: BorderRadius.circular(10),
        ),
      ),
    ),
  );
}
