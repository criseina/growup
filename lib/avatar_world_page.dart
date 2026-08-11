import 'dart:async';
import 'dart:math' as math;

import 'package:flutter/material.dart';

import 'growth_reward_pages.dart';
import 'growth_reward_repository.dart';
import 'main.dart' show ActionLibraryPage, GrowthRecordPage, HomePage;

class AvatarWorldPage extends StatefulWidget {
  const AvatarWorldPage({super.key, required this.profileId});
  final String profileId;

  @override
  State<AvatarWorldPage> createState() => _AvatarWorldPageState();
}

class _AvatarWorldPageState extends State<AvatarWorldPage>
    with SingleTickerProviderStateMixin {
  late final PageController _pageController = PageController();
  late final AnimationController _walkController = AnimationController(
    vsync: this,
    duration: const Duration(milliseconds: 2400),
  )..repeat(reverse: true);
  Timer? _activityTimer;
  var _page = 0;
  var _interacting = false;
  Map<String, List<String>> _placed = {};
  Map<String, String> _equipped = {};
  List<UnlockableItem> _unlocked = [];

  static const _worlds = <({String id, String name, String asset})>[
    (
      id: 'bathroom',
      name: '욕실',
      asset: 'assets/avatar_backgrounds/bathroom.png',
    ),
    (
      id: 'playroom',
      name: '놀이방',
      asset: 'assets/avatar_backgrounds/playroom.png',
    ),
    (id: 'kitchen', name: '주방', asset: 'assets/avatar_backgrounds/kitchen.png'),
    (
      id: 'entrance',
      name: '현관',
      asset: 'assets/avatar_backgrounds/entrance.png',
    ),
    (id: 'bedroom', name: '침실', asset: 'assets/avatar_backgrounds/bedroom.png'),
    (
      id: 'safety',
      name: '안전 활동',
      asset: 'assets/avatar_backgrounds/safety.png',
    ),
  ];

  String get _worldId => _worlds[_page].id;
  bool get _hasSoap => _unlocked.any((item) => item.id == 'bathroom_soap_01');
  bool get _isWashingHands =>
      _worldId == 'bathroom' && _hasSoap && _interacting;

  @override
  void initState() {
    super.initState();
    _load();
    _activityTimer = Timer.periodic(const Duration(seconds: 7), (_) {
      if (mounted) setState(() => _interacting = !_interacting);
    });
  }

  Future<void> _load() async {
    final repository = GrowthRewardRepository();
    final results = await Future.wait([
      repository.loadSpaces(widget.profileId),
      repository.loadAvatar(widget.profileId),
      repository.unlockedItems(widget.profileId),
    ]);
    if (!mounted) return;
    setState(() {
      _placed = results[0] as Map<String, List<String>>;
      _equipped = results[1] as Map<String, String>;
      _unlocked = results[2] as List<UnlockableItem>;
    });
  }

  @override
  void dispose() {
    _activityTimer?.cancel();
    _pageController.dispose();
    _walkController.dispose();
    super.dispose();
  }

  Future<void> _place(UnlockableItem item) async {
    if (item.spaceId != _worldId) return;
    await GrowthRewardRepository().toggleSpaceItem(widget.profileId, item);
    await _load();
  }

  void _openCloset() => Navigator.of(context)
      .push(
        MaterialPageRoute(
          builder: (_) => AvatarPage(profileId: widget.profileId),
        ),
      )
      .then((_) => _load());

  void _go(Widget page) => Navigator.of(context).pushAndRemoveUntil(
    MaterialPageRoute(builder: (_) => page),
    (route) => false,
  );

  @override
  Widget build(BuildContext context) {
    final roomItems = _unlocked
        .where(
          (item) =>
              item.type == UnlockableItemType.spaceItem &&
              item.spaceId == _worldId,
        )
        .toList();
    final placedIds = _placed[_worldId] ?? const <String>[];
    return Scaffold(
      appBar: AppBar(
        title: Text('${_worlds[_page].name}에서 놀아요'),
        actions: [
          IconButton(
            tooltip: '아바타 꾸미기',
            onPressed: _openCloset,
            icon: const Icon(Icons.checkroom_outlined),
          ),
        ],
      ),
      body: Column(
        children: [
          Expanded(
            child: PageView.builder(
              controller: _pageController,
              itemCount: _worlds.length,
              onPageChanged: (index) => setState(() {
                _page = index;
                _interacting = false;
              }),
              itemBuilder: (context, index) {
                final world = _worlds[index];
                return DragTarget<UnlockableItem>(
                  onWillAcceptWithDetails: (details) =>
                      details.data.spaceId == world.id,
                  onAcceptWithDetails: (details) => _place(details.data),
                  builder: (context, candidate, rejected) => Stack(
                    fit: StackFit.expand,
                    children: [
                      Image.asset(world.asset, fit: BoxFit.cover),
                      if (candidate.isNotEmpty)
                        Container(
                          color: const Color(0xffeff8e9).withValues(alpha: .42),
                        ),
                      _PlacedItems(itemIds: _placed[world.id] ?? const []),
                      _GroundedAvatar(
                        walking: _walkController,
                        washingHands: _isWashingHands && world.id == 'bathroom',
                        blueTop: _equipped['top'] == 'avatar_top_01',
                        hasHat: _equipped['hat'] != null,
                        hasBag: _equipped['accessory'] != null,
                        onTap: () =>
                            setState(() => _interacting = !_interacting),
                      ),
                      Positioned(
                        top: 12,
                        left: 12,
                        child: _Speech(
                          text: _isWashingHands && world.id == 'bathroom'
                              ? '비누로 손을 씻고 있어요!'
                              : '나를 터치해 봐요 😊',
                        ),
                      ),
                      if (candidate.isNotEmpty)
                        const Center(child: _DropHint()),
                    ],
                  ),
                );
              },
            ),
          ),
          _RoomInventory(items: roomItems, placedIds: placedIds, onTap: _place),
        ],
      ),
      bottomNavigationBar: _AvatarBottomNavigation(
        onActions: () => _go(ActionLibraryPage(profileId: widget.profileId)),
        onHome: () => _go(const HomePage()),
        onRecords: () => _go(GrowthRecordPage(profileId: widget.profileId)),
      ),
    );
  }
}

class _GroundedAvatar extends StatelessWidget {
  const _GroundedAvatar({
    required this.walking,
    required this.washingHands,
    required this.blueTop,
    required this.hasHat,
    required this.hasBag,
    required this.onTap,
  });
  final Animation<double> walking;
  final bool washingHands;
  final bool blueTop;
  final bool hasHat;
  final bool hasBag;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) => AnimatedBuilder(
    animation: walking,
    builder: (context, _) {
      final wave = math.sin(walking.value * math.pi);
      final x = washingHands ? -100.0 : wave * 55;
      return Positioned(
        bottom: 6,
        left: 0,
        right: 0,
        child: Transform.translate(
          offset: Offset(x, washingHands ? 0 : -2 * wave),
          child: Transform(
            alignment: Alignment.center,
            transform: Matrix4.diagonal3Values(
              washingHands || wave >= 0 ? 1 : -1,
              1,
              1,
            ),
            child: GestureDetector(
              onTap: onTap,
              child: Stack(
                alignment: Alignment.topCenter,
                clipBehavior: Clip.none,
                children: [
                  Image.asset(
                    blueTop
                        ? 'assets/avatars/avatar_blue_top.png'
                        : 'assets/avatars/starter_child.png',
                    height: 270,
                  ),
                  if (hasHat)
                    const Positioned(
                      top: 0,
                      child: Text('🧢', style: TextStyle(fontSize: 38)),
                    ),
                  if (hasBag)
                    const Positioned(
                      right: 54,
                      bottom: 44,
                      child: Text('🎒', style: TextStyle(fontSize: 38)),
                    ),
                  if (washingHands)
                    const Positioned(
                      left: 44,
                      top: 96,
                      child: Text('🫧🫧', style: TextStyle(fontSize: 26)),
                    ),
                ],
              ),
            ),
          ),
        ),
      );
    },
  );
}

class _RoomInventory extends StatelessWidget {
  const _RoomInventory({
    required this.items,
    required this.placedIds,
    required this.onTap,
  });
  final List<UnlockableItem> items;
  final List<String> placedIds;
  final ValueChanged<UnlockableItem> onTap;

  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      height: 100,
      padding: const EdgeInsets.fromLTRB(16, 8, 16, 10),
      decoration: const BoxDecoration(
        color: Color(0xfffffbf5),
        border: Border(top: BorderSide(color: Color(0xffe8e4dc))),
      ),
      child: items.isEmpty
          ? const Center(child: Text('이 공간의 행동을 혼자 해내면 아이템이 생겨요.'))
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                const Text(
                  '길게 눌러 방 안으로 끌어 놓으세요',
                  style: TextStyle(fontSize: 12, fontWeight: FontWeight.w600),
                ),
                const SizedBox(height: 5),
                Expanded(
                  child: ListView.separated(
                    scrollDirection: Axis.horizontal,
                    itemCount: items.length,
                    separatorBuilder: (_, _) => const SizedBox(width: 10),
                    itemBuilder: (context, index) {
                      final item = items[index];
                      final placed = placedIds.contains(item.id);
                      return LongPressDraggable<UnlockableItem>(
                        data: item,
                        feedback: _InventoryTile(item: item, highlighted: true),
                        childWhenDragging: Opacity(
                          opacity: .35,
                          child: _InventoryTile(
                            item: item,
                            highlighted: placed,
                          ),
                        ),
                        child: GestureDetector(
                          onTap: () => onTap(item),
                          child: _InventoryTile(
                            item: item,
                            highlighted: placed,
                          ),
                        ),
                      );
                    },
                  ),
                ),
              ],
            ),
    ),
  );
}

class _InventoryTile extends StatelessWidget {
  const _InventoryTile({required this.item, required this.highlighted});
  final UnlockableItem item;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    decoration: BoxDecoration(
      color: highlighted ? const Color(0xffe0f2dc) : Colors.white,
      borderRadius: BorderRadius.circular(12),
      border: Border.all(color: const Color(0xffb7d9ad)),
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        Text(item.icon, style: const TextStyle(fontSize: 27)),
        Text(
          item.name,
          maxLines: 1,
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 9),
        ),
      ],
    ),
  );
}

class _PlacedItems extends StatelessWidget {
  const _PlacedItems({required this.itemIds});
  final List<String> itemIds;
  @override
  Widget build(BuildContext context) {
    final items = GrowthRewardRepository.items
        .where((item) => itemIds.contains(item.id))
        .toList();
    return Positioned(
      top: 30,
      right: 12,
      child: Wrap(
        spacing: 6,
        children: items
            .map(
              (item) => DecoratedBox(
                decoration: BoxDecoration(
                  color: Colors.white.withValues(alpha: .82),
                  borderRadius: BorderRadius.circular(14),
                ),
                child: Padding(
                  padding: const EdgeInsets.all(6),
                  child: Text(item.icon, style: const TextStyle(fontSize: 26)),
                ),
              ),
            )
            .toList(),
      ),
    );
  }
}

class _Speech extends StatelessWidget {
  const _Speech({required this.text});
  final String text;
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .9),
      borderRadius: BorderRadius.circular(16),
    ),
    child: Padding(
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 7),
      child: Text(text, style: const TextStyle(fontSize: 12)),
    ),
  );
}

class _DropHint extends StatelessWidget {
  const _DropHint();
  @override
  Widget build(BuildContext context) => DecoratedBox(
    decoration: BoxDecoration(
      color: Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(20),
    ),
    child: const Padding(
      padding: EdgeInsets.all(14),
      child: Text('여기에 놓으면 공간에 배치돼요'),
    ),
  );
}

class _AvatarBottomNavigation extends StatelessWidget {
  const _AvatarBottomNavigation({
    required this.onActions,
    required this.onHome,
    required this.onRecords,
  });
  final VoidCallback onActions;
  final VoidCallback onHome;
  final VoidCallback onRecords;
  @override
  Widget build(BuildContext context) => SafeArea(
    top: false,
    child: Container(
      padding: const EdgeInsets.symmetric(vertical: 8),
      decoration: const BoxDecoration(
        color: Color(0xfffffbf5),
        border: Border(top: BorderSide(color: Color(0xffe8e4dc))),
      ),
      child: Row(
        mainAxisAlignment: MainAxisAlignment.spaceAround,
        children: [
          _Nav(
            icon: Icons.auto_awesome_outlined,
            label: '행동',
            onTap: onActions,
          ),
          _Nav(icon: Icons.home_rounded, label: '홈', onTap: onHome),
          const _Nav(
            icon: Icons.face_retouching_natural,
            label: '아바타',
            selected: true,
          ),
          _Nav(icon: Icons.menu_book_outlined, label: '기록', onTap: onRecords),
        ],
      ),
    ),
  );
}

class _Nav extends StatelessWidget {
  const _Nav({
    required this.icon,
    required this.label,
    this.selected = false,
    this.onTap,
  });
  final IconData icon;
  final String label;
  final bool selected;
  final VoidCallback? onTap;
  @override
  Widget build(BuildContext context) => InkWell(
    onTap: onTap,
    borderRadius: BorderRadius.circular(16),
    child: AnimatedContainer(
      duration: const Duration(milliseconds: 180),
      padding: const EdgeInsets.symmetric(horizontal: 12, vertical: 5),
      decoration: BoxDecoration(
        color: selected ? const Color(0xffe0f2dc) : Colors.transparent,
        borderRadius: BorderRadius.circular(16),
      ),
      child: Column(
        mainAxisSize: MainAxisSize.min,
        children: [
          Icon(
            icon,
            size: selected ? 30 : 23,
            color: selected ? const Color(0xff176a36) : const Color(0xff7b867d),
          ),
          const SizedBox(height: 2),
          Text(
            label,
            style: TextStyle(
              fontSize: 11,
              color: selected
                  ? const Color(0xff176a36)
                  : const Color(0xff7b867d),
              fontWeight: selected ? FontWeight.w800 : FontWeight.w500,
            ),
          ),
        ],
      ),
    ),
  );
}
