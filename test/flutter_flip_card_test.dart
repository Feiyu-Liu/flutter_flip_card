import 'package:flutter/material.dart';
import 'package:flutter_flip_card/flutter_flip_card.dart';
import 'package:flutter_test/flutter_test.dart';

void main() {
  Future<void> pumpFlipCard(
    WidgetTester tester, {
    required FlipCardController controller,
    Curve? curve,
  }) {
    return tester.pumpWidget(
      MaterialApp(
        home: Scaffold(
          body: Center(
            child: FlipCard(
              controller: controller,
              rotateSide: RotateSide.right,
              animationDuration: const Duration(milliseconds: 800),
              curve: curve ?? Curves.linear,
              frontWidget: const Text('front'),
              backWidget: const Text('back'),
            ),
          ),
        ),
      ),
    );
  }

  testWidgets('FlipCard defaults to a linear curve', (
    WidgetTester tester,
  ) async {
    final controller = FlipCardController();

    await pumpFlipCard(tester, controller: controller);

    final flipCard = tester.widget<FlipCard>(find.byType(FlipCard));
    expect(flipCard.curve, same(Curves.linear));

    controller.flipcard();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 399));

    expect(find.text('front'), findsOneWidget);
    expect(find.text('back'), findsNothing);
  });

  testWidgets('FlipCard applies a custom curve to flip timing', (
    WidgetTester tester,
  ) async {
    final controller = FlipCardController();

    await pumpFlipCard(tester, controller: controller, curve: Curves.easeOut);

    final flipCard = tester.widget<FlipCard>(find.byType(FlipCard));
    expect(flipCard.curve, same(Curves.easeOut));

    controller.flipcard();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 399));

    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
  });

  testWidgets('controlled side starts on the back without animating', (
    WidgetTester tester,
  ) async {
    final controller = FlipCardController();

    await tester.pumpWidget(
      MaterialApp(
        home: FlipCard(
          controller: controller,
          side: FlipCardSide.back,
          rotateSide: RotateSide.bottom,
          axis: FlipAxis.horizontal,
          frontWidget: const Text('front'),
          backWidget: const Text('back'),
        ),
      ),
    );

    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
    expect(controller.side, FlipCardSide.back);
  });

  testWidgets('controlled side reverses from the current angle', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_ControlledFlipHostState> hostKey =
        GlobalKey<_ControlledFlipHostState>();

    await tester.pumpWidget(_ControlledFlipHost(key: hostKey));
    hostKey.currentState!.setSide(FlipCardSide.back);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 250));
    final double outboundValue =
        hostKey.currentState!.controller.state!.animationController.value;
    expect(outboundValue, inExclusiveRange(0, 1));

    hostKey.currentState!.setSide(FlipCardSide.front);
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 60));
    expect(
      hostKey.currentState!.controller.state!.animationController.value,
      lessThan(outboundValue),
    );

    await tester.pumpAndSettle();
    expect(find.text('front'), findsOneWidget);
    expect(find.text('back'), findsNothing);
    expect(hostKey.currentState!.controller.side, FlipCardSide.front);
  });

  testWidgets('reduced motion jumps directly to the controlled side', (
    WidgetTester tester,
  ) async {
    final GlobalKey<_ControlledFlipHostState> hostKey =
        GlobalKey<_ControlledFlipHostState>();

    await tester.pumpWidget(
      _ControlledFlipHost(key: hostKey, disableAnimations: true),
    );
    hostKey.currentState!.setSide(FlipCardSide.back);
    await tester.pump();

    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
  });
}

class _ControlledFlipHost extends StatefulWidget {
  const _ControlledFlipHost({super.key, this.disableAnimations = false});

  final bool disableAnimations;

  @override
  State<_ControlledFlipHost> createState() => _ControlledFlipHostState();
}

class _ControlledFlipHostState extends State<_ControlledFlipHost> {
  final FlipCardController controller = FlipCardController();
  FlipCardSide side = FlipCardSide.front;

  void setSide(FlipCardSide nextSide) {
    setState(() => side = nextSide);
  }

  @override
  Widget build(BuildContext context) {
    return MaterialApp(
      home: MediaQuery(
        data: MediaQueryData(disableAnimations: widget.disableAnimations),
        child: FlipCard(
          controller: controller,
          side: side,
          rotateSide: RotateSide.bottom,
          axis: FlipAxis.horizontal,
          animationDuration: const Duration(milliseconds: 520),
          curve: Curves.easeInOutCubic,
          frontWidget: const Text('front'),
          backWidget: const Text('back'),
        ),
      ),
    );
  }
}
