import 'package:skillmatch_tn/features/trainings/data/trainings_api.dart';
import 'package:skillmatch_tn/features/trainings/data/trainings_service.dart';
import 'package:skillmatch_tn/features/trainings/domain/training.dart';

import 'fake_auth.dart';

// Faux objets partagés par les tests des formations : aucun appel réseau,
// aucun accès au stockage du téléphone. Valeurs fictives, propres aux tests.

/// Jeton d'exemple rangé dans le faux stockage.
const fakeTrainingsToken = 'jeton-exemple-formations-456';

/// Faux TrainingsApi : retient les appels et répond ce que le test demande.
class FakeTrainingsApi implements TrainingsApi {
  /// Réponse de fetch. Par défaut : aucune formation.
  Future<List<Training>> Function() onFetch = () async => const [];

  final calls = <({String token, String skill})>[];

  @override
  Future<List<Training>> fetch({required String token, required String skill}) {
    calls.add((token: token, skill: skill));
    return onFetch();
  }
}

/// Service prêt pour un test, avec un jeton déjà rangé (sauf si [token]
/// vaut null).
({TrainingsService service, FakeTrainingsApi api, MemoryTokenStore store})
fakeTrainingsService({String? token = fakeTrainingsToken}) {
  final api = FakeTrainingsApi();
  final store = MemoryTokenStore()..token = token;
  return (
    service: TrainingsService(api: api, tokenStore: store),
    api: api,
    store: store,
  );
}

/// Formation fictive, telle que le serveur pourrait la renvoyer.
Training fakeTraining({
  required String id,
  String skill = 'Docker',
  String? title,
  TrainingLevel level = TrainingLevel.debutant,
  int hours = 3,
  TrainingType type = TrainingType.tutoriel,
  bool isSample = false,
  String? url,
}) => Training(
  id: id,
  skill: skill,
  title: title ?? 'Formation test $id',
  level: level,
  hours: hours,
  type: type,
  isSample: isSample,
  url: url,
);
