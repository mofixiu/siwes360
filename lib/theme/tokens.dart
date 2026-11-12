import 'package:flutter/material.dart';
import 'package:google_fonts/google_fonts.dart';

/// Every colour, type size, space and corner radius the app uses.
///
/// The look is a filled-in paper logbook: handmade paper, thin rules between rows,
/// statuses as small office stamps, and IBM Plex Mono wherever a value reads like
/// something written into a form (dates, matric numbers, day counts).
class Palette {
  Palette._();

  // Paper and ink. Pages sit on the handmade paper texture ([OnPaper]); [paper]
  // is its average colour, for surfaces that can't show it (dialogs, pickers).
  static const paper = Color(0xFFF7EFDB);
  static const sheet = Color(0xFFFBF7EF); // inputs, the raised strip of a row
  static const ink = Color(0xFF1E2530);
  static const inkSoft = Color(0xFF5A6070);
  static const inkFaint = Color(0xFF8E909A);
  static const rule = Color(0xFFE3D7C6);
  static const ruleStrong = Color(0xFFC8B8A1);

  // Navy is only for things you can press.
  static const navy = Color(0xFF0A3D62);
  static const navyPressed = Color(0xFF072C47);

  // Muted status colours, as in stamp ink.
  static const olive = Color(0xFF5B6A2C); // approved, signed, logging
  static const ochre = Color(0xFFA06A12); // pending, waiting
  static const brick = Color(0xFFA03F2A); // returned, behind, errors
}

/// The handmade paper every page is drawn on, tiled at its own size
/// (about 512 points wide).
const paperTexture = BoxDecoration(
  color: Palette.paper,
  image: DecorationImage(
    image: AssetImage('assets/images/handmade-paper.jpg'),
    repeat: ImageRepeat.repeat,
    fit: BoxFit.none,
    scale: 3,
    alignment: Alignment.topLeft,
  ),
);

/// Puts a page on the paper texture. Every route wraps its page in this, so a
/// page sliding in covers the one under it instead of showing it through.
class OnPaper extends StatelessWidget {
  const OnPaper({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) => DecoratedBox(decoration: paperTexture, child: child);
}

/// Five type sizes (Txt, not Type, to keep clear of dart:core's Type). Montserrat for words, IBM Plex Mono for form values.
class Txt {
  Txt._();

  static const double display = 26;
  static const double title = 18;
  static const double body = 15;
  static const double small = 13;
  static const double label = 11;

  static TextStyle sans(double size, {FontWeight weight = FontWeight.w400, Color color = Palette.ink, double? height}) =>
      GoogleFonts.montserrat(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle mono(double size, {FontWeight weight = FontWeight.w400, Color color = Palette.ink, double? height}) =>
      GoogleFonts.ibmPlexMono(fontSize: size, fontWeight: weight, color: color, height: height);

  static TextStyle get displayStyle => sans(display, weight: FontWeight.w600, height: 1.2);
  static TextStyle get titleStyle => sans(title, weight: FontWeight.w600, height: 1.3);
  static TextStyle get bodyStyle => sans(body, height: 1.45);
  static TextStyle get smallStyle => sans(small, color: Palette.inkSoft, height: 1.4);

  /// Small uppercase heading above a group of rows.
  static TextStyle get labelStyle =>
      GoogleFonts.montserrat(fontSize: label, fontWeight: FontWeight.w600, color: Palette.inkSoft, letterSpacing: 1.1);
}

class Space {
  Space._();

  static const double xs = 4;
  static const double sm = 8;
  static const double md = 12;
  static const double lg = 16;
  static const double xl = 24;
  static const double xxl = 32;

  /// Left and right page margin.
  static const double page = 20;
}

/// Three corner radii: square rows, small stamps, and controls.
class Radii {
  Radii._();

  static const double none = 0;
  static const double stamp = 2;
  static const double control = 6;
}
