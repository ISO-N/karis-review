import 'package:flutter/material.dart';
import 'package:flutter/semantics.dart';

import '../../app/theme.dart';

class KarisHeading extends StatelessWidget {
  final Widget child;

  const KarisHeading({super.key, required this.child});

  @override
  Widget build(BuildContext context) {
    return Semantics(header: true, child: child);
  }
}

class KarisInteractive extends StatelessWidget {
  final Widget child;
  final String? label;
  final bool button;
  final bool selected;

  const KarisInteractive({
    super.key,
    required this.child,
    this.label,
    this.button = true,
    this.selected = false,
  });

  @override
  Widget build(BuildContext context) {
    return Semantics(
      button: button,
      selected: selected,
      label: label,
      child: child,
    );
  }
}

void announceMessage(BuildContext context, String message) {
  SemanticsService.sendAnnouncement(
    View.of(context),
    message,
    Directionality.of(context),
  );
}

bool shouldAutoFocus(BuildContext context) {
  return MediaQuery.sizeOf(context).shortestSide >= 600;
}

class KarisSkipLink extends StatefulWidget {
  final FocusNode target;

  const KarisSkipLink({super.key, required this.target});

  @override
  State<KarisSkipLink> createState() => _KarisSkipLinkState();
}

class _KarisSkipLinkState extends State<KarisSkipLink> {
  bool _visible = false;

  @override
  Widget build(BuildContext context) {
    final colors = context.karisColors;
    return Focus(
      onFocusChange: (focused) {
        if (_visible != focused) setState(() => _visible = focused);
      },
      child: IgnorePointer(
        ignoring: !_visible,
        child: Opacity(
          opacity: _visible ? 1 : 0,
          child: ExcludeSemantics(
            excluding: !_visible,
            child: TextButton(
              onPressed: () => widget.target.requestFocus(),
              style: TextButton.styleFrom(
                backgroundColor: colors.surface,
                foregroundColor: colors.ink,
                side: BorderSide(color: colors.jade),
              ),
              child: const Text('跳至主内容'),
            ),
          ),
        ),
      ),
    );
  }
}
