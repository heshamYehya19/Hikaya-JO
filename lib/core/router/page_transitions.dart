import 'package:flutter/material.dart';
import 'package:go_router/go_router.dart';

/// One shared transition used for every in-app screen change — a gentle
/// fade combined with a short upward slide, rather than each screen
/// picking (or forgetting to pick) its own. Consistency here is what
/// actually reads as "smooth" to a user, more than any single transition's
/// exact curve.
const _duration = Duration(milliseconds: 280);
const _reverseDuration = Duration(milliseconds: 220);
const _slideDistance = 0.04; // fraction of screen height — subtle, not a full slide-up sheet

Widget _buildTransition(Animation<double> animation, Animation<double> secondaryAnimation, Widget child) {
  final curved = CurvedAnimation(parent: animation, curve: Curves.easeOutCubic, reverseCurve: Curves.easeInCubic);
  return FadeTransition(
    opacity: curved,
    child: SlideTransition(
      position: Tween<Offset>(begin: const Offset(0, _slideDistance), end: Offset.zero).animate(curved),
      child: child,
    ),
  );
}

/// Drop-in replacement for `MaterialPageRoute` — use as
/// `Navigator.of(context).push(smoothPageRoute(const SomeScreen()))`.
PageRouteBuilder<T> smoothPageRoute<T>(Widget child, {RouteSettings? settings}) {
  return PageRouteBuilder<T>(
    settings: settings,
    transitionDuration: _duration,
    reverseTransitionDuration: _reverseDuration,
    pageBuilder: (context, animation, secondaryAnimation) => child,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _buildTransition(animation, secondaryAnimation, child),
  );
}

/// Same transition for go_router's top-level routes (splash → onboarding →
/// auth → home), so the very first screens the app shows don't feel
/// abruptly different from everything pushed after them.
CustomTransitionPage<void> smoothPage({required LocalKey key, required Widget child}) {
  return CustomTransitionPage<void>(
    key: key,
    child: child,
    transitionDuration: _duration,
    reverseTransitionDuration: _reverseDuration,
    transitionsBuilder: (context, animation, secondaryAnimation, child) =>
        _buildTransition(animation, secondaryAnimation, child),
  );
}
