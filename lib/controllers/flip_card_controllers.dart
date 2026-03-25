import '../flipcard/flip_card.dart';
import '../flipcard/gesture_flip_card.dart';
import '../modal/flip_side.dart';

///This controller used to call Fliping
class FlipCardController {
  FlipCardState? state;

  /// Flip the card
  Future flipcard({RotateSide? rotateSide}) async =>
      state?.flipCard(rotateSide: rotateSide);
}

class GestureFlipCardController {
  FlipCardState1? state;

  /// Flip the card
  Future flipcard() async => state?.gestureflipCard();
}
