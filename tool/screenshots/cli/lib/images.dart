import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'util.dart';

img.Image decode(Uint8List png) {
  final image = img.decodePng(png);
  if (image == null) throw ToolException('captured an invalid PNG');
  return image;
}

/// The stores reject screenshots with an alpha channel.
img.Image opaque(img.Image image) {
  if (image.numChannels < 4) return image;
  final out = img.Image(width: image.width, height: image.height, numChannels: 3);
  for (final px in image) {
    final a = px.a / px.maxChannelValue;
    out.setPixelRgb(px.x, px.y, px.r * a + 255 * (1 - a), px.g * a + 255 * (1 - a), px.b * a + 255 * (1 - a));
  }
  return out;
}

/// Fills transparent pixels at the start and end of each row with the row's
/// first and last opaque colour, for the rounded corners of a window capture.
img.Image fillCorners(img.Image image) {
  final max = image.maxChannelValue;
  for (var y = 0; y < image.height; y++) {
    for (final xs in [
      Iterable<int>.generate(image.width),
      Iterable<int>.generate(image.width, (i) => image.width - 1 - i),
    ]) {
      final edge = xs.firstWhere((x) => image.getPixel(x, y).a == max, orElse: () => -1);
      if (edge <= 0 || edge == image.width - 1) continue;
      final fill = image.getPixel(edge, y);
      for (final x in xs.takeWhile((x) => x != edge)) {
        image.setPixelRgba(x, y, fill.r, fill.g, fill.b, max);
      }
    }
  }
  return image;
}

Uint8List encode(img.Image image) => img.encodePng(image, level: 9);
