import 'package:skillmatch_tn/features/offers/data/offers_api.dart';
import 'package:skillmatch_tn/features/offers/data/offers_service.dart';
import 'package:skillmatch_tn/features/offers/domain/offer.dart';

import 'fake_auth.dart';

// Faux objets partagés par les tests des offres : aucun appel réseau, aucun
// accès au stockage du téléphone. Valeurs fictives, propres aux tests.

/// Jeton d'exemple rangé dans le faux stockage.
const fakeOffersToken = 'jeton-exemple-offres-789';

/// Faux OffersApi : retient les appels et répond ce que le test demande.
class FakeOffersApi implements OffersApi {
  /// Réponse de fetch. Par défaut : aucune offre.
  Future<List<Offer>> Function() onFetch = () async => const [];

  final calls = <({String token, List<String> skills})>[];

  @override
  Future<List<Offer>> fetch({
    required String token,
    required List<String> skills,
  }) {
    calls.add((token: token, skills: skills));
    return onFetch();
  }
}

/// Service prêt pour un test, avec un jeton déjà rangé (sauf si [token]
/// vaut null).
({OffersService service, FakeOffersApi api, MemoryTokenStore store})
fakeOffersService({String? token = fakeOffersToken}) {
  final api = FakeOffersApi();
  final store = MemoryTokenStore()..token = token;
  return (
    service: OffersService(api: api, tokenStore: store),
    api: api,
    store: store,
  );
}

/// Offre fictive, telle que le serveur pourrait la renvoyer.
Offer fakeOffer({
  required String id,
  String? title,
  OfferType type = OfferType.stage,
  bool isSample = false,
  int score = 0,
  String explanation = 'Explication du serveur (test)',
  List<String> requiredAcquired = const [],
  List<String> requiredMissing = const [],
  List<String> preferredAcquired = const [],
  List<String> preferredMissing = const [],
}) => Offer(
  id: id,
  title: title ?? 'Offre $id',
  company: 'Entreprise test $id',
  city: 'Ville test',
  type: type,
  isSample: isSample,
  score: score,
  explanation: explanation,
  requiredAcquired: requiredAcquired,
  requiredMissing: requiredMissing,
  preferredAcquired: preferredAcquired,
  preferredMissing: preferredMissing,
);
