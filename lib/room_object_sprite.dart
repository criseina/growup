import 'package:flutter/material.dart';

import 'avatar_room.dart';

class RoomObjectSprite extends StatelessWidget {
  const RoomObjectSprite({super.key, required this.object});

  final RoomObject object;

  @override
  Widget build(BuildContext context) {
    return Image.asset(
      'assets/avatar_layers/objects/extracted/${object.visualAssetId}.png',
      fit: BoxFit.contain,
      alignment: object.anchor == RoomObjectAnchor.floorBottomCenter
          ? Alignment.bottomCenter
          : Alignment.center,
      filterQuality: FilterQuality.medium,
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
