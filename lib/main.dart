import 'dart:convert';

import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:shared_preferences/shared_preferences.dart';

import 'card_detail_content.dart';
import 'onboarding_page.dart';
import 'profile_page.dart';
import 'profile_repository.dart';

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
      builder: (context, child) =>
          AppViewport(child: child ?? const SizedBox()),
      theme: ThemeData(
        colorScheme: ColorScheme.fromSeed(
          seedColor: const Color(0xff3b7d6a),
          brightness: Brightness.light,
        ),
        scaffoldBackgroundColor: const Color(0xfffffbf5),
        useMaterial3: true,
      ),
      home: const _AppEntry(),
    );
  }
}

class _AppEntry extends StatefulWidget {
  const _AppEntry();

  @override
  State<_AppEntry> createState() => _AppEntryState();
}

class _AppEntryState extends State<_AppEntry> {
  bool? _isOnboardingComplete;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    if (mounted) {
      setState(
        () => _isOnboardingComplete =
            preferences.getBool('onboarding_completed_v1') ?? false,
      );
    }
  }

  @override
  Widget build(BuildContext context) {
    if (_isOnboardingComplete == null) {
      return const Scaffold(body: Center(child: CircularProgressIndicator()));
    }
    return _isOnboardingComplete!
        ? const HomePage()
        : OnboardingPage(
            onComplete: () => setState(() => _isOnboardingComplete = true),
          );
  }
}

/// 실제 휴대폰에서는 전체 폭을 쓰고, 브라우저/태블릿에서는 420px 폭의
/// 휴대폰 화면처럼 가운데에 표시한다.
class AppViewport extends StatelessWidget {
  const AppViewport({super.key, required this.child});
  final Widget child;

  @override
  Widget build(BuildContext context) => LayoutBuilder(
    builder: (context, constraints) {
      if (constraints.maxWidth <= 520) return child;
      return ColoredBox(
        color: const Color(0xffeef8e9),
        child: Center(
          child: ConstrainedBox(
            constraints: const BoxConstraints(maxWidth: 420),
            child: Material(
              elevation: 12,
              borderRadius: BorderRadius.circular(32),
              clipBehavior: Clip.antiAlias,
              child: child,
            ),
          ),
        ),
      );
    },
  );
}

class HomePage extends StatefulWidget {
  const HomePage({super.key});

  @override
  State<HomePage> createState() => _HomePageState();
}

class _HomePageState extends State<HomePage> {
  final _profiles = ProfileRepository();
  ChildProfile _activeProfile = ProfileRepository.defaultProfile;
  ActionCard? _recommendation;
  String _recommendationReason = '오늘 새로 해볼 행동이에요.';

  @override
  void initState() {
    super.initState();
    _loadProfile();
  }

  Future<void> _loadProfile() async {
    final profile = await _profiles.loadActiveProfile();
    if (mounted) setState(() => _activeProfile = profile);
    await _loadRecommendation(profile);
  }

  Future<void> _loadRecommendation(ChildProfile profile) async {
    final raw = await rootBundle.loadString('data/action_cards_v1.json');
    final cards =
        ((jsonDecode(raw) as Map<String, dynamic>)['cards'] as List<dynamic>)
            .cast<Map<String, dynamic>>()
            .map(ActionCard.fromJson)
            .toList();
    final preferences = await SharedPreferences.getInstance();
    final saved = preferences.getString('action_card_levels_v1_${profile.id}');
    final levels = saved == null
        ? <String, String>{}
        : Map<String, String>.from(jsonDecode(saved) as Map<String, dynamic>);
    final candidate = cards.cast<ActionCard?>().firstWhere(
      (card) =>
          card != null &&
          levels[card.id] != 'independent' &&
          card.prerequisiteCardIds.every((id) => levels[id] == 'independent'),
      orElse: () => cards.first,
    );
    if (candidate == null || !mounted) return;
    final currentLevel = levels[candidate.id];
    setState(() {
      _recommendation = candidate;
      _recommendationReason = currentLevel == 'withSupport'
          ? '함께 해본 행동이에요. 오늘은 조금 더 스스로 해볼까요?'
          : currentLevel == 'notYet'
          ? '아직 낯선 행동이에요. 부담 없이 한 단계만 해봐요.'
          : '오늘 처음 해볼 행동이에요.';
    });
  }

  @override
  Widget build(BuildContext context) => Scaffold(
    body: SafeArea(
      child: Padding(
        padding: const EdgeInsets.all(24),
        child: Column(
          crossAxisAlignment: CrossAxisAlignment.start,
          children: [
            const SizedBox(height: 18),
            Row(
              children: [
                Text('GrowUp', style: Theme.of(context).textTheme.titleLarge),
                const Spacer(),
                TextButton.icon(
                  onPressed: () async {
                    await Navigator.of(context).push(
                      MaterialPageRoute(
                        builder: (_) =>
                            ProfilePage(activeProfile: _activeProfile),
                      ),
                    );
                    await _loadProfile();
                  },
                  icon: const Icon(Icons.face_outlined),
                  label: Text(_activeProfile.name),
                ),
              ],
            ),
            const SizedBox(height: 34),
            Text(
              '오늘 어떤 걸\n해볼까?',
              style: Theme.of(context).textTheme.displaySmall,
            ),
            const SizedBox(height: 14),
            const Text('잘했는지 평가하지 않아요. 오늘 해보고 싶은 행동을 골라요.'),
            const SizedBox(height: 32),
            if (_recommendation != null)
              _TodayRecommendation(
                card: _recommendation!,
                reason: _recommendationReason,
                onTap: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActionLibraryPage(
                      profileId: _activeProfile.id,
                      initialCategory: _recommendation!.category,
                    ),
                  ),
                ),
              ),
            if (_recommendation != null) const SizedBox(height: 14),
            _HomeAction(
              icon: Icons.auto_awesome,
              title: '오늘 해볼 행동',
              subtitle: '카드를 보고 상태를 골라요',
              color: const Color(0xffe5f5dc),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      ActionLibraryPage(profileId: _activeProfile.id),
                ),
              ),
            ),
            const SizedBox(height: 14),
            _HomeAction(
              icon: Icons.menu_book_outlined,
              title: '내 성장 기록',
              subtitle: '내가 해본 행동을 살펴봐요',
              color: const Color(0xfffff1c9),
              onTap: () => Navigator.of(context).push(
                MaterialPageRoute(
                  builder: (_) =>
                      GrowthRecordPage(profileId: _activeProfile.id),
                ),
              ),
            ),
            const Spacer(),
            Center(
              child: TextButton.icon(
                onPressed: () => Navigator.of(context).push(
                  MaterialPageRoute(
                    builder: (_) => ActionLibraryPage(
                      parentMode: true,
                      profileId: _activeProfile.id,
                    ),
                  ),
                ),
                icon: const Icon(Icons.family_restroom_outlined),
                label: const Text('부모 모드'),
              ),
            ),
          ],
        ),
      ),
    ),
  );
}

class _TodayRecommendation extends StatelessWidget {
  const _TodayRecommendation({
    required this.card,
    required this.reason,
    required this.onTap,
  });

  final ActionCard card;
  final String reason;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    color: const Color(0xffeff8e9),
    child: InkWell(
      onTap: onTap,
      borderRadius: BorderRadius.circular(12),
      child: Padding(
        padding: const EdgeInsets.all(14),
        child: Row(
          children: [
            const CircleAvatar(
              backgroundColor: Color(0xff55ae52),
              foregroundColor: Colors.white,
              child: Icon(Icons.auto_awesome),
            ),
            const SizedBox(width: 12),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  const Text(
                    '오늘의 추천 행동',
                    style: TextStyle(
                      color: Color(0xff28753c),
                      fontWeight: FontWeight.bold,
                    ),
                  ),
                  Text(
                    card.childTitle,
                    style: Theme.of(context).textTheme.titleLarge,
                  ),
                  Text(reason),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class _HomeAction extends StatelessWidget {
  const _HomeAction({
    required this.icon,
    required this.title,
    required this.subtitle,
    required this.color,
    required this.onTap,
  });
  final IconData icon;
  final String title;
  final String subtitle;
  final Color color;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(20),
        child: Row(
          children: [
            CircleAvatar(
              radius: 28,
              backgroundColor: color,
              child: Icon(icon, size: 28),
            ),
            const SizedBox(width: 16),
            Expanded(
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(title, style: Theme.of(context).textTheme.titleLarge),
                  const SizedBox(height: 4),
                  Text(subtitle),
                ],
              ),
            ),
            const Icon(Icons.chevron_right),
          ],
        ),
      ),
    ),
  );
}

class GrowthRecordPage extends StatefulWidget {
  const GrowthRecordPage({
    super.key,
    this.profileId = ProfileRepository.defaultProfileId,
  });
  final String profileId;

  @override
  State<GrowthRecordPage> createState() => _GrowthRecordPageState();
}

class _GrowthRecordPageState extends State<GrowthRecordPage> {
  List<Map<String, dynamic>> _records = [];
  Map<String, ActionCard> _cardsById = {};
  String? _categoryFilter;
  String? _levelFilter;
  int? _periodDays;

  List<Map<String, dynamic>> get _filteredRecords => _records.where((record) {
    final card = _cardsById[record['cardId']];
    final categoryMatches =
        _categoryFilter == null || card?.category == _categoryFilter;
    final levelMatches =
        _levelFilter == null || record['level'] == _levelFilter;
    final observedAt = DateTime.tryParse(record['observedAt'] as String);
    final periodMatches =
        _periodDays == null ||
        (observedAt != null &&
            !observedAt.isBefore(
              DateTime.now().subtract(Duration(days: _periodDays!)),
            ));
    return categoryMatches && levelMatches && periodMatches;
  }).toList();

  int _countFor(String level) =>
      _filteredRecords.where((record) => record['level'] == level).length;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('action_observations_v1');
    final cardsRaw = await rootBundle.loadString('data/action_cards_v1.json');
    final cards =
        (jsonDecode(cardsRaw) as Map<String, dynamic>)['cards']
            as List<dynamic>;
    final cardById = {
      for (final card in cards.cast<Map<String, dynamic>>())
        card['cardId'] as String: ActionCard.fromJson(card),
    };
    final records = raw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .where(
                (record) =>
                    (record['profileId'] ??
                        ProfileRepository.defaultProfileId) ==
                    widget.profileId,
              )
              .toList()
              .reversed
              .toList();
    if (mounted) {
      setState(() {
        _cardsById = cardById;
        _records = records;
      });
    }
  }

  Future<void> _editRecord(Map<String, dynamic> record) async {
    var selectedLevel = record['level'] as String;
    final noteController = TextEditingController(
      text: record['note'] as String? ?? '',
    );
    final updated = await showDialog<Map<String, dynamic>>(
      context: context,
      builder: (context) => StatefulBuilder(
        builder: (context, setDialogState) => AlertDialog(
          title: const Text('관찰 기록 수정'),
          content: Column(
            mainAxisSize: MainAxisSize.min,
            children: [
              Wrap(
                spacing: 8,
                runSpacing: 8,
                children: [
                  for (final level in const [
                    'independent',
                    'withSupport',
                    'notYet',
                  ])
                    ChoiceChip(
                      label: Text(_level(level)),
                      selected: selectedLevel == level,
                      onSelected: (_) =>
                          setDialogState(() => selectedLevel = level),
                    ),
                ],
              ),
              const SizedBox(height: 12),
              TextField(
                controller: noteController,
                minLines: 2,
                maxLines: 4,
                decoration: const InputDecoration(
                  labelText: '관찰 메모 (선택)',
                  border: OutlineInputBorder(),
                ),
              ),
            ],
          ),
          actions: [
            TextButton(
              onPressed: () => Navigator.pop(context),
              child: const Text('취소'),
            ),
            FilledButton(
              onPressed: () => Navigator.pop(context, {
                ...record,
                'level': selectedLevel,
                'note': noteController.text.trim(),
              }),
              child: const Text('저장'),
            ),
          ],
        ),
      ),
    );
    noteController.dispose();
    if (updated == null) return;
    await _persistRecordChange(record, updated);
  }

  Future<void> _deleteRecord(Map<String, dynamic> record) async {
    final confirmed = await showDialog<bool>(
      context: context,
      builder: (context) => AlertDialog(
        title: const Text('기록을 삭제할까요?'),
        content: const Text('삭제한 기록은 되돌릴 수 없어요.'),
        actions: [
          TextButton(
            onPressed: () => Navigator.pop(context, false),
            child: const Text('취소'),
          ),
          FilledButton(
            onPressed: () => Navigator.pop(context, true),
            child: const Text('삭제'),
          ),
        ],
      ),
    );
    if (confirmed != true) return;
    await _persistRecordChange(record, null);
  }

  Future<void> _persistRecordChange(
    Map<String, dynamic> original,
    Map<String, dynamic>? updated,
  ) async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('action_observations_v1');
    if (raw == null) return;
    final records = (jsonDecode(raw) as List<dynamic>)
        .cast<Map<String, dynamic>>()
        .toList();
    final index = records.indexWhere(
      (item) =>
          item['cardId'] == original['cardId'] &&
          item['observedAt'] == original['observedAt'] &&
          (item['profileId'] ?? ProfileRepository.defaultProfileId) ==
              widget.profileId,
    );
    if (index == -1) return;
    if (updated == null) {
      records.removeAt(index);
    } else {
      records[index] = updated;
    }
    await preferences.setString('action_observations_v1', jsonEncode(records));
    await _load();
  }

  String _level(String value) => switch (value) {
    'independent' => '🟢 혼자 해봤어요',
    'withSupport' => '🟡 같이 해봤어요',
    _ => '⚪ 아직 안 해봤어요',
  };

  @override
  Widget build(BuildContext context) => Scaffold(
    appBar: AppBar(
      title: const Text('내 성장 기록'),
      bottom: PreferredSize(
        preferredSize: const Size.fromHeight(122),
        child: Padding(
          padding: const EdgeInsets.fromLTRB(16, 0, 16, 12),
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              _RecordSummary(
                total: _filteredRecords.length,
                independent: _countFor('independent'),
                withSupport: _countFor('withSupport'),
                notYet: _countFor('notYet'),
              ),
              const SizedBox(height: 8),
              SingleChildScrollView(
                scrollDirection: Axis.horizontal,
                child: Row(
                  children: [
                    ChoiceChip(
                      label: const Text('전체'),
                      selected: _categoryFilter == null,
                      onSelected: (_) => setState(() => _categoryFilter = null),
                    ),
                    const SizedBox(width: 6),
                    for (final period in const <int?>[null, 7, 30]) ...[
                      FilterChip(
                        label: Text(period == null ? '전체 기간' : '최근 $period일'),
                        selected: _periodDays == period,
                        onSelected: (_) => setState(() => _periodDays = period),
                      ),
                      const SizedBox(width: 6),
                    ],
                    for (final category
                        in _cardsById.values
                            .map((card) => card.category)
                            .toSet()) ...[
                      ChoiceChip(
                        label: Text(
                          _ActionLibraryPageState.categoryLabels[category] ??
                              category,
                        ),
                        selected: _categoryFilter == category,
                        onSelected: (_) => setState(
                          () => _categoryFilter = _categoryFilter == category
                              ? null
                              : category,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                    for (final level in const [
                      'independent',
                      'withSupport',
                      'notYet',
                    ]) ...[
                      FilterChip(
                        label: Text(_level(level)),
                        selected: _levelFilter == level,
                        onSelected: (_) => setState(
                          () => _levelFilter = _levelFilter == level
                              ? null
                              : level,
                        ),
                      ),
                      const SizedBox(width: 6),
                    ],
                  ],
                ),
              ),
            ],
          ),
        ),
      ),
    ),
    body: _records.isEmpty
        ? const Center(
            child: Text(
              '아직 기록이 없어요.\n오늘 해본 행동부터 골라볼까요?',
              textAlign: TextAlign.center,
            ),
          )
        : ListView.separated(
            padding: const EdgeInsets.all(20),
            itemCount: _filteredRecords.length,
            separatorBuilder: (_, _) => const Divider(),
            itemBuilder: (context, index) {
              final record = _filteredRecords[index];
              final date = DateTime.tryParse(
                record['observedAt'] as String,
              )?.toLocal();
              final time = date == null
                  ? ''
                  : '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
              return ListTile(
                onTap: () {
                  final card = _cardsById[record['cardId']];
                  if (card == null) return;
                  Navigator.push(
                    context,
                    MaterialPageRoute(
                      builder: (_) => ParentCardPage(
                        card: card,
                        cardById: _cardsById,
                        profileId: widget.profileId,
                      ),
                    ),
                  );
                },
                leading: const Icon(
                  Icons.favorite_outline,
                  color: Color(0xff55ae52),
                ),
                title: Text(
                  _cardsById[record['cardId']]?.title ??
                      record['cardId'] as String,
                ),
                subtitle: Text(
                  '${_level(record['level'] as String)}\n$time'
                  '${(record['note'] as String? ?? '').isEmpty ? '' : '\n${record['note']}'}',
                ),
                trailing: PopupMenuButton<_RecordMenuAction>(
                  icon: const Icon(Icons.more_vert),
                  onSelected: (action) => action == _RecordMenuAction.edit
                      ? _editRecord(record)
                      : _deleteRecord(record),
                  itemBuilder: (context) => const [
                    PopupMenuItem(
                      value: _RecordMenuAction.edit,
                      child: Text('수정'),
                    ),
                    PopupMenuItem(
                      value: _RecordMenuAction.delete,
                      child: Text('삭제'),
                    ),
                  ],
                ),
              );
            },
          ),
  );
}

class _RecordSummary extends StatelessWidget {
  const _RecordSummary({
    required this.total,
    required this.independent,
    required this.withSupport,
    required this.notYet,
  });

  final int total;
  final int independent;
  final int withSupport;
  final int notYet;

  @override
  Widget build(BuildContext context) => Row(
    children: [
      _SummaryCount(label: '전체', count: total, color: const Color(0xff3b7d6a)),
      _SummaryCount(
        label: '혼자',
        count: independent,
        color: const Color(0xff55ae52),
      ),
      _SummaryCount(
        label: '같이',
        count: withSupport,
        color: const Color(0xffffc63d),
      ),
      _SummaryCount(label: '아직', count: notYet, color: const Color(0xff999999)),
    ],
  );
}

class _SummaryCount extends StatelessWidget {
  const _SummaryCount({
    required this.label,
    required this.count,
    required this.color,
  });

  final String label;
  final int count;
  final Color color;

  @override
  Widget build(BuildContext context) => Expanded(
    child: Container(
      margin: const EdgeInsets.only(right: 6),
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: BoxDecoration(
        color: color.withValues(alpha: 0.12),
        borderRadius: BorderRadius.circular(12),
      ),
      child: Column(
        children: [
          Text('$count', style: Theme.of(context).textTheme.titleMedium),
          Text(label, style: TextStyle(color: color, fontSize: 12)),
        ],
      ),
    ),
  );
}

enum _RecordMenuAction { edit, delete }

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
  const ActionLibraryPage({
    super.key,
    this.parentMode = false,
    this.profileId = ProfileRepository.defaultProfileId,
    this.initialCategory,
  });
  final bool parentMode;
  final String profileId;
  final String? initialCategory;

  @override
  State<ActionLibraryPage> createState() => _ActionLibraryPageState();
}

class _ActionLibraryPageState extends State<ActionLibraryPage> {
  static const _storageKey = 'action_card_levels_v1';
  static const _observationStorageKey = 'action_observations_v1';
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
  late bool _parentMode = widget.parentMode;
  bool _isLoadingProgress = true;

  @override
  void initState() {
    super.initState();
    _selectedCategory = widget.initialCategory;
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
    final saved = preferences.getString('${_storageKey}_${widget.profileId}');
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
    await preferences.setString(
      '${_storageKey}_${widget.profileId}',
      jsonEncode(encoded),
    );
    final saved = preferences.getString(_observationStorageKey);
    final history = saved == null
        ? <dynamic>[]
        : List<dynamic>.from(jsonDecode(saved) as List<dynamic>);
    history.add({
      'cardId': card.id,
      'profileId': widget.profileId,
      'level': level.name,
      'observedAt': DateTime.now().toIso8601String(),
    });
    if (history.length > 100) history.removeRange(0, history.length - 100);
    await preferences.setString(_observationStorageKey, jsonEncode(history));
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
        builder: (_) => ParentCardPage(
          card: card,
          cardById: cardById,
          profileId: widget.profileId,
        ),
      ),
    );
  }

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
              ? <ActionCard>[]
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
              if (_selectedCategory == null)
                Expanded(
                  child: GridView.count(
                    padding: const EdgeInsets.all(20),
                    crossAxisCount: 2,
                    mainAxisSpacing: 14,
                    crossAxisSpacing: 14,
                    children: [
                      for (final entry in categoryLabels.entries)
                        _CategoryTile(
                          title: entry.value,
                          icon: _categoryIcon(entry.key),
                          onTap: () =>
                              setState(() => _selectedCategory = entry.key),
                        ),
                    ],
                  ),
                )
              else ...[
                Padding(
                  padding: const EdgeInsets.symmetric(horizontal: 12),
                  child: TextButton.icon(
                    onPressed: () => setState(() => _selectedCategory = null),
                    icon: const Icon(Icons.arrow_back),
                    label: Text(categoryLabels[_selectedCategory]!),
                  ),
                ),
                Expanded(
                  child: ListView.builder(
                    padding: const EdgeInsets.fromLTRB(20, 8, 20, 20),
                    itemCount: visibleCards.length,
                    itemBuilder: (context, index) {
                      final card = visibleCards[index];
                      return _TreeCard(
                        card: card,
                        level: _levels[card.id],
                        parentMode: _parentMode,
                        isLast: index == visibleCards.length - 1,
                        onTap: () => _parentMode
                            ? _showParentGuide(card, cardById)
                            : _selectLevel(card),
                      );
                    },
                  ),
                ),
              ],
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

class _CategoryTile extends StatelessWidget {
  const _CategoryTile({
    required this.title,
    required this.icon,
    required this.onTap,
  });
  final String title;
  final IconData icon;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => Card(
    clipBehavior: Clip.antiAlias,
    child: InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.all(16),
        child: Column(
          mainAxisAlignment: MainAxisAlignment.center,
          children: [
            CircleAvatar(
              radius: 30,
              backgroundColor: const Color(0xffe5f5dc),
              child: Icon(icon, size: 30),
            ),
            const SizedBox(height: 14),
            Text(
              title,
              textAlign: TextAlign.center,
              style: Theme.of(context).textTheme.titleMedium,
            ),
          ],
        ),
      ),
    ),
  );
}

class _TreeCard extends StatelessWidget {
  const _TreeCard({
    required this.card,
    required this.level,
    required this.parentMode,
    required this.isLast,
    required this.onTap,
  });
  final ActionCard card;
  final IndependenceLevel? level;
  final bool parentMode;
  final bool isLast;
  final VoidCallback onTap;

  String get _status => switch (level) {
    IndependenceLevel.independent => '🟢 혼자',
    IndependenceLevel.withSupport => '🟡 같이',
    IndependenceLevel.notYet => '⚪ 안 해봤어요',
    null => '아직 기록이 없어요',
  };

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 30,
        child: Column(
          children: [
            const SizedBox(height: 28),
            const CircleAvatar(radius: 7, backgroundColor: Color(0xff55ae52)),
            if (!isLast)
              const SizedBox(
                height: 100,
                child: VerticalDivider(
                  width: 2,
                  thickness: 2,
                  color: Color(0xffd9ead2),
                ),
              ),
          ],
        ),
      ),
      Expanded(
        child: Padding(
          padding: const EdgeInsets.only(bottom: 14),
          child: Card(
            child: ListTile(
              contentPadding: const EdgeInsets.all(16),
              title: Text(
                parentMode ? card.title : card.childTitle,
                style: Theme.of(context).textTheme.titleLarge,
              ),
              subtitle: Text(_status),
              trailing: const Icon(Icons.chevron_right),
              onTap: onTap,
            ),
          ),
        ),
      ),
    ],
  );
}

class ChildCardPage extends StatefulWidget {
  const ChildCardPage({
    super.key,
    required this.card,
    required this.initialLevel,
    this.onOpenParentMode,
    this.onLevelSelected,
  });

  final ActionCard card;
  final IndependenceLevel? initialLevel;
  final VoidCallback? onOpenParentMode;
  final ValueChanged<IndependenceLevel>? onLevelSelected;

  @override
  State<ChildCardPage> createState() => _ChildCardPageState();
}

class _ChildCardPageState extends State<ChildCardPage> {
  late IndependenceLevel? _selected = widget.initialLevel;

  void _select(IndependenceLevel level) {
    setState(() => _selected = level);
    if (widget.onLevelSelected != null) {
      widget.onLevelSelected!(level);
    } else {
      Navigator.pop(context, level);
    }
  }

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
                  if (widget.onOpenParentMode != null)
                    TextButton(
                      onPressed: widget.onOpenParentMode,
                      child: const Text('부모 모드'),
                    ),
                  const Icon(Icons.star_rounded, color: Color(0xffffc943)),
                ],
              ),
              const SizedBox(height: 16),
              Expanded(
                child: ActionIllustration(card: widget.card, large: true),
              ),
              Text(
                widget.card.childTitle,
                style: Theme.of(context).textTheme.displaySmall,
              ),
              const SizedBox(height: 28),
              Row(
                children: [
                  _ChildStatusButton(
                    level: IndependenceLevel.independent,
                    selected: _selected,
                    onTap: () => _select(IndependenceLevel.independent),
                  ),
                  _ChildStatusButton(
                    level: IndependenceLevel.withSupport,
                    selected: _selected,
                    onTap: () => _select(IndependenceLevel.withSupport),
                  ),
                  _ChildStatusButton(
                    level: IndependenceLevel.notYet,
                    selected: _selected,
                    onTap: () => _select(IndependenceLevel.notYet),
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
  const ParentCardPage({
    super.key,
    required this.card,
    required this.cardById,
    this.profileId = ProfileRepository.defaultProfileId,
  });

  final ActionCard card;
  final Map<String, ActionCard> cardById;
  final String profileId;

  @override
  Widget build(BuildContext context) {
    final detailContent =
        cardDetailContentById[card.id] ?? defaultCardDetailContent;
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
              child: Text(detailContent.parentTip),
            ),
            const Divider(height: 28),
            _DetailRow(label: '준비물', value: detailContent.materials),
            const Divider(height: 28),
            _DetailRow(label: '안전 주의', value: detailContent.safetyNote),
            const Divider(height: 28),
            _ObservationHistory(cardId: card.id, profileId: profileId),
            const Divider(height: 28),
            _MemoEditor(cardId: card.id, profileId: profileId),
          ],
        ),
      ),
    );
  }
}

class _DetailRow extends StatelessWidget {
  const _DetailRow({required this.label, required this.value});
  final String label;
  final String value;

  @override
  Widget build(BuildContext context) => Row(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      SizedBox(
        width: 92,
        child: Text(
          label,
          style: const TextStyle(
            color: Color(0xff28753c),
            fontWeight: FontWeight.bold,
          ),
        ),
      ),
      Expanded(child: Text(value)),
    ],
  );
}

class _MemoEditor extends StatefulWidget {
  const _MemoEditor({
    required this.cardId,
    this.profileId = ProfileRepository.defaultProfileId,
  });
  final String cardId;
  final String profileId;

  @override
  State<_MemoEditor> createState() => _MemoEditorState();
}

class _ObservationHistory extends StatefulWidget {
  const _ObservationHistory({
    required this.cardId,
    this.profileId = ProfileRepository.defaultProfileId,
  });
  final String cardId;
  final String profileId;

  @override
  State<_ObservationHistory> createState() => _ObservationHistoryState();
}

class _ObservationHistoryState extends State<_ObservationHistory> {
  List<Map<String, dynamic>> _records = [];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    final raw = preferences.getString('action_observations_v1');
    final records = raw == null
        ? <Map<String, dynamic>>[]
        : (jsonDecode(raw) as List<dynamic>)
              .cast<Map<String, dynamic>>()
              .where((record) => record['cardId'] == widget.cardId)
              .where(
                (record) =>
                    (record['profileId'] ??
                        ProfileRepository.defaultProfileId) ==
                    widget.profileId,
              )
              .toList()
              .reversed
              .take(3)
              .toList();
    if (mounted) setState(() => _records = records);
  }

  String _label(String value) => switch (value) {
    'independent' => '🟢 혼자',
    'withSupport' => '🟡 같이',
    _ => '⚪ 안 해봤어요',
  };

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '최근 기록',
        style: TextStyle(color: Color(0xff28753c), fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      if (_records.isEmpty)
        const Text('아직 기록이 없어요.')
      else
        for (final record in _records)
          Padding(
            padding: const EdgeInsets.only(bottom: 4),
            child: Text(
              '${_label(record['level'] as String)} · ${_formatDate(record['observedAt'] as String)}',
            ),
          ),
    ],
  );

  String _formatDate(String value) {
    final date = DateTime.tryParse(value)?.toLocal();
    if (date == null) return '';
    return '${date.month}월 ${date.day}일 ${date.hour.toString().padLeft(2, '0')}:${date.minute.toString().padLeft(2, '0')}';
  }
}

class _MemoEditorState extends State<_MemoEditor> {
  late final TextEditingController _controller = TextEditingController();
  bool _loaded = false;

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final preferences = await SharedPreferences.getInstance();
    _controller.text =
        preferences.getString(
          'parent_note_${widget.profileId}_${widget.cardId}',
        ) ??
        '';
    if (mounted) setState(() => _loaded = true);
  }

  Future<void> _save(String value) async {
    final preferences = await SharedPreferences.getInstance();
    await preferences.setString(
      'parent_note_${widget.profileId}_${widget.cardId}',
      value,
    );
  }

  @override
  void dispose() {
    _controller.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) => Column(
    crossAxisAlignment: CrossAxisAlignment.start,
    children: [
      const Text(
        '메모',
        style: TextStyle(color: Color(0xff28753c), fontWeight: FontWeight.bold),
      ),
      const SizedBox(height: 8),
      TextField(
        controller: _controller,
        enabled: _loaded,
        minLines: 2,
        maxLines: 4,
        onChanged: _save,
        decoration: const InputDecoration(
          hintText: '필요한 내용을 메모해 보세요.',
          border: OutlineInputBorder(),
        ),
      ),
    ],
  );
}

class ActionIllustration extends StatelessWidget {
  const ActionIllustration({super.key, required this.card, this.large = false});
  final ActionCard card;
  final bool large;
  @override
  Widget build(BuildContext context) => ClipRRect(
    borderRadius: BorderRadius.circular(28),
    child: ColoredBox(
      color: const Color(0xfff4f0e8),
      child: _assetPath == null
          ? _fallback()
          : Image.asset(
              _assetPath!,
              fit: BoxFit.cover,
              errorBuilder: (_, _, _) => _fallback(),
            ),
    ),
  );

  Widget _fallback() => Center(
    child: Icon(
      _iconFor(card.category),
      size: large ? 150 : 72,
      color: const Color(0xff478bc2),
    ),
  );

  String? get _assetPath => switch (card.id) {
    'H-01' => 'assets/illustrations/h-01-wash-hands.png',
    'H-02' => 'assets/illustrations/h-02-brush-teeth.png',
    'H-03' => 'assets/illustrations/h-03-wash-face.png',
    'H-04' => 'assets/illustrations/h-04-wash-body.png',
    _ => null,
  };
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
