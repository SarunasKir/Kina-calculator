import 'package:kina_data/kina_data.dart';
import 'package:test/test.dart';

import 'helpers.dart';

void main() {
  late KinaDatabase db;
  late ProfileRepository repo;
  final settings = CalculatorSettings.defaults;

  setUp(() {
    db = openTestDatabase();
    repo = ProfileRepository(db);
  });
  tearDown(() => db.close());

  test('saves and lists profiles sorted by name', () async {
    await repo.save('weekend', settings);
    await repo.save('Alpha', settings);
    final names = (await repo.list()).map((p) => p.name);
    expect(names, ['Alpha', 'weekend']);
  });

  test('same name ignoring case updates instead of adding', () async {
    final first = await repo.save('Weekend', settings);
    final second = await repo.save(
      '  WEEKEND ',
      CalculatorSettings.fromJson(const {'amountMillions': '9'}),
    );
    expect(second.id, first.id);
    final all = await repo.list();
    expect(all, hasLength(1));
    expect(all.single.name, 'WEEKEND');
    expect(all.single.settings.amountMillions, '9');
  });

  test('rejects empty and long names', () async {
    await expectLater(
      repo.save('   ', settings),
      throwsA(
        isA<ProfileException>().having(
          (e) => e.error,
          'error',
          ProfileError.emptyName,
        ),
      ),
    );
    await expectLater(
      repo.save('x' * 43, settings),
      throwsA(
        isA<ProfileException>().having(
          (e) => e.error,
          'error',
          ProfileError.nameTooLong,
        ),
      ),
    );
    expect(await repo.save('x' * 42, settings), isA<Profile>());
    expect(
      const ProfileException(ProfileError.tooMany).toString(),
      contains('tooMany'),
    );
  });

  test('stops at 50 profiles but still allows updates', () async {
    for (var i = 0; i < ProfileRepository.maxProfiles; i++) {
      await repo.save('Profile $i', settings);
    }
    await expectLater(
      repo.save('One more', settings),
      throwsA(isA<ProfileException>()),
    );
    await repo.save('profile 7', settings);
    expect(await repo.list(), hasLength(50));
  });

  test('delete hides the profile and frees the name', () async {
    final p = await repo.save('Temp', settings);
    await repo.delete(p.id);
    expect(await repo.list(), isEmpty);
    final again = await repo.save('Temp', settings);
    expect(again.id, isNot(p.id));
  });
}
