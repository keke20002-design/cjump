// Physics and game-wide constants
const double kGravityForce = 1800.0; // pixels/s²
const double kJumpVelocity = 700.0; // pixels/s on bounce
const double kMaxHorizontalSpeed = 400.0;
const double kGravityFlipCooldown = 1.5; // seconds
const double kAntiGravityDuration = 2.5; // seconds
const double kMinAntiGravityDuration = 1.2; // seconds
const double kBaseScrollSpeed = 30.0; // initial auto-scroll speed
const double kSpeedIncreaseFactor = 0.05; // speed increase per score point or second? user said 0.002 per frame.
const double kWorldTopLimit = -2000.0; // world Y limit for game over
const double kPlatformWidth = 80.0;
const double kPlatformHeight = 14.0;
const double kCharacterSize = 40.0;

// Platform generation
const int kInitialPlatformCount = 15;
const double kBasePlatformGap = 120.0;
const double kMinPlatformGap = 80.0;
const double kMaxPlatformGap = 220.0;

// Scoring
const double kScoreScale = 0.1; // world units → display score

// Gravity flip animation
const double kGravityFlipDuration = 0.2; // seconds

// Camera
const double kCameraLead = 0.35; // character stays at this fraction of screen height

// Electric ceiling (antigravity death zone)
const double kElectricWireY = 14.0; // screen-space Y of the electric wire
