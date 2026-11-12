import 'package:flutter/material.dart';
import 'package:flutter/services.dart';
import 'package:google_fonts/google_fonts.dart';
import 'package:siwes360/theme/tokens.dart';

/// The app's only theme. Handmade paper: no elevation, no shadows, hairline rules.
ThemeData buildAppTheme() {
  final text = GoogleFonts.montserratTextTheme().apply(bodyColor: Palette.ink, displayColor: Palette.ink);
  const controlShape = RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.control)));
  OutlineInputBorder border(Color color, [double width = 1]) => OutlineInputBorder(
        borderRadius: BorderRadius.circular(Radii.control),
        borderSide: BorderSide(color: color, width: width),
      );

  return ThemeData(
    useMaterial3: true,
    brightness: Brightness.light,
    // Pages are drawn on the paper texture by their route (see [OnPaper]).
    scaffoldBackgroundColor: Colors.transparent,
    canvasColor: Palette.paper,
    textTheme: text,
    colorScheme: const ColorScheme.light(
      primary: Palette.navy,
      onPrimary: Colors.white,
      secondary: Palette.ink,
      onSecondary: Palette.paper,
      surface: Palette.paper,
      onSurface: Palette.ink,
      error: Palette.brick,
      onError: Colors.white,
      outline: Palette.ruleStrong,
      outlineVariant: Palette.rule,
      surfaceTint: Colors.transparent,
    ),
    splashFactory: NoSplash.splashFactory,
    highlightColor: Palette.rule.withValues(alpha: 0.5),
    dividerTheme: const DividerThemeData(color: Palette.rule, thickness: 1, space: 1),
    iconTheme: const IconThemeData(color: Palette.inkSoft, size: 22),
    appBarTheme: AppBarTheme(
      backgroundColor: Colors.transparent,
      surfaceTintColor: Colors.transparent,
      // A see-through bar would otherwise get white status bar icons.
      systemOverlayStyle: SystemUiOverlayStyle.dark,
      foregroundColor: Palette.ink,
      elevation: 0,
      scrolledUnderElevation: 0,
      centerTitle: false,
      titleSpacing: 0,
      titleTextStyle: Txt.titleStyle,
      shape: const Border(bottom: BorderSide(color: Palette.rule)),
    ),
    inputDecorationTheme: InputDecorationTheme(
      filled: true,
      fillColor: Palette.sheet,
      isDense: true,
      contentPadding: const EdgeInsets.symmetric(horizontal: 14, vertical: 14),
      hintStyle: Txt.sans(Txt.body, color: Palette.inkFaint),
      labelStyle: Txt.sans(Txt.small, color: Palette.inkSoft),
      floatingLabelStyle: Txt.sans(Txt.small, color: Palette.ink),
      errorStyle: Txt.sans(Txt.small, color: Palette.brick),
      prefixIconColor: Palette.inkFaint,
      suffixIconColor: Palette.inkFaint,
      border: border(Palette.ruleStrong),
      enabledBorder: border(Palette.ruleStrong),
      focusedBorder: border(Palette.ink, 1.4),
      errorBorder: border(Palette.brick),
      focusedErrorBorder: border(Palette.brick, 1.4),
      disabledBorder: border(Palette.rule),
    ),
    filledButtonTheme: FilledButtonThemeData(
      style: FilledButton.styleFrom(
        backgroundColor: Palette.navy,
        foregroundColor: Colors.white,
        disabledBackgroundColor: Palette.rule,
        disabledForegroundColor: Palette.inkFaint,
        minimumSize: const Size.fromHeight(52),
        shape: controlShape,
        textStyle: Txt.sans(Txt.body, weight: FontWeight.w600),
        elevation: 0,
      ),
    ),
    outlinedButtonTheme: OutlinedButtonThemeData(
      style: OutlinedButton.styleFrom(
        foregroundColor: Palette.navy,
        side: const BorderSide(color: Palette.navy),
        minimumSize: const Size.fromHeight(48),
        shape: controlShape,
        textStyle: Txt.sans(Txt.body, weight: FontWeight.w600),
      ),
    ),
    textButtonTheme: TextButtonThemeData(
      style: TextButton.styleFrom(
        foregroundColor: Palette.navy,
        textStyle: Txt.sans(Txt.body, weight: FontWeight.w600),
        shape: controlShape,
      ),
    ),
    progressIndicatorTheme: const ProgressIndicatorThemeData(
      color: Palette.ink,
      linearTrackColor: Palette.rule,
      circularTrackColor: Colors.transparent,
    ),
    switchTheme: SwitchThemeData(
      thumbColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Colors.white : Palette.inkFaint),
      trackColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Palette.navy : Palette.sheet),
      trackOutlineColor: WidgetStateProperty.resolveWith((s) => s.contains(WidgetState.selected) ? Palette.navy : Palette.ruleStrong),
    ),
    snackBarTheme: SnackBarThemeData(
      backgroundColor: Palette.ink,
      contentTextStyle: Txt.sans(Txt.small, color: Palette.paper),
      behavior: SnackBarBehavior.floating,
      elevation: 0,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.control))),
    ),
    dialogTheme: DialogThemeData(
      backgroundColor: Palette.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      shape: const RoundedRectangleBorder(
        borderRadius: BorderRadius.all(Radius.circular(Radii.control)),
        side: BorderSide(color: Palette.ruleStrong),
      ),
      titleTextStyle: Txt.titleStyle,
      contentTextStyle: Txt.bodyStyle,
    ),
    bottomSheetTheme: const BottomSheetThemeData(
      backgroundColor: Palette.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      modalElevation: 0,
      shape: RoundedRectangleBorder(borderRadius: BorderRadius.vertical(top: Radius.circular(Radii.control))),
    ),
    datePickerTheme: DatePickerThemeData(
      backgroundColor: Palette.paper,
      surfaceTintColor: Colors.transparent,
      elevation: 0,
      headerBackgroundColor: Palette.paper,
      headerForegroundColor: Palette.ink,
      shape: const RoundedRectangleBorder(borderRadius: BorderRadius.all(Radius.circular(Radii.control))),
      dayStyle: Txt.mono(Txt.small),
      yearStyle: Txt.mono(Txt.small),
      todayBorder: const BorderSide(color: Palette.ink),
    ),
    pageTransitionsTheme: const PageTransitionsTheme(
      builders: {
        TargetPlatform.iOS: _PaperCupertinoTransitions(),
        TargetPlatform.android: _PaperFadeForwardsTransitions(),
      },
    ),
  );
}

class _PaperCupertinoTransitions extends CupertinoPageTransitionsBuilder {
  const _PaperCupertinoTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T> route, BuildContext context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      super.buildTransitions(route, context, animation, secondaryAnimation, OnPaper(child: child));
}

class _PaperFadeForwardsTransitions extends FadeForwardsPageTransitionsBuilder {
  const _PaperFadeForwardsTransitions();

  @override
  Widget buildTransitions<T>(PageRoute<T>? route, BuildContext? context, Animation<double> animation,
          Animation<double> secondaryAnimation, Widget child) =>
      super.buildTransitions(route, context, animation, secondaryAnimation, OnPaper(child: child));
}
