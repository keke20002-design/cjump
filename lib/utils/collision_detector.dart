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
  }) {
    // Basic AABB overlap
    if (!charRect.overlaps(platformRect)) return null;

    if (isNormalGravity) {
      // Player moves downward (+Y), hits TOP surface of platform
      if (velocityY <= 0) return null;
      final charBottom = charRect.bottom;
      final platTop = platformRect.top;
      // Ensure the character's bottom was above the platform top last frame
      // (penetration check: bottom is within platform height range)
      if (charBottom - velocityY * 0.016 > platTop) return null;
      return const CollisionResult(surface: CollisionSurface.top);
    } else {
      // Player moves upward (-Y), hits BOTTOM surface of platform
      if (velocityY >= 0) return null;
      final charTop = charRect.top;
      final platBottom = platformRect.bottom;
      if (charTop - velocityY * 0.016 < platBottom) return null;
      return const CollisionResult(surface: CollisionSurface.bottom);
    }
  }
}

enum CollisionSurface { top, bottom }

class CollisionResult {
  final CollisionSurface surface;
  const CollisionResult({required this.surface});
}
