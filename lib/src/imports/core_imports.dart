// Flutter SDK
export 'package:flutter/material.dart';
export 'package:flutter/cupertino.dart' hide RefreshCallback;
export 'package:flutter/foundation.dart';
export 'package:flutter/services.dart';
export 'package:flutter_native_splash/flutter_native_splash.dart';
export 'dart:async';
export 'dart:math';

// Project Core — everything exported through shared.dart (theme, extensions,
// utils, widgets, enums) plus routing and services.
export '../config/app_config.dart';
export '../routing/app_router.dart';
export '../routing/app_routes.dart';
export '../routing/global_navigator.dart';
export '../services/services.dart';
export '../shared/shared.dart';

export '../screens/auth/login_screen.dart';
export '../screens/auth/signup_screen.dart';
export '../screens/auth/forgot_password_screen.dart';
export '../screens/home/home_page.dart';
export '../screens/onboarding/onboarding_page.dart';
