import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/trainings/data/trainings_service.dart';
import 'package:skillmatch_tn/features/trainings/domain/trainings_failure.dart';

import 'support/fake_trainings.dart';

void main() {
  Future<TrainingsFailure> failureOf(TrainingsService service) async {
    try {
      await service.fetch('Docker');
    } on TrainingsException catch (e) {
      return e.failure;
    }
    fail('Une TrainingsException était attendue.');
  }

  test('Envoie le jeton et la compétence telle quelle', () async {
    final fake = fakeTrainingsService();
    fake.api.onFetch = () async => [fakeTraining(id: 'a')];

    final trainings = await fake.service.fetch('Power BI');

    expect(trainings.single.id, 'a');
    final call = fake.api.calls.single;
    expect(call.token, fakeTrainingsToken);
    expect(call.skill, 'Power BI');
  });

  test('Sans jeton : session expirée, rien n\'est envoyé', () async {
    final fake = fakeTrainingsService(token: null);

    expect(await failureOf(fake.service), TrainingsFailure.sessionExpired);
    expect(fake.api.calls, isEmpty);
  });

  test('Jeton vide : session expirée, rien n\'est envoyé', () async {
    final fake = fakeTrainingsService(token: '');

    expect(await failureOf(fake.service), TrainingsFailure.sessionExpired);
    expect(fake.api.calls, isEmpty);
  });

  test('401 : le jeton stocké est effacé', () async {
    final fake = fakeTrainingsService();
    fake.api.onFetch = () async =>
        throw const TrainingsException(TrainingsFailure.sessionExpired);

    expect(await failureOf(fake.service), TrainingsFailure.sessionExpired);
    expect(fake.store.token, isNull);
  });

  test('Autre erreur : le jeton est gardé', () async {
    final fake = fakeTrainingsService();
    fake.api.onFetch = () async =>
        throw const TrainingsException(TrainingsFailure.network);

    expect(await failureOf(fake.service), TrainingsFailure.network);
    expect(fake.store.token, fakeTrainingsToken);
  });
}
