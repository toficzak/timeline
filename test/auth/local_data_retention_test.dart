import 'dart:io';

import 'package:drift/native.dart';
import 'package:flutter_test/flutter_test.dart';
import 'package:timelines/auth/auth_controller.dart';
import 'package:timelines/auth/mock_auth_repository.dart';
import 'package:timelines/data/app_database.dart' as db;
import 'package:timelines/timeline/local_photo_store.dart';
import 'package:timelines/timeline/local_timeline_repository.dart';
import 'package:timelines/timeline/timeline.dart';

void main() {
  test('local timeline data survives sign-out and sign-in', () async {
    final db.AppDatabase database = db.AppDatabase(NativeDatabase.memory());
    addTearDown(database.close);
    final LocalTimelineRepository timelineRepository = LocalTimelineRepository(
      database,
      _FakePhotoStore(),
    );
    final AuthController auth = AuthController(MockAuthRepository());

    await auth.initialize();
    final Timeline timeline = await timelineRepository.createTimeline('Shared');
    await timelineRepository.createEntry(
      timelineId: timeline.id,
      description: 'retained locally',
    );

    await auth.signOut();
    expect(await timelineRepository.listTimelines(), [timeline]);

    await auth.signIn();
    expect(await timelineRepository.listEntries(timeline.id), hasLength(1));
    expect(
      (await timelineRepository.listEntries(timeline.id)).single.description,
      'retained locally',
    );
  });
}

class _FakePhotoStore implements PhotoStore {
  @override
  Future<String> importPhoto(File source) async => 'entries/photo.jpg';

  @override
  Future<void> deletePhoto(String relativePath) async {}
}
