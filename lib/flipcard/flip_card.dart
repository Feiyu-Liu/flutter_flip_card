import 'dart:async';
import 'dart:math';

import 'package:flutter/material.dart';

import '../controllers/flip_card_controllers.dart';
import '../modal/flip_side.dart';

/// A component that transitions between two children with a card flip.
class FlipCard extends StatefulWidget {
  const FlipCard({
    super.key,
    this.focusColor,
    this.splashColor,
    this.onTapFlipping = false,
    this.disableSplashEffect = false,
    required this.frontWidget,
    required this.backWidget,
    required this.controller,
    this.axis = FlipAxis.vertical,
    required this.rotateSide,
    this.animationDuration = const Duration(milliseconds: 800),
    this.curve = Curves.linear,
    this.side,
    this.initialSide = FlipCardSide.front,
    this.onFlipCompleted,
  }) : assert(
         side == null || !onTapFlipping,
         'onTapFlipping is only available when side is uncontrolled.',
       );

  /// Controller used to flip the card imperatively.
  final FlipCardController controller;

  /// Front side widget.
  final Widget frontWidget;

  /// Back side widget.
  final Widget backWidget;

  /// Whether tapping toggles an uncontrolled card.
  final bool onTapFlipping;

  /// The flip axis.
  final FlipAxis axis;

  /// The direction in which the card rotates.
  final RotateSide rotateSide;

  /// Duration of a complete front-to-back flip.
  final Duration animationDuration;

  /// Curve used by each transition.
  final Curve curve;

  /// Controlled target side. When null, the controller owns the side.
  final FlipCardSide? side;

  /// Initial side used before any controlled or imperative transition.
  final FlipCardSide initialSide;

  /// Called after an animated or reduced-motion transition settles.
  final ValueChanged<FlipCardSide>? onFlipCompleted;

  /// Whether to disable the InkWell splash effect for tap flipping.
  final bool disableSplashEffect;

  final Color? splashColor;
  final Color? focusColor;

  @override
  FlipCardState createState() => FlipCardState();
}

class FlipCardState extends State<FlipCard>
    with SingleTickerProviderStateMixin {
  late final AnimationController animationController;
  late FlipCardSide _targetSide;
  RotateSide? _rotateSideOverride;
  bool _disableAnimations = false;
  int _transitionGeneration = 0;

  FlipCardSide get targetSide => _targetSide;

  @override
  void initState() {
    super.initState();
    _targetSide = widget.side ?? widget.initialSide;
    animationController = AnimationController(
      duration: widget.animationDuration,
      value: _valueForSide(_targetSide),
      vsync: this,
    );
    widget.controller.state = this;
  }

  @override
  void didChangeDependencies() {
    super.didChangeDependencies();
    final bool disableAnimations =
        MediaQuery.maybeDisableAnimationsOf(context) ?? false;
    if (_disableAnimations == disableAnimations) {
      return;
    }
    _disableAnimations = disableAnimations;
    if (_disableAnimations && animationController.isAnimating) {
      unawaited(showSide(_targetSide, animate: false));
    }
  }

  @override
  void didUpdateWidget(covariant FlipCard oldWidget) {
    super.didUpdateWidget(oldWidget);
    if (oldWidget.controller != widget.controller) {
      if (oldWidget.controller.state == this) {
        oldWidget.controller.state = null;
      }
      widget.controller.state = this;
    }
    if (oldWidget.animationDuration != widget.animationDuration) {
      animationController.duration = widget.animationDuration;
    }
    final FlipCardSide? controlledSide = widget.side;
    if (controlledSide != null && controlledSide != _targetSide) {
      unawaited(showSide(controlledSide));
    }
  }

  @override
  void dispose() {
    if (widget.controller.state == this) {
      widget.controller.state = null;
    }
    animationController.dispose();
    super.dispose();
  }

  /// Toggles an uncontrolled card or the current controlled target.
  Future<void> flipCard({RotateSide? rotateSide}) {
    final FlipCardSide nextSide = _targetSide == FlipCardSide.front
        ? FlipCardSide.back
        : FlipCardSide.front;
    return showSide(nextSide, rotateSide: rotateSide);
  }

  /// Moves the card to [side], preserving continuity if the target changes.
  Future<void> showSide(
    FlipCardSide side, {
    RotateSide? rotateSide,
    bool animate = true,
  }) async {
    final int transitionGeneration = ++_transitionGeneration;
    _targetSide = side;
    _rotateSideOverride = rotateSide;
    final double targetValue = _valueForSide(side);
    final double distance = (animationController.value - targetValue).abs();

    if (distance == 0) {
      _rotateSideOverride = null;
      return;
    }

    if (!animate ||
        _disableAnimations ||
        widget.animationDuration == Duration.zero) {
      animationController.stop();
      animationController.value = targetValue;
      _completeTransition(side, transitionGeneration);
      return;
    }

    final int durationMicros =
        (widget.animationDuration.inMicroseconds * distance).round();
    try {
      await animationController
          .animateTo(
            targetValue,
            duration: Duration(microseconds: durationMicros),
            curve: widget.curve,
          )
          .orCancel;
    } on TickerCanceled {
      return;
    }
    _completeTransition(side, transitionGeneration);
  }

  void _completeTransition(FlipCardSide side, int transitionGeneration) {
    if (!mounted || transitionGeneration != _transitionGeneration) {
      return;
    }
    _rotateSideOverride = null;
    widget.onFlipCompleted?.call(side);
  }

  @override
  Widget build(BuildContext context) {
    return AnimatedBuilder(
      animation: animationController,
      builder: (BuildContext context, Widget? child) {
        final RotateSide rotateSide = _rotateSideOverride ?? widget.rotateSide;
        final double direction =
            rotateSide == RotateSide.top || rotateSide == RotateSide.left
            ? 1
            : -1;
        final double angle = animationController.value * pi * direction;
        final Matrix4 transform = Matrix4.identity()..setEntry(3, 2, 0.001);
        if (widget.axis == FlipAxis.horizontal) {
          transform.rotateX(angle);
        } else {
          transform.rotateY(angle);
        }
        final bool showFront = animationController.value <= 0.5;
        final Matrix4 backTransform = Matrix4.identity();
        if (widget.axis == FlipAxis.horizontal) {
          backTransform.rotateX(pi);
        } else {
          backTransform.rotateY(pi);
        }
        final Widget visibleSide = showFront
            ? widget.frontWidget
            : Transform(
                transform: backTransform,
                alignment: Alignment.center,
                child: widget.backWidget,
              );
        final Widget transformedCard = Transform(
          alignment: Alignment.center,
          transform: transform,
          child: visibleSide,
        );

        if (!widget.onTapFlipping) {
          return transformedCard;
        }
        return InkWell(
          onTap: () => unawaited(flipCard()),
          splashColor: widget.splashColor,
          focusColor: widget.focusColor,
          overlayColor: widget.disableSplashEffect
              ? WidgetStateProperty.all<Color>(Colors.transparent)
              : null,
          child: transformedCard,
        );
      },
    );
  }

  double _valueForSide(FlipCardSide side) {
    return side == FlipCardSide.front ? 0 : 1;
  }
}
