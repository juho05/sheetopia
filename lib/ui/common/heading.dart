import 'package:flutter/material.dart';

class SliverHeading extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const SliverHeading({
    super.key,
    required this.text,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SliverPadding(
      padding: padding,
      sliver: SliverToBoxAdapter(
        child: Text(
          text,
          style: theme.textTheme.bodyLarge!.copyWith(
            fontSize: 16,
            fontWeight: FontWeight.w500,
            overflow: TextOverflow.ellipsis,
          ),
        ),
      ),
    );
  }
}

class Heading extends StatelessWidget {
  final String text;
  final EdgeInsets padding;
  const Heading({
    super.key,
    required this.text,
    this.padding = EdgeInsets.zero,
  });

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return Padding(
      padding: padding,
      child: Text(
        text,
        style: theme.textTheme.bodyLarge!.copyWith(
          fontSize: 16,
          fontWeight: FontWeight.w500,
          overflow: TextOverflow.ellipsis,
        ),
      ),
    );
  }
}
