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
    final alignmentY = (-1 + source.row).toDouble();
    return SizedBox.square(
      dimension: size,
      child: ClipRect(
        child: OverflowBox(
          alignment: Alignment(alignmentX, alignmentY),
          minWidth: size * 4,
          maxWidth: size * 4,
          minHeight: size * 3,
          maxHeight: size * 3,
          child: Image.asset(
            source.asset,
            width: size * 4,
            height: size * 3,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }

  ({String asset, int column, int row})? _sourceFor(String id) {
    const atlasA = 'assets/space_items/room_items_a.png';
    const atlasB = 'assets/space_items/room_items_b.png';
    return switch (id) {
      'bathroom_soap_01' => (asset: atlasA, column: 0, row: 0),
      'bathroom_towel_01' => (asset: atlasA, column: 1, row: 0),
      'bathroom_toothbrush_01' => (asset: atlasA, column: 2, row: 0),
      'bathroom_shampoo_01' => (asset: atlasA, column: 3, row: 0),
      'bedroom_rack_01' => (asset: atlasA, column: 0, row: 1),
      'bedroom_basket_01' => (asset: atlasA, column: 1, row: 1),
      'bedroom_folded_01' => (asset: atlasA, column: 2, row: 1),
      'bedroom_hat_01' => (asset: atlasA, column: 3, row: 1),
      'kitchen_cup_01' => (asset: atlasA, column: 0, row: 2),
      'kitchen_cutlery_01' => (asset: atlasA, column: 1, row: 2),
      'kitchen_dishes_01' => (asset: atlasA, column: 2, row: 2),
      'kitchen_cloth_01' => (asset: atlasA, column: 3, row: 2),
      'playroom_toybox_01' => (asset: atlasB, column: 0, row: 0),
      'playroom_shelf_01' => (asset: atlasB, column: 1, row: 0),
      'playroom_laundry_01' => (asset: atlasB, column: 2, row: 0),
      'playroom_trash_01' => (asset: atlasB, column: 3, row: 0),
      'entrance_bag_01' => (asset: atlasB, column: 0, row: 1),
      'entrance_bottle_01' => (asset: atlasB, column: 1, row: 1),
      'entrance_wipes_01' => (asset: atlasB, column: 2, row: 1),
      'entrance_umbrella_01' => (asset: atlasB, column: 3, row: 1),
      'safety_cone_01' => (asset: atlasB, column: 0, row: 2),
      'safety_stop_01' => (asset: atlasB, column: 1, row: 2),
      'safety_crosswalk_01' => (asset: atlasB, column: 2, row: 2),
      'safety_contact_01' => (asset: atlasB, column: 3, row: 2),
      'toilet_paper_01' => (asset: atlasA, column: 1, row: 0),
      'toilet_wipes_01' => (asset: atlasB, column: 2, row: 1),
      'toilet_soap_01' => (asset: atlasA, column: 0, row: 0),
      'toilet_towel_01' => (asset: atlasA, column: 1, row: 0),
      _ => null,
    };
  }
}
