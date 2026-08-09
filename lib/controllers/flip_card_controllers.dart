import '../flipcard/flip_card.dart';
import '../flipcard/gesture_flip_card.dart';
import '../modal/flip_side.dart';

///This controller used to call Fliping
class FlipCardController {
  FlipCardState? state;

  /// Flip the card
  Future<void> flipcard({RotateSide? rotateSide}) async =>
      state?.flipCard(rotateSide: rotateSide);

  /// Animates the card to [side] without relying on its current side.
  Future<void> showSide(
    FlipCardSide side, {
    RotateSide? rotateSide,
    bool animate = true,
  }) async => state?.showSide(side, rotateSide: rotateSide, animate: animate);

  /// The side the card is currently moving toward.
  FlipCardSide? get side => state?.targetSide;
}

class GestureFlipCardController {
  FlipCardState1? state;

  /// Flip the card
  Future flipcard() async => state?.gestureflipCard();
}
