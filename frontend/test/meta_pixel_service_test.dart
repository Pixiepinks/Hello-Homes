import 'dart:math';

import 'package:flutter_test/flutter_test.dart';
import 'package:frontend/utils/meta_pixel_service.dart';

void main() {
  test('generateEventId returns a purchase event id without throwing', () {
    final eventId = MetaPixelService.generateEventId(random: Random(1));

    expect(eventId, matches(RegExp(r'^hh_purchase_\d+_[0-9a-f]{16}$')));
  });

  test('generateEventId remains safe over repeated calls', () {
    final random = Random(42);

    for (var i = 0; i < 1000; i++) {
      expect(
        () => MetaPixelService.generateEventId(random: random),
        returnsNormally,
      );
    }
  });
}
