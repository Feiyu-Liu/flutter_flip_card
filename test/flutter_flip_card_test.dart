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

  testWidgets('FlipCard defaults to a linear curve',
      (WidgetTester tester) async {
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

  testWidgets('FlipCard applies a custom curve to flip timing',
      (WidgetTester tester) async {
    final controller = FlipCardController();

    await pumpFlipCard(
      tester,
      controller: controller,
      curve: Curves.easeOut,
    );

    final flipCard = tester.widget<FlipCard>(find.byType(FlipCard));
    expect(flipCard.curve, same(Curves.easeOut));

    controller.flipcard();
    await tester.pump();
    await tester.pump(const Duration(milliseconds: 399));

    expect(find.text('front'), findsNothing);
    expect(find.text('back'), findsOneWidget);
  });
}
