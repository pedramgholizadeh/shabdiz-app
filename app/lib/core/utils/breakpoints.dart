/// Layout breakpoints shared by screens.
///
/// Android TV reports a very wide window, so the "wide" layouts double as the
/// 10-foot TV experience; no platform sniffing is needed.
const double kMediumBreakpoint = 600;
const double kWideBreakpoint = 900;

/// Maximum content width used to keep phone-proportioned lists readable on
/// large screens instead of stretching edge to edge.
const double kMaxContentWidth = 760;
const double kMaxGridWidth = 1200;

bool isCompact(double width) => width < kMediumBreakpoint;

bool isWide(double width) => width >= kWideBreakpoint;
