import 'dart:math';
import 'dart:typed_data';

import 'package:image/image.dart' as img;

import 'util.dart';

img.Image decode(Uint8List png) {
  final image = img.decodePng(png);
  if (image == null) throw ToolException('captured an invalid PNG');
  return image;
}

/// [light] below the diagonal from the top left to the bottom right corner,
/// [dark] above it, like the README's library screenshot.
img.Image diagonal(img.Image light, img.Image dark) {
  if (light.width != dark.width || light.height != dark.height) {
    throw ToolException('light and dark capture differ in size');
  }
  final w = light.width, h = light.height;
  final length = sqrt(w * w + h * h);
  final out = img.Image(width: w, height: h, numChannels: 4);
  for (var y = 0; y < h; y++) {
    for (var x = 0; x < w; x++) {
      // Signed distance to the diagonal in pixels, positive below it.
      final d = (y * w - x * h) / length;
      final t = (d + 0.5).clamp(0.0, 1.0);
      final a = light.getPixel(x, y), b = dark.getPixel(x, y);
      out.setPixelRgba(
        x,
        y,
        a.r * t + b.r * (1 - t),
        a.g * t + b.g * (1 - t),
        a.b * t + b.b * (1 - t),
        a.a * t + b.a * (1 - t),
      );
    }
  }
  return out;
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

Uint8List encode(img.Image image) => img.encodePng(image, level: 9);
