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
    final avatarItems = _items.where((item) => item.type == UnlockableItemType.avatarItem).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('\uC544\uBC14\uD0C0 \uAFB8\uBBF8\uAE30')),
      body: ListView(
        padding: const EdgeInsets.all(20),
        children: [
          Container(
            height: 306,
            decoration: BoxDecoration(color: const Color(0xffeff8e9), borderRadius: BorderRadius.circular(28)),
            child: Stack(
              alignment: Alignment.center,
              children: [
                Image.asset(_equipped['top'] == 'avatar_top_01' ? 'assets/avatars/avatar_blue_top.png' : 'assets/avatars/starter_child.png', height: 258),
                if (_equipped['hat'] != null) const Positioned(top: 26, child: Text('\uD83E\uDDE2', style: TextStyle(fontSize: 42))),
                if (_equipped['accessory'] != null) const Positioned(right: 72, bottom: 42, child: Text('\uD83C\uDF92', style: TextStyle(fontSize: 42))),
                Positioned(bottom: 12, child: Text(_equipped.isEmpty ? '\uCC98\uC74C \uD63C\uC790 \uD55C \uD589\uB3D9\uC73C\uB85C \uC544\uC774\uD15C\uC744 \uBC1B\uC544\uC694.' : '\uB098\uB9CC\uC758 \uBA4B\uC9C4 \uBAA8\uC2B5\uC744 \uAFB8\uBA70 \uBCF4\uC138\uC694.', style: const TextStyle(fontWeight: FontWeight.w600))),
              ],
            ),
          ),
          const SizedBox(height: 22),
          const Text('\uAFB8\uBBF8\uAE30 \uD56D\uBAA9', style: TextStyle(fontSize: 18, fontWeight: FontWeight.bold)),
          const SizedBox(height: 8),
          for (final slot in slots)
            _SlotRow(
              title: _slotTitle(slot),
              items: avatarItems.where((item) => item.category == slot).toList(),
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
  const _SlotRow({required this.title, required this.items, required this.equippedId, required this.onTap});
  final String title;
  final List<UnlockableItem> items;
  final String? equippedId;
  final ValueChanged<UnlockableItem> onTap;
  @override
  Widget build(BuildContext context) => Card(
        child: Padding(
          padding: const EdgeInsets.all(12),
          child: Row(children: [
            SizedBox(width: 88, child: Text(title, style: const TextStyle(fontWeight: FontWeight.bold))),
            Expanded(
              child: items.isEmpty
                  ? const Text('\uD63C\uC790 \uD55C \uD589\uB3D9\uC744 \uB9CE\uC774 \uD574\uBCF4\uBA70 \uC544\uC774\uD15C\uC744 \uBAA8\uC544\uC694.', style: TextStyle(color: Colors.grey, fontSize: 12))
                  : Wrap(spacing: 8, runSpacing: 6, children: items.map((item) => ChoiceChip(label: Text('${item.icon} ${item.name}'), selected: item.id == equippedId, onSelected: (_) => onTap(item))).toList()),
            ),
          ]),
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
  final _stageKey = GlobalKey();
  List<UnlockableItem> _items = [];
  List<SpacePlacement> _placements = [];
  SpacePlacement? _selectedPlacement;
  String _spaceId = 'bathroom';

  static const _spaces = <({String id, String label, String asset})>[
    (id: 'bathroom', label: '\uC695\uC2E4', asset: 'assets/avatar_backgrounds/bathroom.png'),
    (id: 'playroom', label: '\uB180\uC774\uBC29', asset: 'assets/avatar_backgrounds/playroom.png'),
    (id: 'kitchen', label: '\uC8FC\uBC29', asset: 'assets/avatar_backgrounds/kitchen.png'),
    (id: 'entrance', label: '\uD604\uAD00', asset: 'assets/avatar_backgrounds/entrance.png'),
    (id: 'bedroom', label: '\uCE68\uC2E4', asset: 'assets/avatar_backgrounds/bedroom.png'),
    (id: 'safety', label: '\uC548\uC804', asset: 'assets/avatar_backgrounds/safety.png'),
  ];

  @override
  void initState() {
    super.initState();
    _load();
  }

  Future<void> _load() async {
    final data = await Future.wait<Object>([
      _repository.unlockedItems(widget.profileId),
      _repository.loadPlacements(profileId: widget.profileId, spaceId: _spaceId),
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
    return (x: local.dx / render.size.width, y: local.dy / render.size.height);
  }

  Future<void> _accept(Object data, Offset offset) async {
    final point = _relative(offset);
    final itemId = data is UnlockableItem
        ? data.id
        : data is SpacePlacement
            ? data.itemId
            : '';
    final slot = _slotFor(itemId, point);
    if (data is UnlockableItem) {
      await _repository.placeItem(profileId: widget.profileId, spaceId: _spaceId, itemId: data.id, x: slot.x, y: slot.y);
    } else if (data is SpacePlacement) {
      await _repository.placeItem(profileId: widget.profileId, spaceId: _spaceId, itemId: data.itemId, x: slot.x, y: slot.y);
    }
    if (!mounted) return;
    setState(() => _selectedPlacement = null);
    await _load();
  }

  // Dollhouse furniture slots: drops snap to an intentional surface instead
  // of allowing objects to float at arbitrary screen coordinates.
  ({double x, double y}) _slotFor(String itemId, ({double x, double y}) point) => switch (itemId) {
        'bathroom_soap_01' => (x: .67, y: .44),
        'bathroom_toothbrush_01' => (x: .76, y: .44),
        'bathroom_towel_01' => (x: .84, y: .31),
        'playroom_toybox_01' => (x: .31, y: .67),
        'playroom_shelf_01' => (x: .74, y: .40),
        'kitchen_cup_01' => (x: .61, y: .53),
        'kitchen_table_01' => (x: .52, y: .58),
        'entrance_bag_01' => (x: .27, y: .56),
        'entrance_shoe_rack_01' => (x: .72, y: .61),
        'bedroom_lamp_01' => (x: .72, y: .43),
        'bedroom_star_01' => (x: .58, y: .23),
        'safety_car_01' => (x: .74, y: .62),
        'safety_cone_01' => (x: .51, y: .67),
        _ => (x: point.x.clamp(.12, .78), y: point.y.clamp(.26, .72)),
      };

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
    final space = _spaces.firstWhere((item) => item.id == _spaceId);
    final inventory = _items.where((item) => item.type == UnlockableItemType.spaceItem && item.spaceId == _spaceId).toList();
    return Scaffold(
      appBar: AppBar(title: const Text('\uACF5\uAC04 \uAFB8\uBBF8\uAE30')),
      body: SafeArea(
        child: Column(children: [
          SizedBox(
            height: 50,
            child: ListView(scrollDirection: Axis.horizontal, padding: const EdgeInsets.symmetric(horizontal: 12), children: _spaces.map((item) => Padding(padding: const EdgeInsets.only(right: 7), child: ChoiceChip(label: Text(item.label), selected: item.id == _spaceId, onSelected: (_) => _changeSpace(item.id)))).toList()),
          ),
          Expanded(
            child: Padding(
              padding: const EdgeInsets.fromLTRB(16, 8, 16, 12),
              child: LayoutBuilder(
                builder: (context, constraints) => DragTarget<Object>(
                  onWillAcceptWithDetails: (details) => details.data is UnlockableItem || details.data is SpacePlacement,
                  onAcceptWithDetails: (details) => _accept(details.data, details.offset),
                  builder: (context, candidates, _) => Container(
                    key: _stageKey,
                    clipBehavior: Clip.hardEdge,
                    decoration: BoxDecoration(borderRadius: BorderRadius.circular(26), border: Border.all(color: candidates.isEmpty ? const Color(0xffd9e5d4) : const Color(0xff2f8b4b), width: 3)),
                    child: Stack(fit: StackFit.expand, children: [
                      Image.asset(space.asset, fit: BoxFit.cover),
                      for (final placement in _placements)
                        Positioned(
                          left: (placement.x * (constraints.maxWidth - 56)).clamp(4, constraints.maxWidth - 60).toDouble(),
                          top: (placement.y * (constraints.maxHeight - 56)).clamp(8, constraints.maxHeight - 64).toDouble(),
                          child: LongPressDraggable<Object>(
                            data: placement,
                            feedback: _ItemToken(item: _itemFor(placement.itemId), highlighted: true),
                            childWhenDragging: const SizedBox(width: 52, height: 52),
                            child: GestureDetector(onTap: () => setState(() => _selectedPlacement = placement), child: _ItemToken(item: _itemFor(placement.itemId), highlighted: _selectedPlacement?.id == placement.id)),
                          ),
                        ),
                      if (_selectedPlacement != null)
                        Positioned(
                          top: 10,
                          right: 10,
                          child: FilledButton.icon(onPressed: _removeSelected, icon: const Icon(Icons.delete_outline), label: const Text('\uD68C\uC218')),
                        ),
                      Positioned(left: 12, bottom: 10, child: DecoratedBox(decoration: BoxDecoration(color: Colors.black54, borderRadius: BorderRadius.circular(12)), child: Padding(padding: const EdgeInsets.symmetric(horizontal: 10, vertical: 6), child: Text('${space.label}  ${_placements.length}\uAC1C', style: const TextStyle(color: Colors.white, fontWeight: FontWeight.bold))))),
                    ]),
                  ),
                ),
              ),
            ),
          ),
          Container(
            height: 112,
            padding: const EdgeInsets.fromLTRB(16, 10, 16, 6),
            decoration: const BoxDecoration(color: Color(0xfffffbf5), border: Border(top: BorderSide(color: Color(0xffe8e4dc)))),
            child: Column(crossAxisAlignment: CrossAxisAlignment.start, children: [
              const Text('\uBCF4\uAD00\uD568  \uAE38\uAC8C \uB20C\uB7EC \uBC30\uACBD\uC5D0 \uB04C\uC5B4\uB193\uC544\uC694.', style: TextStyle(fontWeight: FontWeight.w700)),
              const SizedBox(height: 6),
              Expanded(child: inventory.isEmpty ? const Center(child: Text('\uC774 \uACF5\uAC04\uC5D0 \uB193\uC744 \uD68D\uB4DD \uC544\uC774\uD15C\uC774 \uC5C6\uC5B4\uC694.')) : ListView(scrollDirection: Axis.horizontal, children: inventory.map((item) => Padding(padding: const EdgeInsets.only(right: 8), child: LongPressDraggable<Object>(data: item, feedback: _ItemToken(item: item, highlighted: true), childWhenDragging: Opacity(opacity: .35, child: _ItemToken(item: item)), child: _ItemToken(item: item)))).toList())),
            ]),
          ),
        ]),
      ),
    );
  }

  UnlockableItem? _itemFor(String id) {
    final matches = GrowthRewardRepository.items.where((item) => item.id == id).toList();
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
        decoration: BoxDecoration(color: highlighted ? const Color(0xffffedb8) : Colors.white.withValues(alpha: .92), borderRadius: BorderRadius.circular(14), border: Border.all(color: highlighted ? const Color(0xffe6a921) : const Color(0xffd7ded2), width: highlighted ? 2 : 1), boxShadow: const [BoxShadow(color: Color(0x33000000), blurRadius: 5, offset: Offset(0, 2))]),
        child: Column(mainAxisAlignment: MainAxisAlignment.center, children: [_SpaceSprite(itemId: item?.id), Text(item?.name ?? '', overflow: TextOverflow.ellipsis, style: const TextStyle(fontSize: 8))]),
      );
}

class _SpaceSprite extends StatelessWidget {
  const _SpaceSprite({required this.itemId, this.size = 44});
  final String? itemId;
  final double size;
  @override
  Widget build(BuildContext context) {
    final cell = switch (itemId) {
      'bathroom_soap_01' => (-1.0, -1.0),
      'bathroom_toothbrush_01' => (0.0, -1.0),
      'bathroom_towel_01' => (1.0, -1.0),
      'playroom_toybox_01' => (-1.0, 1.0),
      'kitchen_cup_01' => (0.0, 1.0),
      'entrance_bag_01' => (1.0, 1.0),
      _ => null,
    };
    if (cell == null) return Text(itemId == null ? '\uD83D\uDCE6' : '\u2728', style: TextStyle(fontSize: size * .62));
    return SizedBox(
      width: size,
      height: size,
      child: ClipRect(
        child: Align(
          alignment: Alignment(cell.$1, cell.$2),
          widthFactor: 1 / 3,
          heightFactor: 1 / 2,
          child: Image.asset('assets/space_items/room_items.png', width: size * 3, height: size * 2, fit: BoxFit.fill),
        ),
      ),
    );
  }
}

Future<void> showGrowthCelebration(BuildContext context, {required GrowthUnlockResult result, required String profileId}) => showDialog<void>(
      context: context,
      builder: (dialogContext) => AlertDialog(
        icon: Text(result.item.icon, style: const TextStyle(fontSize: 50)),
        title: const Text('\uD63C\uC790 \uD574\uB0C8\uC5B4\uC694'),
        content: Text('\uCC98\uC74C \uD63C\uC790 \uD55C \uD589\uB3D9\uC744 \uAE30\uB150\uD574\uC694.\n${result.item.name} \uC544\uC774\uD15C\uC744 \uC5BB\uC5C8\uC5B4\uC694.'),
        actions: [
          TextButton(onPressed: () => Navigator.pop(dialogContext), child: const Text('\uB098\uC911\uC5D0 \uBCF4\uAE30')),
          FilledButton(
            onPressed: () {
              Navigator.pop(dialogContext);
              Navigator.of(context).push(MaterialPageRoute(builder: (_) => result.item.type == UnlockableItemType.avatarItem ? AvatarPage(profileId: profileId) : SpacePage(profileId: profileId)));
            },
            child: Text(result.item.type == UnlockableItemType.avatarItem ? '\uC544\uBC14\uD0C0 \uAFB8\uBBF8\uAE30' : '\uACF5\uAC04 \uAFB8\uBBF8\uAE30'),
          ),
        ],
      ),
    );
