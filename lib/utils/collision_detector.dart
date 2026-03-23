import 'dart:ui';

/// AABB collision helper.
/// Returns true and provides bounce info only when the collision is "valid"
/// given current velocity and gravity direction.
class CollisionDetector {
  /// Check if [charRect] overlaps [platformRect] in a directional manner.
  /// [velocityY] positive = moving down, negative = moving up.
  /// [isNormalGravity] true = bounce off top of platform, false = bounce off bottom.
  static CollisionResult? check({
    required Rect charRect,
    required Rect platformRect,
    required double velocityY,
    required bool isNormalGravity,
    double dt = 0.016,
  }) {
    // Basic AABB overlap
    if (!charRect.overlaps(platformRect)) return null;

    if (isNormalGravity) {
      // Player moves downward (+Y), hits TOP surface of platform
      if (velocityY <= 0) return null;
      final charBottom = charRect.bottom;
      final platTop = platformRect.top;
      // Swept check: previous-frame bottom must have been at or above platTop
      // (i.e., player crossed the boundary this frame, not already past it)
      final prevBottom = charBottom - velocityY * dt;
      if (prevBottom > platTop) return null;
      return const CollisionResult(surface: CollisionSurface.top);
    } else {
      // Player moves upward (-Y), hits BOTTOM surface of platform
      if (velocityY >= 0) return null;
      final charTop = charRect.top;
      final platBottom = platformRect.bottom;
      // Swept check: previous-frame top must have been at or below platBottom
      final prevTop = charTop - velocityY * dt;
      if (prevTop < platBottom) return null;
      return const CollisionResult(surface: CollisionSurface.bottom);
    }
  }
}

enum CollisionSurface { top, bottom }

class CollisionResult {
  final CollisionSurface surface;
  const CollisionResult({required this.surface});
}
