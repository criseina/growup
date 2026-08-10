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
    const slots = ['hair', 'top', 'bottom', 'shoes', 'hat', 'accessory'];
    final avatarItems = _items
        .where((item) => item.type == UnlockableItemType.avatarItem)
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('내 아바타')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 280,
            decoration: BoxDecoration(
              color: const Color(0xffeff8e9),
              borderRadius: BorderRadius.circular(28),
            ),
            child: Column(
              mainAxisAlignment: MainAxisAlignment.center,
              children: [
                Stack(
                  alignment: Alignment.topCenter,
                  children: [
                    Image.asset(
                      'assets/avatars/starter_child.png',
                      height: 220,
                    ),
                    if (_equipped['hat'] != null)
                      const Positioned(
                        top: 0,
                        child: Text('🧢', style: TextStyle(fontSize: 42)),
                      ),
                  ],
                ),
                const Text('성장 모습을 보여주는 나의 친구'),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '꾸미기 아이템',
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
    'top' => '상의',
    'bottom' => '하의',
    'shoes' => '신발',
    'hat' => '모자',
    _ => '액세서리',
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
            width: 64,
            child: Text(
              title,
              style: const TextStyle(fontWeight: FontWeight.bold),
            ),
          ),
          Expanded(
            child: items.isEmpty
                ? const Text('아직 잠겨 있어요', style: TextStyle(color: Colors.grey))
                : Wrap(
                    spacing: 8,
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
    const spaces = {
      'bathroom': '욕실',
      'playroom': '놀이방',
      'kitchen': '주방',
      'entrance': '현관',
      'safety': '안전 공간',
    };
    final available = _items
        .where(
          (item) =>
              item.type == UnlockableItemType.spaceItem &&
              item.spaceId == _selectedSpace,
        )
        .toList();
    final placed = _placed[_selectedSpace] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(title: const Text('내 공간 꾸미기')),
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
                    const SizedBox(height: 18),
                    Wrap(
                      spacing: 16,
                      runSpacing: 16,
                      children: available
                          .where((item) => placed.contains(item.id))
                          .map((item) => _SpaceItem(item: item))
                          .toList(),
                    ),
                    if (available
                        .where((item) => placed.contains(item.id))
                        .isEmpty)
                      const Expanded(
                        child: Center(child: Text('잠금 해제한 아이템을 놓아 보세요.')),
                      ),
                  ],
                ),
              ),
            ),
            const SizedBox(height: 16),
            Align(
              alignment: Alignment.centerLeft,
              child: Text(
                '놓을 수 있는 아이템',
                style: Theme.of(context).textTheme.titleMedium,
              ),
            ),
            const SizedBox(height: 8),
            SizedBox(
              height: 84,
              child: available.isEmpty
                  ? const Center(child: Text('이 공간의 아이템은 아직 잠겨 있어요.'))
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
    title: const Text('혼자 해냈어요!'),
    content: Text('처음 혼자 해낸 성장 덕분에\n${result.item.name} 아이템이 생겼어요.'),
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
