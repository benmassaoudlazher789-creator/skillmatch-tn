import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/offers/data/offers_service.dart';
import 'package:skillmatch_tn/features/offers/domain/offers_failure.dart';

import 'support/fake_offers.dart';

void main() {
  Future<OffersFailure> failureOf(OffersService service) async {
    try {
      await service.fetch(const ['Dart']);
    } on OffersException catch (e) {
      return e.failure;
    }
    fail('Une OffersException était attendue.');
  }

  test('Envoie le jeton et les compétences telles quelles', () async {
    final fake = fakeOffersService();
    fake.api.onFetch = () async => [fakeOffer(id: 'a')];

    final offers = await fake.service.fetch(const ['Dart', 'SQL']);

    expect(offers.single.id, 'a');
    final call = fake.api.calls.single;
    expect(call.token, fakeOffersToken);
    expect(call.skills, ['Dart', 'SQL']);
  });

  test('Sans jeton : session expirée, rien n\'est envoyé', () async {
    final fake = fakeOffersService(token: null);

    expect(await failureOf(fake.service), OffersFailure.sessionExpired);
    expect(fake.api.calls, isEmpty);
  });

  test('401 : le jeton stocké est effacé', () async {
    final fake = fakeOffersService();
    fake.api.onFetch = () async =>
        throw const OffersException(OffersFailure.sessionExpired);

    expect(await failureOf(fake.service), OffersFailure.sessionExpired);
    expect(fake.store.token, isNull);
  });

  test('Autre erreur : le jeton est gardé', () async {
    final fake = fakeOffersService();
    fake.api.onFetch = () async =>
        throw const OffersException(OffersFailure.network);

    expect(await failureOf(fake.service), OffersFailure.network);
    expect(fake.store.token, fakeOffersToken);
  });
}
