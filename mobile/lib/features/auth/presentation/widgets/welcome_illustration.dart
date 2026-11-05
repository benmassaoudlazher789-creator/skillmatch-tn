import 'dart:math' as math;

import 'package:flutter/material.dart';

import '../../../../core/theme/app_colors.dart';
import '../../../../core/theme/app_spacing.dart';

/// Illustration de l'écran Bienvenue, dessinée en formes géométriques.
///
/// Pourquoi un CustomPainter plutôt qu'une photo ? Pas de fichier image à
/// gérer, aucune personne réelle représentée, et le dessin s'adapte à
/// toutes les largeurs d'écran. Il raconte l'idée de l'application :
/// un CV (à gauche) → des compétences détectées (au centre) → un score
/// de correspondance (à droite).
///
/// Pour l'instant, l'écran Bienvenue affiche la photo (WelcomeHero) et non
/// cette illustration. On garde ce widget dans le projet pour deux raisons :
/// - WelcomeHero l'affiche à la place de la photo si celle-ci ne se charge
///   pas (errorBuilder) ;
/// - on pourra le remettre en haut de l'écran Bienvenue (à la place de
///   const WelcomeHero() dans welcome_screen.dart) si la photo est retirée.
class WelcomeIllustration extends StatelessWidget {
  const WelcomeIllustration({super.key, this.height = 144}); // h-36

  final double height;

  @override
  Widget build(BuildContext context) {
    return Semantics(
      label: 'Illustration : un CV relié à des compétences et à un score',
      image: true,
      // shadow-md : l'ombre est posée autour du ClipRRect, sinon le
      // découpage des coins la masquerait.
      child: DecoratedBox(
        decoration: BoxDecoration(
          borderRadius: BorderRadius.circular(AppRadius.media),
          boxShadow: const [
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 4),
              blurRadius: 6,
              spreadRadius: -1,
            ),
            BoxShadow(
              color: Color(0x1A000000),
              offset: Offset(0, 2),
              blurRadius: 4,
              spreadRadius: -2,
            ),
          ],
        ),
        child: ClipRRect(
          borderRadius: BorderRadius.circular(AppRadius.media),
          child: SizedBox(
            height: height,
            width: double.infinity,
            child: const CustomPaint(painter: _WelcomePainter()),
          ),
        ),
      ),
    );
  }
}

class _WelcomePainter extends CustomPainter {
  const _WelcomePainter();

  static const _panel = Color(0xFF173452);
  static const _panelLine = Color(0xFF1F4064);
  static const _sheet = Color(0xFFF7F5EF);
  static const _sheetLine = Color(0xFFD9D5C8);
  static const _link = Color(0xFF4F6B8A);
  static const _softBlue = Color(0xFF8FB3D9);

  @override
  void paint(Canvas canvas, Size size) {
    final w = size.width;
    final h = size.height;

    // 1. Fond du panneau + quadrillage discret.
    canvas.drawRect(Offset.zero & size, Paint()..color = _panel);
    final grid = Paint()
      ..color = _panelLine
      ..strokeWidth = 1;
    for (var x = 0.0; x < w; x += 24) {
      canvas.drawLine(Offset(x, 0), Offset(x, h), grid);
    }
    for (var y = 0.0; y < h; y += 24) {
      canvas.drawLine(Offset(0, y), Offset(w, y), grid);
    }

    // 2. La feuille de CV, légèrement inclinée.
    final sheetW = math.min(92.0, w * 0.26);
    final sheetH = h * 0.74;
    final sheetCenter = Offset(w * 0.17, h * 0.5);
    canvas.save();
    canvas.translate(sheetCenter.dx, sheetCenter.dy);
    canvas.rotate(-0.07);
    final sheetRect = Rect.fromCenter(
      center: Offset.zero,
      width: sheetW,
      height: sheetH,
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(
        sheetRect.shift(const Offset(3, 4)),
        const Radius.circular(8),
      ),
      Paint()..color = Colors.black.withValues(alpha: 0.18),
    );
    canvas.drawRRect(
      RRect.fromRectAndRadius(sheetRect, const Radius.circular(8)),
      Paint()..color = _sheet,
    );
    // En-tête du CV : un rond (photo) et deux lignes (nom, titre).
    final pad = sheetW * 0.14;
    final avatarR = sheetW * 0.11;
    final avatarC = Offset(
      sheetRect.left + pad + avatarR,
      sheetRect.top + pad + avatarR,
    );
    canvas.drawCircle(avatarC, avatarR, Paint()..color = AppColors.navy);
    final linePaint = Paint()
      ..color = _sheetLine
      ..strokeWidth = 4
      ..strokeCap = StrokeCap.round;
    final textLeft = avatarC.dx + avatarR + 6;
    canvas.drawLine(
      Offset(textLeft, avatarC.dy - 4),
      Offset(sheetRect.right - pad, avatarC.dy - 4),
      linePaint..color = AppColors.navy.withValues(alpha: 0.7),
    );
    canvas.drawLine(
      Offset(textLeft, avatarC.dy + 5),
      Offset(sheetRect.right - pad * 1.8, avatarC.dy + 5),
      linePaint..color = _sheetLine,
    );
    // Corps du CV : quelques lignes, dont deux surlignées (compétences).
    var y = avatarC.dy + avatarR + pad;
    final highlights = {1: AppColors.emerald, 3: AppColors.amber};
    for (var i = 0; y < sheetRect.bottom - pad * 0.6; i++) {
      final end = sheetRect.right - pad - (i.isOdd ? sheetW * 0.18 : 0);
      linePaint.color = highlights[i] ?? _sheetLine;
      canvas.drawLine(
        Offset(sheetRect.left + pad, y),
        Offset(end, y),
        linePaint,
      );
      y += 9;
    }
    canvas.restore();

    // 3. Les compétences détectées : des pastilles reliées au CV.
    final linkStart = Offset(sheetCenter.dx + sheetW / 2 + 4, h * 0.5);
    final skills = <(Offset, double, Color)>[
      (Offset(w * 0.47, h * 0.24), 11, AppColors.emerald),
      (Offset(w * 0.55, h * 0.52), 8, AppColors.amber),
      (Offset(w * 0.45, h * 0.78), 9, _softBlue),
      (Offset(w * 0.62, h * 0.22), 6, _softBlue),
    ];
    final ring = _ringCenter(size);
    final linkPaint = Paint()
      ..color = _link
      ..strokeWidth = 1.5
      ..style = PaintingStyle.stroke;
    for (final (c, _, _) in skills) {
      final path = Path()
        ..moveTo(linkStart.dx, linkStart.dy)
        ..quadraticBezierTo((linkStart.dx + c.dx) / 2, c.dy, c.dx, c.dy)
        ..lineTo(ring.dx - _ringRadius(size), ring.dy);
      canvas.drawPath(path, linkPaint);
    }
    for (final (c, r, color) in skills) {
      canvas.drawCircle(
        c,
        r + 5,
        Paint()..color = color.withValues(alpha: 0.18),
      );
      canvas.drawCircle(c, r, Paint()..color = color);
    }

    // 4. L'anneau de score, partiellement rempli.
    final ringR = _ringRadius(size);
    final ringRect = Rect.fromCircle(center: ring, radius: ringR);
    canvas.drawCircle(
      ring,
      ringR,
      Paint()
        ..color = _panelLine
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9,
    );
    canvas.drawArc(
      ringRect,
      -math.pi / 2,
      2 * math.pi * 0.7,
      false,
      Paint()
        ..color = AppColors.emerald
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    // Petite portion ambre : ce qu'il reste à apprendre.
    canvas.drawArc(
      ringRect,
      -math.pi / 2 + 2 * math.pi * 0.75,
      2 * math.pi * 0.12,
      false,
      Paint()
        ..color = AppColors.amber
        ..style = PaintingStyle.stroke
        ..strokeWidth = 9
        ..strokeCap = StrokeCap.round,
    );
    // Au centre : une coche (le profil correspond).
    final check = Path()
      ..moveTo(ring.dx - ringR * 0.32, ring.dy + ringR * 0.02)
      ..lineTo(ring.dx - ringR * 0.08, ring.dy + ringR * 0.26)
      ..lineTo(ring.dx + ringR * 0.34, ring.dy - ringR * 0.22);
    canvas.drawPath(
      check,
      Paint()
        ..color = AppColors.onNavy
        ..style = PaintingStyle.stroke
        ..strokeWidth = 4
        ..strokeCap = StrokeCap.round
        ..strokeJoin = StrokeJoin.round,
    );
  }

  Offset _ringCenter(Size s) => Offset(s.width * 0.83, s.height * 0.5);
  double _ringRadius(Size s) => math.min(s.height * 0.27, s.width * 0.11);

  @override
  bool shouldRepaint(covariant CustomPainter oldDelegate) => false;
}
