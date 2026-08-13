import 'package:flutter/material.dart';

class AvatarObjectSprite extends StatelessWidget {
  const AvatarObjectSprite({super.key, required this.itemId, this.size = 58});

  final String itemId;
  final double size;

  @override
  Widget build(BuildContext context) {
    final source = _sourceFor(itemId);
    if (source == null) {
      return SizedBox.square(
        dimension: size,
        child: const Center(
          child: Icon(Icons.auto_awesome, color: Color(0xffd39b2a)),
        ),
      );
    }
    final alignmentX = -1 + source.column * (2 / 3);
    final alignmentY = source.rows == 1
        ? 0.0
        : -1 + source.row * (2 / (source.rows - 1));
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(alignmentX, alignmentY),
          minWidth: size * 4,
          maxWidth: size * 4,
          minHeight: size * source.rows,
          maxHeight: size * source.rows,
          child: Image.asset(
            source.asset,
            width: size * 4,
            height: size * source.rows,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  ({String asset, int column, int row, int rows})? _sourceFor(String id) {
    const atlasA = 'assets/space_items/room_items_a.png';
    const atlasB = 'assets/space_items/room_items_b.png';
    return switch (id) {
      'bathroom_soap_01' => (asset: atlasA, column: 0, row: 0, rows: 3),
      'bathroom_towel_01' => (asset: atlasA, column: 1, row: 0, rows: 3),
      'bathroom_toothbrush_01' => (asset: atlasA, column: 2, row: 0, rows: 3),
      'bathroom_shampoo_01' => (asset: atlasA, column: 3, row: 0, rows: 3),
      'bedroom_rack_01' => (asset: atlasA, column: 0, row: 1, rows: 3),
      'bedroom_basket_01' => (asset: atlasA, column: 1, row: 1, rows: 3),
      'bedroom_folded_01' => (asset: atlasA, column: 2, row: 1, rows: 3),
      'bedroom_hat_01' => (asset: atlasA, column: 3, row: 1, rows: 3),
      'kitchen_cup_01' => (asset: atlasA, column: 0, row: 2, rows: 3),
      'kitchen_cutlery_01' => (asset: atlasA, column: 1, row: 2, rows: 3),
      'kitchen_dishes_01' => (asset: atlasA, column: 2, row: 2, rows: 3),
      'kitchen_cloth_01' => (asset: atlasA, column: 3, row: 2, rows: 3),
      'playroom_toybox_01' => (asset: atlasB, column: 0, row: 0, rows: 3),
      'playroom_shelf_01' => (asset: atlasB, column: 1, row: 0, rows: 3),
      'playroom_laundry_01' => (asset: atlasB, column: 2, row: 0, rows: 3),
      'playroom_trash_01' => (asset: atlasB, column: 3, row: 0, rows: 3),
      'entrance_bag_01' => (asset: atlasB, column: 0, row: 1, rows: 3),
      'entrance_bottle_01' => (asset: atlasB, column: 1, row: 1, rows: 3),
      'entrance_wipes_01' => (asset: atlasB, column: 2, row: 1, rows: 3),
      'entrance_umbrella_01' => (asset: atlasB, column: 3, row: 1, rows: 3),
      'safety_cone_01' => (asset: atlasB, column: 0, row: 2, rows: 3),
      'safety_stop_01' => (asset: atlasB, column: 1, row: 2, rows: 3),
      'safety_crosswalk_01' => (asset: atlasB, column: 2, row: 2, rows: 3),
      'safety_contact_01' => (asset: atlasB, column: 3, row: 2, rows: 3),
      'toilet_paper_01' => (
        asset: 'assets/space_items/toilet_items.png',
        column: 0,
        row: 0,
        rows: 1,
      ),
      'toilet_wipes_01' => (
        asset: 'assets/space_items/toilet_items.png',
        column: 1,
        row: 0,
        rows: 1,
      ),
      'toilet_soap_01' => (
        asset: 'assets/space_items/toilet_items.png',
        column: 2,
        row: 0,
        rows: 1,
      ),
      'toilet_towel_01' => (
        asset: 'assets/space_items/toilet_items.png',
        column: 3,
        row: 0,
        rows: 1,
      ),
      _ => null,
    };
  }
}

class RewardItemVisual extends StatelessWidget {
  const RewardItemVisual({
    super.key,
    required this.itemId,
    required this.fallbackIcon,
    required this.isSpaceItem,
    this.size = 62,
  });

  final String itemId;
  final String fallbackIcon;
  final bool isSpaceItem;
  final double size;

  @override
  Widget build(BuildContext context) {
    if (isSpaceItem) return AvatarObjectSprite(itemId: itemId, size: size);
    if (!AvatarRewardItemSprite.supports(itemId)) {
      return SizedBox.square(
        dimension: size,
        child: Center(
          child: Text(fallbackIcon, style: TextStyle(fontSize: size * .75)),
        ),
      );
    }
    return AvatarRewardItemSprite(itemId: itemId, size: size);
  }
}

class AvatarRewardItemSprite extends StatelessWidget {
  const AvatarRewardItemSprite({
    super.key,
    required this.itemId,
    this.size = 58,
  });

  final String itemId;
  final double size;

  static bool supports(String itemId) => const {
    'avatar_top_01',
    'avatar_bottom_01',
    'avatar_shoes_01',
    'avatar_hat_01',
    'avatar_accessory_01',
  }.contains(itemId);

  @override
  Widget build(BuildContext context) {
    final column = switch (itemId) {
      'avatar_top_01' => 0,
      'avatar_bottom_01' => 1,
      'avatar_shoes_01' => 2,
      'avatar_hat_01' => 3,
      'avatar_accessory_01' => 0,
      _ => 0,
    };
    final row = itemId == 'avatar_accessory_01' ? 1 : 0;
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(-1 + column * (2 / 3), -1 + row * 2),
          minWidth: size * 4,
          maxWidth: size * 4,
          minHeight: size * 2,
          maxHeight: size * 2,
          child: Image.asset(
            'assets/avatars/avatar_reward_items.png',
            width: size * 4,
            height: size * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}
