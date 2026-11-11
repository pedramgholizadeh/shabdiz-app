import 'package:flutter_riverpod/flutter_riverpod.dart';

import '../../data/models/user.dart';

/// In-memory session identity, hydrated at splash and updated on sign-in/out.
/// Widgets read this instead of poking secure storage directly.
class CurrentUserSession extends Notifier<User?> {
  @override
  User? build() => null;

  void set(User? user) => state = user;
}

final currentUserProvider =
    NotifierProvider<CurrentUserSession, User?>(CurrentUserSession.new);
