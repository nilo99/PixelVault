import 'dart:math' as math;

import 'package:flutter/widgets.dart';

/// How much room the UI actually has, in three coarse bands.
///
/// The app is used on handhelds as well as phones — the AYN Thor in
/// particular is held in portrait and has a second, much smaller display —
/// so "portrait phone" is not a safe assumption. Every dimension in the
/// design system was a hardcoded logical pixel value tuned for a ~390pt
/// wide screen, which overflows well before the viewport gets genuinely
/// small.
enum GengarDensity {
  /// A secondary/auxiliary display, or a very short window. Chrome is
  /// stripped back to leave room for content.
  tiny,

  /// A small phone or a handheld's main screen in portrait.
  compact,

  /// A normal phone or larger.
  regular,
}

/// Viewport-derived sizing shared by the whole design system.
///
/// Read it with `GengarMetrics.of(context)`. It is installed once near the
/// root (see `app.dart`) so every screen sees the same values and they
/// change with the window rather than being baked in at build time.
@immutable
class GengarMetrics {
  const GengarMetrics({
    required this.size,
    required this.density,
    required this.scale,
  });

  /// Reference viewport the design system's raw numbers were drawn against.
  static const _referenceWidth = 390.0;
  static const _referenceHeight = 780.0;

  /// Below this the layout is treated as an auxiliary screen.
  static const tinyWidth = 320.0;
  static const tinyHeight = 420.0;

  static const compactWidth = 380.0;
  static const compactHeight = 640.0;

  final Size size;
  final GengarDensity density;

  /// Multiplier applied to type and spacing, `0.70`–`1.0`. Driven by
  /// whichever axis is tighter, so a short-but-wide window shrinks too.
  final double scale;

  bool get isTiny => density == GengarDensity.tiny;
  bool get isCompact => density != GengarDensity.regular;

  /// Horizontal page padding. The design uses 20 at reference size; on an
  /// auxiliary screen that is more than 10% of the width spent on margins.
  double get gutter => isTiny ? 10.0 : (20.0 * scale).clamp(12.0, 20.0);

  /// Vertical rhythm unit, for gaps between stacked sections.
  double gap(double atReference) => math.max(2.0, atReference * scale);

  /// Bottom padding that keeps content clear of the floating nav bar.
  double get navBarInset => isTiny ? 68.0 : 96.0;

  static GengarMetrics fromSize(Size size) {
    final widthFactor = size.width / _referenceWidth;
    final heightFactor = size.height / _referenceHeight;
    // The tighter axis wins: a wide but very short window is just as
    // cramped as a narrow one, and the chrome has to give way either way.
    final scale = math.min(widthFactor, heightFactor).clamp(0.70, 1.0);

    final GengarDensity density;
    if (size.width < tinyWidth || size.height < tinyHeight) {
      density = GengarDensity.tiny;
    } else if (size.width < compactWidth || size.height < compactHeight) {
      density = GengarDensity.compact;
    } else {
      density = GengarDensity.regular;
    }

    return GengarMetrics(size: size, density: density, scale: scale);
  }

  static GengarMetrics of(BuildContext context) {
    final inherited = context.dependOnInheritedWidgetOfExactType<_GengarMetricsScope>();
    if (inherited != null) return inherited.metrics;
    // A screen rendered outside the scope (a bare widget test, a dialog
    // pushed on a detached navigator) still gets sensible values rather
    // than throwing.
    return GengarMetrics.fromSize(MediaQuery.sizeOf(context));
  }

  @override
  bool operator ==(Object other) =>
      other is GengarMetrics &&
      other.size == size &&
      other.density == density &&
      other.scale == scale;

  @override
  int get hashCode => Object.hash(size, density, scale);
}

/// Installs [GengarMetrics] for the subtree and clamps text scaling.
///
/// The clamp matters as much as the metrics: a user with the system font
/// turned up to 200% on a 320pt-wide screen overflows every card in the
/// app. Their preference is still respected, just bounded, and then folded
/// together with the viewport scale so type shrinks on small screens
/// without every call site having to know about it.
class GengarMetricsScope extends StatelessWidget {
  const GengarMetricsScope({super.key, required this.child});

  final Widget child;

  /// Accessibility range honoured before the viewport scale is applied.
  static const _minUserTextScale = 0.85;
  static const _maxUserTextScale = 1.30;

  @override
  Widget build(BuildContext context) {
    final mq = MediaQuery.of(context);
    final metrics = GengarMetrics.fromSize(mq.size);

    // `TextScaler` has no factor getter, so probe it with a known size.
    final userScale = (mq.textScaler.scale(100) / 100).clamp(
      _minUserTextScale,
      _maxUserTextScale,
    );

    return _GengarMetricsScope(
      metrics: metrics,
      child: MediaQuery(
        data: mq.copyWith(
          textScaler: TextScaler.linear(userScale * metrics.scale),
        ),
        child: child,
      ),
    );
  }
}

class _GengarMetricsScope extends InheritedWidget {
  const _GengarMetricsScope({required this.metrics, required super.child});

  final GengarMetrics metrics;

  @override
  bool updateShouldNotify(_GengarMetricsScope oldWidget) => oldWidget.metrics != metrics;
}
