import 'package:flutter/material.dart';

import 'avatar_object_sprite.dart';
import 'avatar_character_system.dart';
import 'avatar_room.dart';
import 'growth_reward_repository.dart';
import 'room_object_sprite.dart';

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
    final data = await Future.wait<Object>([
      _repository.unlockedItems(widget.profileId),
      _repository.loadAvatar(widget.profileId),
    ]);
    if (!mounted) return;
    setState(() {
      _items = data[0] as List<UnlockableItem>;
      _equipped = data[1] as Map<String, String>;
    });
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
      appBar: AppBar(
        title: const Text('\uC544\uBC14\uD0C0 \uAFB8\uBBF8\uAE30'),
      ),
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
                Image.asset(
                  _equipped['top'] == 'avatar_top_01'
                      ? 'assets/avatars/avatar_blue_top.png'
                      : 'assets/avatars/starter_child.png',
                  height: 258,
                ),
                if (_equipped['hat'] != null)
                  Positioned(
                    top: 26,
                    child: AvatarRewardItemSprite(
                      itemId: _equipped['hat']!,
                      size: 68,
                    ),
                  ),
                if (_equipped['accessory'] != null)
                  Positioned(
                    right: 72,
                    bottom: 42,
                    child: AvatarRewardItemSprite(
                      itemId: _equipped['accessory']!,
                      size: 62,
                    ),
                  ),
                Positioned(
                  bottom: 12,
                  child: Text(
                    _equipped.isEmpty
                        ? '\uCC98\uC74C \uD63C\uC790 \uD55C \uD589\uB3D9\uC73C\uB85C \uC544\uC774\uD15C\uC744 \uBC1B\uC544\uC694.'
                        : '\uB098\uB9CC\uC758 \uBA4B\uC9C4 \uBAA8\uC2B5\uC744 \uAFB8\uBA70 \uBCF4\uC138\uC694.',
                    style: const TextStyle(fontWeight: FontWeight.w600),
                  ),
                ),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text(
            '\uAFB8\uBBF8\uAE30 \uD56D\uBAA9',
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
    'hair' => '\uBA38\uB9AC',
    'hat' => '\uBAA8\uC790',
    'top' => '\uC0C1\uC758',
    'bottom' => '\uD558\uC758',
    'shoes' => '\uC2E0\uBC1C',
    _ => '\uAC00\uBC29/\uC561\uC138\uC11C\uB9AC',
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
                    '\uD63C\uC790 \uD55C \uD589\uB3D9\uC744 \uB9CE\uC774 \uD574\uBCF4\uBA70 \uC544\uC774\uD15C\uC744 \uBAA8\uC544\uC694.',
                    style: TextStyle(color: Colors.grey, fontSize: 12),
                  )
                : Wrap(
                    spacing: 8,
                    runSpacing: 6,
                    children: items
                        .map(
                          (item) => ChoiceChip(
                            avatar: RewardItemVisual(
                              itemId: item.id,
                              fallbackIcon: item.icon,
                              isSpaceItem: false,
                              size: 26,
                            ),
                            label: Text(item.name),
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
  const SpacePage({super.key, required this.profileId, this.initialSpaceId});
  final String profileId;
  final String? initialSpaceId;
  @override
  State<SpacePage> createState() => _SpacePageState();
}

class _SpacePageState extends State<SpacePage> {
  final _repository = GrowthRewardRepository();
  final _stageKey = GlobalKey();
  List<UnlockableItem> _items = [];
  List<SpacePlacement> _placements = [];
  SpacePlacement? _selectedPlacement;
  late String _spaceId;

  @override
  void initState() {
    super.initState();
    _spaceId = widget.initialSpaceId ?? 'bathroom';
    _load();
  }

  Future<void> _load() async {
    final data = await Future.wait<Object>([
      _repository.unlockedItems(widget.profileId),
      _repository.loadPlacements(
        profileId: widget.profileId,
        spaceId: _spaceId,
      ),
    ]);
    if (!mounted) return;
    setState(() {
      _items = data[0] as List<UnlockableItem>;
      _placements = data[1] as List<SpacePlacement>;
    });
  }

  Future<void> _changeSpace(String value) async {
    setState(() {
      _spaceId = value;
      _selectedPlacement = null;
    });
    await _load();
  }

  ({double x, double y}) _relative(Offset offset) {
    final render = _stageKey.currentContext!.findRenderObject()! as RenderBox;
    final local = render.globalToLocal(offset);
    final viewport = AvatarViewportSystem.contain(render.size);
    final origin = Offset(
      (render.size.width - viewport.width) / 2,
      (render.size.height - viewport.height) / 2,
    );
    final viewportPoint = local - origin;
    return (
      x: (viewportPoint.dx / viewport.width).clamp(0, 1),
      y: (viewportPoint.dy / viewport.height).clamp(0, 1),
    );
  }

  Future<void> _accept(Object data, Offset offset) async {
    final point = _relative(offset);
    final itemId = data is UnlockableItem
        ? data.id
        : data is SpacePlacement
        ? data.itemId
        : '';
    final slot = _slotFor(itemId, point);
    if (slot == null) {
      if (!mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        const SnackBar(content: Text('이 물건을 놓을 수 있는 자리 가까이에 놓아 주세요.')),
      );
      return;
    }
    if (data is UnlockableItem) {
      await _repository.placeItem(
        profileId: widget.profileId,
        spaceId: _spaceId,
        itemId: data.id,
        x: slot.position.x / 100,
        y: slot.position.y / 100,
      );
    } else if (data is SpacePlacement) {
      await _repository.placeItem(
        profileId: widget.profileId,
        spaceId: _spaceId,
        itemId: data.itemId,
        x: slot.position.x / 100,
        y: slot.position.y / 100,
      );
    }
    if (!mounted) return;
    setState(() => _selectedPlacement = null);
    await _load();
  }

  // Decoration slots are shared with AvatarWorldPage through AvatarRoom. The
  // repository keeps the previous 0–1 persisted values for compatibility,
  // while room definitions themselves use the common 0–100 logical system.
  DecorationSlot? _slotFor(String itemId, ({double x, double y}) point) {
    final room = roomById(_spaceId);
    final slot = room.nearestAcceptingSlot(
      itemId,
      RoomPoint(point.x * 100, point.y * 100),
    );
    if (slot == null) return null;
    final dropPoint = RoomPoint(point.x * 100, point.y * 100);
    return slot.position.distanceTo(dropPoint) <= 20 ? slot : null;
  }

  Future<void> _removeSelected() async {
    final selected = _selectedPlacement;
    if (selected == null) return;
    await _repository.removePlacement(selected.id);
    if (!mounted) return;
    setState(() => _selectedPlacement = null);
    await _load();
  }

  @override
  Widget build(BuildContext context) {
    final space = roomById(_spaceId);
    final inventory = _items
        .where(
          (item) =>
              item.type == UnlockableItemType.spaceItem &&
              item.spaceId == _spaceId,
        )
        .toList();
    return Scaffold(
      appBar: AppBar(title: const Text('\uACF5\uAC04 \uAFB8\uBBF8\uAE30')),
      body: SafeArea(
        child: Column(
          children: [
            SizedBox(
              height: 50,
              child: ListView(
                scrollDirection: Axis.horizontal,
                padding: const EdgeInsets.symmetric(horizontal: 12),
                children: avatarRooms
                    .map(
                      (item) => Padding(
                        padding: const EdgeInsets.only(right: 7),
                        child: ChoiceChip(
                          label: Text(item.label),
                          selected: item.id == _spaceId,
                          onSelected: (_) => _changeSpace(item.id),
                        ),
                      ),
                    )
                    .toList(),
              ),
            ),
            Expanded(
              child: Padding(
                padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
                child: LayoutBuilder(
                  builder: (context, constraints) => DragTarget<Object>(
                    onWillAcceptWithDetails: (details) {
                      final data = details.data;
                      final itemId = data is UnlockableItem
                          ? data.id
                          : data is SpacePlacement
                          ? data.itemId
                          : '';
                      final item = _itemFor(itemId);
                      return item != null && item.spaceId == _spaceId;
                    },
                    onAcceptWithDetails: (details) =>
                        _accept(details.data, details.offset),
                    builder: (context, candidates, _) => Container(
                      key: _stageKey,
                      clipBehavior: Clip.hardEdge,
                      decoration: BoxDecoration(
                        borderRadius: BorderRadius.circular(26),
                        border: Border.all(
                          color: candidates.isEmpty
                              ? const Color(0xffd9e5d4)
                              : const Color(0xff2f8b4b),
                          width: 3,
                        ),
                      ),
                      child: Center(
                        child: SizedBox(
                          width: AvatarViewportSystem.contain(
                            Size(constraints.maxWidth, constraints.maxHeight),
                          ).width,
                          height: AvatarViewportSystem.contain(
                            Size(constraints.maxWidth, constraints.maxHeight),
                          ).height,
                          child: LayoutBuilder(
                            builder: (context, viewportConstraints) => Stack(
                              fit: StackFit.expand,
                              children: [
                                Image.asset(
                                  space.backgroundAsset,
                                  fit: BoxFit.fill,
                                ),
                                for (final object in space.fixedObjects.where(
                                  (object) => object.shouldRenderAtlas,
                                ))
                                  PositionedRoomObject(
                                    object: object,
                                    viewportSize: Size(
                                      viewportConstraints.maxWidth,
                                      viewportConstraints.maxHeight,
                                    ),
                                  ),
                                if (candidates.isNotEmpty)
                                  for (final slot in space.slots.where(
                                    (slot) =>
                                        candidates.isEmpty ||
                                        slot.accepts(
                                          candidates.first is UnlockableItem
                                              ? (candidates.first
                                                        as UnlockableItem)
                                                    .id
                                              : candidates.first
                                                    is SpacePlacement
                                              ? (candidates.first
                                                        as SpacePlacement)
                                                    .itemId
                                              : '',
                                        ),
                                  ))
                                    Positioned(
                                      left:
                                          slot.position.x /
                                              100 *
                                              viewportConstraints.maxWidth -
                                          26,
                                      top:
                                          slot.position.y /
                                              100 *
                                              viewportConstraints.maxHeight -
                                          26,
                                      child: IgnorePointer(
                                        child: Container(
                                          width: 52,
                                          height: 52,
                                          decoration: BoxDecoration(
                                            color: const Color(0x553aa75b),
                                            shape: BoxShape.circle,
                                            border: Border.all(
                                              color: Colors.white,
                                              width: 2,
                                            ),
                                          ),
                                          child: const Icon(
                                            Icons.add,
                                            color: Colors.white,
                                          ),
                                        ),
                                      ),
                                    ),
                                for (final placement in _placements)
                                  Positioned(
                                    left:
                                        (placement.x *
                                                    viewportConstraints
                                                        .maxWidth -
                                                29)
                                            .clamp(
                                              4,
                                              viewportConstraints.maxWidth - 62,
                                            )
                                            .toDouble(),
                                    top:
                                        (placement.y *
                                                    viewportConstraints
                                                        .maxHeight -
                                                58)
                                            .clamp(
                                              8,
                                              viewportConstraints.maxHeight -
                                                  66,
                                            )
                                            .toDouble(),
                                    child: LongPressDraggable<Object>(
                                      data: placement,
                                      feedback: _ItemToken(
                                        item: _itemFor(placement.itemId),
                                        highlighted: true,
                                      ),
                                      childWhenDragging: const SizedBox(
                                        width: 52,
                                        height: 52,
                                      ),
                                      child: GestureDetector(
                                        onTap: () => setState(
                                          () => _selectedPlacement = placement,
                                        ),
                                        child: DecoratedBox(
                                          decoration: BoxDecoration(
                                            border:
                                                _selectedPlacement?.id ==
                                                    placement.id
                                                ? Border.all(
                                                    color: const Color(
                                                      0xff2f8b4b,
                                                    ),
                                                    width: 2,
                                                  )
                                                : null,
                                            borderRadius: BorderRadius.circular(
                                              12,
                                            ),
                                          ),
                                          child: AvatarObjectSprite(
                                            itemId: placement.itemId,
                                            size: 58,
                                          ),
                                        ),
                                      ),
                                    ),
                                  ),
                                if (_selectedPlacement != null)
                                  Positioned(
                                    top: 10,
                                    right: 10,
                                    child: FilledButton.icon(
                                      onPressed: _removeSelected,
                                      icon: const Icon(Icons.delete_outline),
                                      label: const Text('\uD68C\uC218'),
                                    ),
                                  ),
                                Positioned(
                                  left: 12,
                                  bottom: 10,
                                  child: DecoratedBox(
                                    decoration: BoxDecoration(
                                      color: Colors.black54,
                                      borderRadius: BorderRadius.circular(12),
                                    ),
                                    child: Padding(
                                      padding: const EdgeInsets.symmetric(
                                        horizontal: 10,
                                        vertical: 6,
                                      ),
                                      child: Text(
                                        '${space.label}  ${_placements.length}\uAC1C',
                                        style: const TextStyle(
                                          color: Colors.white,
                                          fontWeight: FontWeight.bold,
                                        ),
                                      ),
                                    ),
                                  ),
                                ),
                              ],
                            ),
                          ),
                        ),
                      ),
                    ),
                  ),
                ),
              ),
            ),
            Container(
              height: 112,
              padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
              decoration: const BoxDecoration(
                color: Color(0xfffffbf5),
                border: Border(top: BorderSide(color: Color(0xffe8e4dc))),
              ),
              child: Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                children: [
                  Text(
                    '${space.label} 보관함 · 길게 눌러 배치하거나 이동해요.',
                    style: const TextStyle(fontWeight: FontWeight.w700),
                  ),
                  const SizedBox(height: 6),
                  Expanded(
                    child: inventory.isEmpty
                        ? const Center(
                            child: Text(
                              '\uC774 \uACF5\uAC04\uC5D0 \uB193\uC744 \uD68D\uB4DD \uC544\uC774\uD15C\uC774 \uC5C6\uC5B4\uC694.',
                            ),
                          )
                        : ListView(
                            scrollDirection: Axis.horizontal,
                            children: inventory
                                .map(
                                  (item) => Padding(
                                    padding: const EdgeInsets.only(right: 8),
                                    child: LongPressDraggable<Object>(
                                      data: item,
                                      feedback: _ItemToken(
                                        item: item,
                                        highlighted: true,
                                      ),
                                      childWhenDragging: Opacity(
                                        opacity: .35,
                                        child: _ItemToken(item: item),
                                      ),
                                      child: _ItemToken(item: item),
                                    ),
                                  ),
                                )
                                .toList(),
                          ),
                  ),
                ],
              ),
            ),
          ],
        ),
      ),
    );
  }

  UnlockableItem? _itemFor(String id) {
    final matches = GrowthRewardRepository.items
        .where((item) => item.id == id)
        .toList();
    return matches.isEmpty ? null : matches.first;
  }
}

class _ItemToken extends StatelessWidget {
  const _ItemToken({required this.item, this.highlighted = false});
  final UnlockableItem? item;
  final bool highlighted;
  @override
  Widget build(BuildContext context) => Container(
    width: 58,
    height: 58,
    decoration: BoxDecoration(
      color: highlighted
          ? const Color(0xffffedb8)
          : Colors.white.withValues(alpha: .92),
      borderRadius: BorderRadius.circular(14),
      border: Border.all(
        color: highlighted ? const Color(0xffe6a921) : const Color(0xffd7ded2),
        width: highlighted ? 2 : 1,
      ),
      boxShadow: const [
        BoxShadow(
          color: Color(0x33000000),
          blurRadius: 5,
          offset: Offset(0, 2),
        ),
      ],
    ),
    child: Column(
      mainAxisAlignment: MainAxisAlignment.center,
      children: [
        AvatarObjectSprite(itemId: item?.id ?? '', size: 38),
        Text(
          item?.name ?? '',
          overflow: TextOverflow.ellipsis,
          style: const TextStyle(fontSize: 8),
        ),
      ],
    ),
  );
}

Future<void> showGrowthCelebration(
  BuildContext context, {
  required GrowthUnlockResult result,
  required String profileId,
}) => showDialog<void>(
  context: context,
  builder: (dialogContext) => AlertDialog(
    icon: RewardItemVisual(
      itemId: result.item.id,
      fallbackIcon: result.item.icon,
      isSpaceItem: result.item.type == UnlockableItemType.spaceItem,
    ),
    title: const Text('\uD63C\uC790 \uD574\uB0C8\uC5B4\uC694'),
    content: Text(
      '\uCC98\uC74C \uD63C\uC790 \uD55C \uD589\uB3D9\uC744 \uAE30\uB150\uD574\uC694.\n${result.item.name} \uC544\uC774\uD15C\uC744 \uC5BB\uC5C8\uC5B4\uC694.',
    ),
    actions: [
      TextButton(
        onPressed: () => Navigator.pop(dialogContext),
        child: const Text('\uB098\uC911\uC5D0 \uBCF4\uAE30'),
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
              ? '\uC544\uBC14\uD0C0 \uAFB8\uBBF8\uAE30'
              : '\uACF5\uAC04 \uAFB8\uBBF8\uAE30',
        ),
      ),
    ],
  ),
);
