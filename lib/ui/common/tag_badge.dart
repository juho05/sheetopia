import 'package:flutter/material.dart';
import 'package:sheetopia/data/repositories/scores/tag.dart';
import 'package:sheetopia/ui/common/common_badge.dart';

class TagBadge extends StatelessWidget {
  final Tag tag;
  final void Function()? onTap;
  final void Function()? onRemove;

  const TagBadge({super.key, required this.tag, this.onTap, this.onRemove});

  @override
  Widget build(BuildContext context) {
    return CommonBadge(
      name: tag.name,
      color: tag.color,
      onTap: onTap,
      onRemove: onRemove,
    );
  }
}
