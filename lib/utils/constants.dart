// Physics and game-wide constants
const double kGravityForce = 1800.0; // pixels/s²
const double kJumpVelocity = 700.0; // pixels/s on bounce
const double kMaxHorizontalSpeed = 400.0;
const double kGravityFlipCooldown = 1.5; // seconds
const double kPlatformWidth = 80.0;
const double kPlatformHeight = 14.0;
const double kCharacterSize = 40.0;

// Platform generation
const int kInitialPlatformCount = 15;
const double kMinPlatformGap = 80.0;
const double kMaxPlatformGap = 160.0;

// Scoring
const double kScoreScale = 0.1; // world units → display score

// Gravity flip animation
const double kGravityFlipDuration = 0.2; // seconds

// Camera
const double kCameraLead = 0.35; // character stays at this fraction of screen height

// Electric ceiling (antigravity death zone)
const double kElectricWireY = 14.0; // screen-space Y of the electric wire
