import 'package:flutter_test/flutter_test.dart';

import 'package:skillmatch_tn/features/cv/domain/cv_file_rules.dart';

void main() {
  const mega = 1024 * 1024;

  String? validate(String name, int size) =>
      CvFileRules.validate(fileName: name, sizeInBytes: size);

  group('CvFileRules.validate', () {
    test('PDF et DOCX acceptés, majuscules comprises', () {
      expect(validate('cv.pdf', 1000), isNull);
      expect(validate('cv.docx', 1000), isNull);
      expect(validate('MON_CV.PDF', 1000), isNull);
    });

    test('autres formats et noms sans extension refusés', () {
      // Ancien format Word : le serveur ne le lit pas.
      expect(validate('cv.doc', 1000), CvFileRules.formatError);
      expect(validate('cv.png', 1000), CvFileRules.formatError);
      expect(validate('cv.pdf.exe', 1000), CvFileRules.formatError);
      expect(validate('cv', 1000), CvFileRules.formatError);
      expect(validate('cv.', 1000), CvFileRules.formatError);
      expect(validate('.pdf', 1000), CvFileRules.formatError);
    });

    test(
      'limite de 5 Mo : exactement 5 Mo accepté, 1 octet de plus refusé',
      () {
        expect(validate('cv.pdf', 5 * mega), isNull);
        expect(
          validate('cv.pdf', 5 * mega + 1),
          CvFileRules.tooLargeError(5 * mega + 1),
        );
      },
    );

    test('fichier vide refusé', () {
      expect(validate('cv.pdf', 0), CvFileRules.emptyError);
    });
  });

  group('CvFileRules.formatSize', () {
    test('octets, Ko et Mo à la française', () {
      expect(CvFileRules.formatSize(512), '512 octets');
      expect(CvFileRules.formatSize(350 * 1024), '350 Ko');
      expect(CvFileRules.formatSize((1.2 * mega).round()), '1,2 Mo');
      expect(CvFileRules.formatSize(6 * mega), '6 Mo');
    });
  });
}
