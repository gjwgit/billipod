/// Tests for reporting failures from Pod writes that nothing awaits.
///
// Runs without a live Pod: the save future is stood in for directly.
//
// Run: flutter test test/write_failure_test.dart

library;

import 'package:flutter_test/flutter_test.dart';
import 'package:solidui/solidui.dart';

void main() {
  setUp(SolidWriteFailures.clear);

  test('a save completing with an error String is reported', () async {
    SolidWriteFailures.watch(
      Future<String?>.value('Pod unreachable'),
      during: 'updating the star',
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      SolidWriteFailures.latest.value,
      'Failed updating the star.\n\nPod unreachable',
    );
  });

  test('a save completing with null reports nothing', () async {
    SolidWriteFailures.watch(
      Future<String?>.value(),
      during: 'moving the bill to Scheduled',
    );
    await Future<void>.delayed(Duration.zero);

    expect(SolidWriteFailures.latest.value, isNull);
  });

  test('a save that throws is reported', () async {
    SolidWriteFailures.watch(
      Future<String?>.error(Exception('no network')),
      during: 'moving the bill to Expected',
    );
    await Future<void>.delayed(Duration.zero);

    expect(
      SolidWriteFailures.latest.value,
      contains('Failed moving the bill to Expected.'),
    );
  });
}
