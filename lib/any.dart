/// Lean command-based state management for Flutter with selective rebuilds.
///
/// Register state and repositories in [AnyScope], update through [Command]
/// subclasses, and observe with [AnyScopeBuildContext.of] or [AnySelector].
library;

import 'dart:async' show FutureOr, scheduleMicrotask;
import 'dart:developer' as developer;

import 'package:flutter/foundation.dart' show kDebugMode;
import 'package:flutter/widgets.dart';

part 'binding.dart';
part 'command.dart';
part 'scope.dart';
part 'any_scope.dart';
part 'selector.dart';
part 'context.dart';
part 'logging.dart';