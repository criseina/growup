import 'package:flutter/material.dart';

import 'avatar_room.dart';

class RoomObjectSprite extends StatelessWidget {
  const RoomObjectSprite({super.key, required this.object});

  final RoomObject object;

  static const _sources = <String, ({String theme, int column, int row})>{
    'bathroom_mirror': (theme: 'bathroom', column: 0, row: 0),
    'bathroom_sink': (theme: 'bathroom', column: 1, row: 0),
    'bathroom_bathtub': (theme: 'bathroom', column: 2, row: 0),
    'bathroom_shower': (theme: 'bathroom', column: 3, row: 0),
    'bedroom_bed': (theme: 'bedroom', column: 0, row: 0),
    'bedroom_mirror': (theme: 'bedroom', column: 1, row: 0),
    'bedroom_wardrobe': (theme: 'bedroom', column: 2, row: 0),
    'bedroom_drawer': (theme: 'bedroom', column: 3, row: 0),
    'kitchen_table': (theme: 'kitchen', column: 0, row: 0),
    'kitchen_cabinet': (theme: 'kitchen', column: 1, row: 0),
    'kitchen_sink': (theme: 'kitchen', column: 2, row: 0),
    'kitchen_fridge': (theme: 'kitchen', column: 3, row: 0),
    'playroom_low_shelf': (theme: 'playroom', column: 0, row: 0),
    'playroom_bookshelf': (theme: 'playroom', column: 1, row: 0),
    'entrance_shoe_rack': (theme: 'entrance', column: 0, row: 0),
    'entrance_hooks': (theme: 'entrance', column: 1, row: 0),
    'entrance_traffic_light': (theme: 'entrance', column: 0, row: 1),
    'entrance_crosswalk': (theme: 'entrance', column: 1, row: 1),
    'toilet_bowl': (theme: 'toilet', column: 0, row: 0),
    'toilet_sink': (theme: 'toilet', column: 1, row: 0),
    'toilet_flush': (theme: 'toilet', column: 2, row: 0),
    'toilet_paper_holder': (theme: 'toilet', column: 3, row: 0),
  };

  @override
  Widget build(BuildContext context) {
    final source = _sources[object.visualAssetId];
    if (source == null) return const SizedBox.shrink();
    // The toilet atlas was generated with a transparent background. Other
    // atlases are chroma-keyed to transparent during the asset pipeline.
    return LayoutBuilder(
      builder: (context, box) => ClipRect(
        child: OverflowBox(
          alignment: Alignment(
            -1 + source.column * (2 / 3),
            -1 + source.row * 2,
          ),
          minWidth: box.maxWidth * 4,
          maxWidth: box.maxWidth * 4,
          minHeight: box.maxHeight * 2,
          maxHeight: box.maxHeight * 2,
          child: Image.asset(
            'assets/avatar_layers/objects/${source.theme}.png',
            width: box.maxWidth * 4,
            height: box.maxHeight * 2,
            fit: BoxFit.fill,
          ),
        ),
      ),
    );
  }
}

class PositionedRoomObject extends StatelessWidget {
  const PositionedRoomObject({
    super.key,
    required this.object,
    required this.viewportSize,
  });

  final RoomObject object;
  final Size viewportSize;

  @override
  Widget build(BuildContext context) {
    final bounds = object.visualBounds;
    return Positioned(
      left: bounds.left * viewportSize.width / 100,
      top: bounds.top * viewportSize.height / 100,
      width: bounds.width * viewportSize.width / 100,
      height: bounds.height * viewportSize.height / 100,
      child: IgnorePointer(child: RoomObjectSprite(object: object)),
    );
  }
}
