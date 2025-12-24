import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';
import 'package:sheetopia/data/repositories/scores/score.dart';
import 'package:sheetopia/ui/common/common_badge.dart';
import 'package:sheetopia/ui/common/optional_tooltip.dart';
import 'package:sheetopia/ui/common/tag_badge.dart';
import 'package:sheetopia/ui/common/text_scroll.dart';

class ScoreGridCell extends StatelessWidget {
  static const double width = 250;
  static const double height = 288;
  static final int previewHeight = (height / 2.1).toInt();

  final Score score;

  const ScoreGridCell({super.key, required this.score});

  @override
  Widget build(BuildContext context) {
    final theme = Theme.of(context);
    return SizedBox(
      width: width,
      height: height,
      child: Material(
        borderRadius: BorderRadius.circular(12),
        color: theme.colorScheme.surfaceContainer,
        elevation: 2,
        child: InkWell(
          borderRadius: BorderRadius.circular(12),
          onTap: () {
            context.go("/scores/${score.id}");
          },
          child: Stack(
            children: [
              Column(
                crossAxisAlignment: CrossAxisAlignment.start,
                spacing: 4,
                children: [
                  // TODO: replace with preview
                  ClipRRect(
                    borderRadius: const BorderRadiusGeometry.only(
                      topLeft: Radius.circular(12),
                      topRight: Radius.circular(12),
                    ),
                    child: Container(
                      color: Colors.white,
                      height: previewHeight.toDouble(),
                    ),
                  ),
                  Padding(
                    padding: const EdgeInsets.all(8.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      spacing: 4,
                      children: [
                        OptionalTooltip(
                          message: score.title,
                          child: TextScroll(
                            score.title,
                            fadedBorder: false,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontWeight: FontWeight.w500,
                              fontSize: 16,
                            ),
                          ),
                        ),
                        OptionalTooltip(
                          message: score.composer,
                          child: Text(
                            score.composer ?? "No composer",
                            overflow: TextOverflow.ellipsis,
                            style: theme.textTheme.bodyMedium!.copyWith(
                              fontSize: 14,
                              fontWeight: FontWeight.w300,
                              fontStyle: FontStyle.italic,
                            ),
                          ),
                        ),
                        Padding(
                          padding: const EdgeInsets.only(top: 4),
                          child: SizedBox(
                            height: 24,
                            child: ListView.builder(
                              scrollDirection: Axis.horizontal,
                              itemCount: score.instruments.length,
                              itemBuilder: (context, index) => Padding(
                                padding: index == 0
                                    ? EdgeInsets.zero
                                    : const EdgeInsets.only(left: 4),
                                child: CommonBadge(
                                  name: score.instruments[index],
                                  color:
                                      theme.colorScheme.surfaceContainerHighest,
                                ),
                              ),
                            ),
                          ),
                        ),
                        if (score.tags.isNotEmpty) const Divider(),
                        SizedBox(
                          height: 24,
                          child: ListView.builder(
                            scrollDirection: Axis.horizontal,
                            itemCount: score.tags.length,
                            itemBuilder: (context, index) => Padding(
                              padding: index == 0
                                  ? EdgeInsets.zero
                                  : const EdgeInsets.only(left: 4),
                              child: TagBadge(tag: score.tags[index]),
                            ),
                          ),
                        ),
                      ],
                    ),
                  ),
                ],
              ),
              Align(
                alignment: Alignment.topRight,
                child: Padding(
                  padding: const EdgeInsets.all(4),
                  child: SizedBox.square(
                    dimension: 34,
                    child: IconButton.filled(
                      color: Colors.white,
                      iconSize: 20,
                      padding: const EdgeInsets.all(0),
                      style: ButtonStyle(
                        backgroundColor: WidgetStateProperty.all(
                          Colors.black.withAlpha(100),
                        ),
                      ),
                      onPressed: () {
                        context.go("/scores/${score.id}/edit");
                      },
                      icon: const Icon(Icons.edit),
                    ),
                  ),
                ),
              ),
            ],
          ),
        ),
      ),
    );
  }
}
