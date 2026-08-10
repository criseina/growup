import 'package:flutter/material.dart';

import 'growth_reward_repository.dart';

class AvatarPage extends StatefulWidget {
  const AvatarPage({super.key, required this.profileId});
  final String profileId;

  @override
  State<AvatarPage> createState() => _AvatarPageState();
}

class _AvatarPageState extends State<AvatarPage> {
  final _repository = GrowthRewardRepository();
  List<UnlockableItem> _items = [];
  Map<String, String> _equipped = {};

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.unlockedItems(widget.profileId);
    final equipped = await _repository.loadAvatar(widget.profileId);
    if (mounted) {
      setState(() {
        _items = items;
        _equipped = equipped;
      });
    }
  }

  Future<void> _equip(UnlockableItem item) async {
    await _repository.equipAvatarItem(widget.profileId, item);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    const slots = ['hair', 'hat', 'top', 'bottom', 'shoes', 'accessory'];
    final avatarItems = _items
        .where((item) => item.type == UnlockableItemType.avatarItem)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('아바타 꾸미기')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 306,
            decoration: BoxDecoration(
              color: const Color(0xffeff8e9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset('assets/avatars/starter_child.png', height: 258),
                if (_equipped['hat'] != null)
                  const Positioned(
                    top: 26,
                    child: Text('🧢', style: TextStyle(fontSize: 42)),
                  ),
                if (_equipped['accessory'] != null)
                  const Positioned(
                    right: 72,
                    bottom: 42,
                    child: Text('🎒', style: TextStyle(fontSize: 42)),
                  ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    _equipped.isEmpty
                        ? '첫 독립 행동으로 꾸미기 아이템을 받아요'
                        : '나만의 성장 모습을 꾸며 보세요',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '꾸미기 항목',
            style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold),
          ),
          const SizedBox(height: 8),
          for (final slot in slots)
            _SlotRow(
              title: _slotTitle(slot),
              items: avatarItems
                  .where((item) => item.category == slot)
                  .toList(),
              equippedId: _equipped[slot],
              onTap: _equip,
            ),
        ],
      ),
    );
  }

  String _slotTitle(String slot) => switch (slot) {
    'hair' => '머리',
    'hat' => '모자',
    'top' => '상의',
    'bottom' => '하의',
    'shoes' => '신발',
    _ => '가방·액세서리',
  };
}

class _SlotRow extends StatelessWidget {
  const _SlotRow({
    required this.title,
    required this.items,
    required this.equippedId,
    required this.onTap,
  });
  final String title;
  final List<UnlockableItem> items;
  final String? equippedId;
  final ValueChanged<UnlockableItem> onTap;

  @override
  Widget build(BuildContext context) => Card(
    child: Padding(
      padding: const EdgeInsets.all(12),
      child: Row(
        children: [
          SizedBox(
            width: 88,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Text(
                    '새 행동을 혼자 해보면 아이템이 열려요',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: items
                        .map(
                          (item) => ChoiceChip(
                            label: Text('${item.icon} ${item.name}'),
                            selected: item.id == equippedId,
                            onSelected: (_) => onTap(item),
                          ),
                        )
                        .toList(),
                  ),
          ),
        ],
      ),
    ),
  );
}

class SpacePage extends StatefulWidget {
  const SpacePage({super.key, required this.profileId});
  final String profileId;

  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage> {
  final _repository = GrowthRewardRepository();
  List<UnlockableItem> _items = [];
  Map<String, List<String>> _placed = {};
  String _selectedSpace = 'bathroom';
  static const spaces = <String, String>{
    'bathroom': '욕실',
    'playroom': '놀이방',
    'kitchen': '주방',
    'entrance': '현관',
    'bedroom': '침실',
    'safety': '안전 활동',
  };

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final items = await _repository.unlockedItems(widget.profileId);
    final placed = await _repository.loadSpaces(widget.profileId);
    if (mounted) {
      setState(() {
        _items = items;
        _placed = placed;
      });
    }
  }

  Future<void> _toggle(UnlockableItem item) async {
    await _repository.toggleSpaceItem(widget.profileId, item);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final available = _items
        .where(
          (item) =>
              item.type == UnlockableItemType.spaceItem &&
              item.spaceId == _selectedSpace,
        )
        .toList();
    final placed = _placed[_selectedSpace] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('공간 꾸미기')),
      body: Padding(
        padding: const EdgeInsets.all(20),
        child: Column(
          children: [
            SingleChildScrollView(
              scrollDirection: Axis.horizontal,
              child: Row(
                children: spaces.entries
                    .map(
                      (entry) => Padding(
                        padding: const EdgeInsets.only(right: 8),
                        child: ChoiceChip(
                          label: Text(entry.value),
                          selected: _selectedSpace == entry.key,
                          onSelected: (_) =>
                              setState(() => _selectedSpace = entry.key),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            const SizedBox(height: 18),
            Expanded(
              child: Container(
                width: double.infinity,
                padding: const EdgeInsets.all(20),
                decoration: BoxDecoration(
                  color: const Color(0xffeff8e9),
                  borderRadius: BorderRadius.circular(28),
                ),
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      spaces[_selectedSpace]!,
                      style: const TextStyle(
                        fontSize: 22,
                        fontWeight: FontWeight.bold,
                      ),
                    ),
                    const SizedBox(height: 10),
                    Text(
                      '${placed.length}개 아이템을 배치했어요',
                      style: const TextStyle(color: Color(0xff28753c)),
                    ),
                    const SizedBox(height: 24),
                    if (placed.isEmpty)
                      const Expanded(
                        child: Center(
                          child: Text('독립 행동을 해보면 이 공간의 아이템이 열려요.'),
                        ),
                      )
                    else
                      Wrap(
                        spacing: 18,
                        runSpacing: 18,
                        children: available
                            .where((item) => placed.contains(item.id))
                            .map((item) => _SpaceItem(item: item))
                            .toList(),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '배치할 수 있는 아이템',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 86,
              child: available.isEmpty
                  ? const Center(child: Text('아직 열려 있는 아이템이 없어요'))
                  : ListView(
                      scrollDirection: Axis.horizontal,
                      children: available
                          .map(
                            (item) => Padding(
                              padding: const EdgeInsets.only(right: 8),
                              child: FilterChip(
                                label: Text('${item.icon} ${item.name}'),
                                selected: placed.contains(item.id),
                                onSelected: (_) => _toggle(item),
                              ),
                            ),
                          )
                          .toList(),
                    ),
            ),
          ],
        ),
      ),
    );
  }
}

class _SpaceItem extends StatelessWidget {
  const _SpaceItem({required this.item});
  final UnlockableItem item;
  @override
  Widget build(BuildContext context) => Column(
    mainAxisSize: MainAxisSize.min,
    children: [
      Text(item.icon, style: const TextStyle(fontSize: 42)),
      Text(item.name, style: const TextStyle(fontSize: 12)),
    ],
  );
}

Future<void> showGrowthCelebration(
  BuildContext context, {
  required GrowthUnlockResult result,
  required String profileId,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    icon: Text(result.item.icon, style: const TextStyle(fontSize: 50)),
    title: const Text('첫 혼자 성공이에요!'),
    content: Text('처음 혼자 해낸 성장의 순간이에요.\n${result.item.name} 아이템이 열렸어요.'),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('나중에 보기'),
      ),
      FilledButton(
        onPressed: () {
          Navigator.pop(dialogContext);
          Navigator.of(context).push(
            MaterialPageRoute(
              builder: (_) => result.item.type == UnlockableItemType.avatarItem
                  ? AvatarPage(profileId: profileId)
                  : SpacePage(profileId: profileId),
            ),
          );
        },
        child: Text(
          result.item.type == UnlockableItemType.avatarItem
              ? '아바타 꾸미기'
              : '공간 꾸미기',
        ),
      ),
    ],
  ),
);
