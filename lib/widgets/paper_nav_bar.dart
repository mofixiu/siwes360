import 'package:flutter/material.dart';
import 'package:siwes360/theme/tokens.dart';

class NavItem {
  const NavItem(this.label, this.icon, this.selectedIcon, this.builder);

  final String label;
  final IconData icon;
  final IconData selectedIcon;
  final WidgetBuilder builder;
}

/// The bottom bar for every role: a rule on top, one icon set (Material outlined),
/// and a short ink bar over the current tab. Tabs replace each other without animation.
class PaperNavBar extends StatelessWidget {
  const PaperNavBar({super.key, required this.items, required this.currentIndex});

  final List<NavItem> items;
  final int currentIndex;

  void _go(BuildContext context, int index) {
    if (index == currentIndex) return;
    Navigator.of(context).pushReplacement(
      PageRouteBuilder(
        pageBuilder: (context, _, _) => OnPaper(child: items[index].builder(context)),
        transitionDuration: Duration.zero,
        reverseTransitionDuration: Duration.zero,
      ),
    );
  }

  @override
  Widget build(BuildContext context) {
    return Container(
      decoration: const BoxDecoration(
        border: Border(top: BorderSide(color: Palette.rule)),
      ),
      child: SafeArea(
        top: false,
        child: SizedBox(
          height: 58,
          child: Row(
            children: [
              for (var i = 0; i < items.length; i++)
                Expanded(
                  child: Semantics(
                    selected: i == currentIndex,
                    button: true,
                    label: items[i].label,
                    child: InkWell(
                      onTap: () => _go(context, i),
                      child: Column(
                        children: [
                          Container(
                            height: 2,
                            width: 28,
                            color: i == currentIndex ? Palette.ink : Colors.transparent,
                          ),
                          const SizedBox(height: 7),
                          Icon(
                            i == currentIndex ? items[i].selectedIcon : items[i].icon,
                            size: 22,
                            color: i == currentIndex ? Palette.ink : Palette.inkFaint,
                          ),
                          const SizedBox(height: 3),
                          Text(
                            items[i].label,
                            style: Txt.sans(
                              Txt.label,
                              weight: i == currentIndex ? FontWeight.w600 : FontWeight.w500,
                              color: i == currentIndex ? Palette.ink : Palette.inkFaint,
                            ),
                          ),
                        ],
                      ),
                    ),
                  ),
                ),
            ],
          ),
        ),
      ),
    );
  }
}
