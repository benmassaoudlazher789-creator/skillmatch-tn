import 'dart:typed_data';

import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/cv/data/cv_analysis_service.dart';
import 'package:skillmatch_tn/features/cv/data/cv_picker.dart';
import 'package:skillmatch_tn/features/cv/domain/cv_failure.dart';
import 'package:skillmatch_tn/features/cv/domain/cv_file_rules.dart';

import 'support/fake_cv.dart';

void main() {
  /// Lance l'analyse et renvoie la raison de l'échec.
  Future<CvFailure> failureOf(
    CvAnalysisService service, [
    PickedCvFile file = fakeCvFile,
  ]) async {
    try {
      await service.analyze(file);
    } on CvException catch (e) {
      return e.failure;
    }
    fail('Une CvException était attendue.');
  }

  test('Envoie le jeton, le contenu et l\'extension du fichier', () async {
    final fake = fakeCvService();
    const docx = PickedCvFile(
      name: 'Mon CV.DOCX',
      sizeInBytes: 20,
      readBytes: fakePdfBytes,
    );

    final skills = await fake.service.analyze(docx);

    expect(skills, ['Dart', 'Flutter', 'SQL', 'Git']);
    expect(fake.api.calls, hasLength(1));
    final call = fake.api.calls.single;
    expect(call.token, fakeCvToken);
    expect(call.extension, 'docx');
    expect(call.bytes, await fakePdfBytes());
  });

  test('Sans jeton : session expirée, rien n\'est envoyé', () async {
    final fake = fakeCvService(token: null);

    expect(await failureOf(fake.service), CvFailure.sessionExpired);
    expect(fake.api.calls, isEmpty);
  });

  test('401 : le jeton stocké est effacé', () async {
    final fake = fakeCvService();
    fake.api.onAnalyze = () async =>
        throw const CvException(CvFailure.sessionExpired);

    expect(await failureOf(fake.service), CvFailure.sessionExpired);
    expect(fake.store.token, isNull);
  });

  test('Autre erreur : le jeton est gardé', () async {
    final fake = fakeCvService();
    fake.api.onAnalyze = () async =>
        throw const CvException(CvFailure.tooManyRequests);

    expect(await failureOf(fake.service), CvFailure.tooManyRequests);
    expect(fake.store.token, fakeCvToken);
  });

  test('Fichier illisible sur le téléphone : message dédié', () async {
    final fake = fakeCvService();
    const broken = PickedCvFile(
      name: 'cv.pdf',
      sizeInBytes: 20,
      readBytes: failingBytes,
    );

    expect(await failureOf(fake.service, broken), CvFailure.fileRead);
    expect(fake.api.calls, isEmpty);
  });

  test('Fichier devenu vide ou trop gros : refusé avant l\'envoi', () async {
    final fake = fakeCvService();
    final empty = PickedCvFile(
      name: 'cv.pdf',
      sizeInBytes: 20,
      readBytes: () async => Uint8List(0),
    );
    final huge = PickedCvFile(
      name: 'cv.pdf',
      sizeInBytes: 20,
      readBytes: () async => Uint8List(CvFileRules.maxSizeInBytes + 1),
    );

    expect(await failureOf(fake.service, empty), CvFailure.empty);
    expect(await failureOf(fake.service, huge), CvFailure.tooLarge);
    expect(fake.api.calls, isEmpty);
  });

  test('La liste reçue est nettoyée : espaces, vides et doublons', () {
    expect(
      CvAnalysisService.tidy([' Flutter ', 'flutter', '', 'Power   BI', 'SQL']),
      ['Flutter', 'Power BI', 'SQL'],
    );
  });
}
