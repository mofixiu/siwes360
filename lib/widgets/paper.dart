import 'dart:io';

import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';

/// Shared pieces of the paper-logbook look: rules, rows, labels, stamps and
/// buttons. Screens build from these instead of cards and shadows.

/// A hairline rule across the page.
class Rule extends StatelessWidget {
  const Rule({super.key, this.color = Palette.rule, this.indent = 0, this.thickness = 1});

  const Rule.strong({super.key, this.indent = 0, this.thickness = 1}) : color = Palette.ruleStrong;

  final Color color;
  final double indent;
  final double thickness;

  @override
  Widget build(BuildContext context) =>
      Container(margin: EdgeInsets.only(left: indent), height: thickness, color: color);
}

/// Small uppercase heading for a group of rows, with an optional action.
class SectionLabel extends StatelessWidget {
  const SectionLabel(this.text, {super.key, this.trailing, this.padding});

  final String text;
  final Widget? trailing;
  final EdgeInsetsGeometry? padding;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: padding ?? const EdgeInsets.fromLTRB(Space.page, Space.xl, Space.page, Space.sm),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.end,
        children: [
          Expanded(child: Text(text.toUpperCase(), style: Txt.labelStyle)),
          ?trailing,
        ],
      ),
    );
  }
}

/// A navy text link used next to section labels ("See all").
class InlineLink extends StatelessWidget {
  const InlineLink(this.text, {super.key, required this.onTap});

  final String text;
  final VoidCallback onTap;

  @override
  Widget build(BuildContext context) {
    return InkWell(
      onTap: onTap,
      child: Padding(
        padding: const EdgeInsets.symmetric(vertical: 2),
        child: Text(text, style: Txt.sans(Txt.small, weight: FontWeight.w600, color: Palette.navy)),
      ),
    );
  }
}

/// One line of a ruled list: content with a rule under it.
class LedgerRow extends StatelessWidget {
  const LedgerRow({
    super.key,
    required this.child,
    this.onTap,
    this.leading,
    this.trailing,
    this.padding = const EdgeInsets.fromLTRB(Space.page, 14, Space.page, 14),
    this.showChevron,
  });

  final Widget child;
  final VoidCallback? onTap;
  final Widget? leading;
  final Widget? trailing;
  final EdgeInsetsGeometry padding;
  final bool? showChevron;

  @override
  Widget build(BuildContext context) {
    final chevron = showChevron ?? onTap != null;
    return InkWell(
      onTap: onTap,
      child: Container(
        decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
        child: Padding(
          padding: padding,
          child: Row(
            children: [
              if (leading != null) ...[leading!, const SizedBox(width: Space.md)],
              Expanded(child: child),
              if (trailing != null) ...[const SizedBox(width: Space.md), trailing!],
              if (chevron) ...[
                const SizedBox(width: Space.sm),
                const Icon(Icons.chevron_right, size: 20, color: Palette.inkFaint),
              ],
            ],
          ),
        ),
      ),
    );
  }
}

/// A rule across the top of a list, so the first row is ruled above and below.
class LedgerTop extends StatelessWidget {
  const LedgerTop({super.key});

  @override
  Widget build(BuildContext context) => const Rule();
}

/// Screen title in the page, not in an app bar: "Logbook", with a line under it.
class PageHeader extends StatelessWidget {
  const PageHeader({super.key, required this.title, this.subtitle, this.actions = const [], this.leading});

  final String title;
  final Widget? subtitle;
  final List<Widget> actions;
  final Widget? leading;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.sm, 0),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          if (leading != null) ...[leading!, const SizedBox(width: Space.md)],
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(title, style: Txt.displayStyle),
                if (subtitle != null) ...[const SizedBox(height: Space.xs), subtitle!],
              ],
            ),
          ),
          ...actions,
        ],
      ),
    );
  }
}

/// A short labelled figure for a line of stats: "4 students".
class Figure {
  const Figure(this.value, this.label, {this.color = Palette.ink});

  final String value;
  final String label;
  final Color color;
}

/// Stats on one line, separated by thin vertical rules: 4 students | 9 to review | 2 to sign.
class FigureLine extends StatelessWidget {
  const FigureLine(this.figures, {super.key});

  final List<Figure> figures;

  @override
  Widget build(BuildContext context) {
    final children = <Widget>[];
    for (var i = 0; i < figures.length; i++) {
      final f = figures[i];
      if (i > 0) {
        children.add(Container(width: 1, height: 32, color: Palette.rule, margin: const EdgeInsets.symmetric(horizontal: Space.md)));
      }
      children.add(
        Flexible(
          child: Column(
            crossAxisAlignment: CrossAxisAlignment.start,
            children: [
              Text(f.value, style: Txt.mono(Txt.title, weight: FontWeight.w500, color: f.color)),
              Text(f.label, style: Txt.smallStyle, maxLines: 1, overflow: TextOverflow.ellipsis),
            ],
          ),
        ),
      );
    }
    return Row(crossAxisAlignment: CrossAxisAlignment.center, children: children);
  }
}

/// Review status of an entry, as the API names it.
enum EntryStatus {
  pending('PENDING', Palette.ochre),
  approved('APPROVED', Palette.olive),
  rejected('RETURNED', Palette.brick);

  const EntryStatus(this.label, this.color);

  final String label;
  final Color color;

  static EntryStatus of(dynamic value) {
    switch (value?.toString().toLowerCase()) {
      case 'approved':
        return EntryStatus.approved;
      case 'rejected':
        return EntryStatus.rejected;
      default:
        return EntryStatus.pending;
    }
  }
}

/// A small office stamp: uppercase status in a thin outlined box, with the
/// reviewer's initials once reviewed. "APPROVED · N.O."
class Stamp extends StatelessWidget {
  const Stamp(this.status, {super.key, this.initials});

  final EntryStatus status;
  final String? initials;

  @override
  Widget build(BuildContext context) {
    final showInitials = status != EntryStatus.pending && (initials ?? '').isNotEmpty;
    return StampBox(
      color: status.color,
      text: showInitials ? '${status.label} · $initials' : status.label,
    );
  }
}

/// The outlined box a stamp is printed in. Also used for other short marks.
class StampBox extends StatelessWidget {
  const StampBox({super.key, required this.color, required this.text, this.weight = 1});

  final Color color;
  final String text;
  final double weight;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(horizontal: 6, vertical: 3),
      decoration: BoxDecoration(
        border: Border.all(color: color, width: weight),
        borderRadius: BorderRadius.circular(Radii.stamp),
      ),
      child: Text(
        text,
        style: Txt.sans(Txt.label, weight: FontWeight.w600, color: color).copyWith(letterSpacing: 0.9, height: 1.2),
      ),
    );
  }
}

/// The supervisor's weekly signature: a heavier stamp with the week, initials
/// and date. When the week is not signed, an empty dashed box.
class SignOffStamp extends StatelessWidget {
  const SignOffStamp({super.key, required this.week, this.signedBy, this.signedOn, this.compact = false});

  final int week;
  final String? signedBy; // full name
  final DateTime? signedOn;
  final bool compact;

  bool get signed => signedBy != null;

  @override
  Widget build(BuildContext context) {
    if (!signed) {
      return CustomPaint(
        painter: _DashedBoxPainter(color: Palette.ruleStrong),
        child: Padding(
          padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 3 : 6),
          child: Text(
            compact ? 'NOT SIGNED' : 'WEEK $week · NOT SIGNED',
            style: Txt.sans(Txt.label, weight: FontWeight.w600, color: Palette.inkFaint).copyWith(letterSpacing: 0.9),
          ),
        ),
      );
    }
    final initials = _initials(signedBy!);
    return Container(
      padding: EdgeInsets.symmetric(horizontal: 8, vertical: compact ? 3 : 6),
      decoration: BoxDecoration(
        border: Border.all(color: Palette.olive, width: 2),
        borderRadius: BorderRadius.circular(Radii.stamp),
      ),
      child: compact
          ? Text(
              'SIGNED · $initials',
              style: Txt.sans(Txt.label, weight: FontWeight.w700, color: Palette.olive).copyWith(letterSpacing: 0.9),
            )
          : Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              mainAxisSize: MainAxisSize.min,
              children: [
                Text(
                  'WEEK $week SIGNED OFF',
                  style: Txt.sans(Txt.label, weight: FontWeight.w700, color: Palette.olive).copyWith(letterSpacing: 0.9),
                ),
                const SizedBox(height: 2),
                Text(
                  [initials, if (signedOn != null) _date(signedOn!)].join(' · '),
                  style: Txt.mono(Txt.label, weight: FontWeight.w500, color: Palette.olive),
                ),
              ],
            ),
    );
  }

  static String _initials(String name) {
    final parts = name.trim().split(RegExp(r'\s+'));
    if (parts.length == 1) return '${parts.first[0]}.';
    return '${parts.first[0]}.${parts.last[0]}.';
  }

  static String _date(DateTime d) {
    const months = ['JAN', 'FEB', 'MAR', 'APR', 'MAY', 'JUN', 'JUL', 'AUG', 'SEP', 'OCT', 'NOV', 'DEC'];
    return '${d.day} ${months[d.month - 1]}';
  }
}

class _DashedBoxPainter extends CustomPainter {
  _DashedBoxPainter({required this.color});

  final Color color;

  @override
  void paint(Canvas canvas, Size size) {
    final paint = Paint()
      ..color = color
      ..strokeWidth = 1
      ..style = PaintingStyle.stroke;
    const dash = 4.0, gap = 3.0;
    void line(Offset a, Offset b) {
      final length = (b - a).distance;
      final dir = (b - a) / length;
      for (double d = 0; d < length; d += dash + gap) {
        canvas.drawLine(a + dir * d, a + dir * (d + dash).clamp(0, length), paint);
      }
    }

    final r = Offset.zero & size;
    line(r.topLeft, r.topRight);
    line(r.topRight, r.bottomRight);
    line(r.bottomRight, r.bottomLeft);
    line(r.bottomLeft, r.topLeft);
  }

  @override
  bool shouldRepaint(_DashedBoxPainter old) => old.color != color;
}

/// Initials in a ruled circle, or the person's photo if they set one on this device.
class Monogram extends StatelessWidget {
  const Monogram({super.key, required this.name, this.size = 40, this.photoPath});

  final String? name;
  final double size;
  final String? photoPath;

  @override
  Widget build(BuildContext context) {
    final parts = (name ?? '').trim().split(RegExp(r'\s+')).where((p) => p.isNotEmpty).toList();
    final letters = parts.isEmpty
        ? '?'
        : (parts.length == 1 ? parts.first[0] : '${parts.first[0]}${parts.last[0]}').toUpperCase();
    final hasPhoto = photoPath != null && File(photoPath!).existsSync();
    return Container(
      width: size,
      height: size,
      decoration: BoxDecoration(
        shape: BoxShape.circle,
        color: Palette.sheet,
        border: Border.all(color: Palette.ruleStrong),
        image: hasPhoto ? DecorationImage(image: FileImage(File(photoPath!)), fit: BoxFit.cover) : null,
      ),
      alignment: Alignment.center,
      child: hasPhoto
          ? null
          : Text(letters, style: Txt.sans(size * 0.34, weight: FontWeight.w600, color: Palette.inkSoft)),
    );
  }
}

/// "Day 18 of 180" with a thin bar.
class DayProgress extends StatelessWidget {
  const DayProgress({super.key, required this.day, required this.of, this.trailing});

  final int day;
  final int of;
  final String? trailing;

  @override
  Widget build(BuildContext context) {
    final fraction = of == 0 ? 0.0 : (day / of).clamp(0.0, 1.0);
    return Column(
      crossAxisAlignment: CrossAxisAlignment.start,
      children: [
        Row(
          children: [
            Text('Day $day of $of', style: Txt.mono(Txt.small, weight: FontWeight.w500)),
            const Spacer(),
            if (trailing != null) Text(trailing!, style: Txt.mono(Txt.small, color: Palette.inkSoft)),
          ],
        ),
        const SizedBox(height: Space.sm),
        LayoutBuilder(
          builder: (context, c) => Stack(
            children: [
              Container(height: 3, color: Palette.rule),
              Container(height: 3, width: c.maxWidth * fraction, color: Palette.ink),
            ],
          ),
        ),
      ],
    );
  }
}

/// The main action on a screen. Navy, full width.
class PrimaryButton extends StatelessWidget {
  const PrimaryButton({super.key, required this.label, required this.onPressed, this.busy = false, this.icon});

  final String label;
  final VoidCallback? onPressed;
  final bool busy;
  final IconData? icon;

  @override
  Widget build(BuildContext context) {
    return FilledButton(
      onPressed: busy ? null : onPressed,
      child: busy
          ? const SizedBox(width: 20, height: 20, child: CircularProgressIndicator(strokeWidth: 2, color: Palette.inkSoft))
          : Row(
              mainAxisSize: MainAxisSize.min,
              children: [
                if (icon != null) ...[Icon(icon, size: 20), const SizedBox(width: Space.sm)],
                Text(label),
              ],
            ),
    );
  }
}

/// A navy outlined button for the second action.
class SecondaryButton extends StatelessWidget {
  const SecondaryButton({super.key, required this.label, required this.onPressed, this.color = Palette.navy, this.busy = false});

  final String label;
  final VoidCallback? onPressed;
  final Color color;
  final bool busy;

  @override
  Widget build(BuildContext context) {
    return OutlinedButton(
      onPressed: busy ? null : onPressed,
      style: OutlinedButton.styleFrom(foregroundColor: color, side: BorderSide(color: color)),
      child: busy
          ? SizedBox(width: 18, height: 18, child: CircularProgressIndicator(strokeWidth: 2, color: color))
          : Text(label),
    );
  }
}

/// Pinned to the bottom of a screen, above the home indicator, with a rule above.
class BottomAction extends StatelessWidget {
  const BottomAction({super.key, required this.child});

  final Widget child;

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Palette.rule)),
      ),
      padding: const EdgeInsets.fromLTRB(Space.page, Space.md, Space.page, Space.md),
      child: SafeArea(top: false, minimum: const EdgeInsets.only(bottom: Space.sm), child: child),
    );
  }
}

/// A plain sentence where a list would be, e.g. "Nothing waiting for review."
class EmptyNote extends StatelessWidget {
  const EmptyNote(this.text, {super.key, this.detail});

  final String text;
  final String? detail;

  @override
  Widget build(BuildContext context) {
    return Padding(
      padding: const EdgeInsets.fromLTRB(Space.page, Space.lg, Space.page, Space.lg),
      child: Column(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          Text(text, style: Txt.sans(Txt.body, weight: FontWeight.w500)),
          if (detail != null) ...[const SizedBox(height: Space.xs), Text(detail!, style: Txt.smallStyle)],
        ],
      ),
    );
  }
}

class LoadingView extends StatelessWidget {
  const LoadingView({super.key});

  @override
  Widget build(BuildContext context) => const Center(
        child: SizedBox(width: 22, height: 22, child: CircularProgressIndicator(strokeWidth: 2)),
      );
}

class ErrorView extends StatelessWidget {
  const ErrorView({super.key, required this.message, required this.onRetry});

  final String message;
  final VoidCallback onRetry;

  @override
  Widget build(BuildContext context) {
    return Center(
      child: Padding(
        padding: const EdgeInsets.all(Space.xxl),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            Text("Couldn't load this page", style: Txt.titleStyle, textAlign: TextAlign.center),
            const SizedBox(height: Space.sm),
            Text(message, style: Txt.smallStyle, textAlign: TextAlign.center),
            const SizedBox(height: Space.lg),
            TextButton(onPressed: onRetry, child: const Text('Try again')),
          ],
        ),
      ),
    );
  }
}

/// A read-only field, as on the official record: label, value and a lock.
class LockedField extends StatelessWidget {
  const LockedField({super.key, required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
      child: Row(
        children: [
          Expanded(
            child: Column(
              crossAxisAlignment: CrossAxisAlignment.start,
              children: [
                Text(label.toUpperCase(), style: Txt.labelStyle),
                const SizedBox(height: 4),
                Text(
                  value.isEmpty ? '—' : value,
                  style: mono ? Txt.mono(Txt.body, color: Palette.inkSoft) : Txt.sans(Txt.body, color: Palette.inkSoft),
                ),
              ],
            ),
          ),
          const Icon(Icons.lock_outline, size: 16, color: Palette.inkFaint),
        ],
      ),
    );
  }
}

/// A label and value pair on one ruled line, for read-only details.
class DetailLine extends StatelessWidget {
  const DetailLine({super.key, required this.label, required this.value, this.mono = false});

  final String label;
  final String value;
  final bool mono;

  @override
  Widget build(BuildContext context) {
    return Container(
      padding: const EdgeInsets.symmetric(vertical: 12),
      decoration: const BoxDecoration(border: Border(bottom: BorderSide(color: Palette.rule))),
      child: Row(
        crossAxisAlignment: CrossAxisAlignment.start,
        children: [
          SizedBox(width: 96, child: Text(label, style: Txt.smallStyle)),
          Expanded(
            child: Text(
              value.isEmpty ? '—' : value,
              style: mono ? Txt.mono(Txt.small, weight: FontWeight.w500) : Txt.sans(Txt.small, weight: FontWeight.w500, color: Palette.ink),
            ),
          ),
        ],
      ),
    );
  }
}

/// Opens a paper bottom sheet with a short handle rule.
Future<T?> showPaperSheet<T>(BuildContext context, {required WidgetBuilder builder}) {
  return showModalBottomSheet<T>(
    context: context,
    isScrollControlled: true,
    useSafeArea: true,
    backgroundColor: Colors.transparent,
    // The keyboard inset is applied here, around the whole sheet, so the
    // sheet's content can scroll instead of being squeezed below zero height.
    builder: (context) => DecoratedBox(
      decoration: paperTexture.copyWith(borderRadius: const BorderRadius.vertical(top: Radius.circular(Radii.control))),
      child: Padding(
        padding: EdgeInsets.only(bottom: MediaQuery.viewInsetsOf(context).bottom),
        child: Column(
          mainAxisSize: MainAxisSize.min,
          children: [
            const SizedBox(height: Space.sm),
            Container(width: 36, height: 3, color: Palette.ruleStrong),
            Flexible(child: builder(context)),
          ],
        ),
      ),
    ),
  );
}

/// Snack bar messages in one place.
void showNote(BuildContext context, String message, {bool error = false}) {
  ScaffoldMessenger.of(context)
    ..hideCurrentSnackBar()
    ..showSnackBar(
      SnackBar(
        content: Text(message),
        backgroundColor: error ? Palette.brick : Palette.ink,
      ),
    );
}

/// Ask before doing something that can't be undone. Returns true on confirm.
Future<bool> confirm(
  BuildContext context, {
  required String title,
  required String message,
  required String action,
  bool destructive = false,
}) async {
  final result = await showDialog<bool>(
    context: context,
    builder: (context) => AlertDialog(
      title: Text(title),
      content: Text(message, style: Txt.sans(Txt.body, color: Palette.inkSoft)),
      actions: [
        TextButton(
          onPressed: () => Navigator.pop(context, false),
          style: TextButton.styleFrom(foregroundColor: Palette.inkSoft),
          child: const Text('Cancel'),
        ),
        TextButton(
          onPressed: () => Navigator.pop(context, true),
          style: TextButton.styleFrom(foregroundColor: destructive ? Palette.brick : Palette.navy),
          child: Text(action),
        ),
      ],
    ),
  );
  return result ?? false;
}
