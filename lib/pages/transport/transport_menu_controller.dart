import 'package:get/get.dart';

import 'transport_api.dart';

/// What the transport menu should show this person.
///
/// ---------------------------------------------------------------------------
/// THE SERVER DECIDES, NOT THE APP
/// ---------------------------------------------------------------------------
/// The tempting version reads `authController.userRole` and shows the driving
/// screens when it says "driver". It would work today and rot immediately:
/// being crew is not a role, it is a fact about a trip. The office records who
/// drives what on the trip itself, and it changes the week a driver is swapped.
///
/// So this asks `transport/me` and believes the answer. A driver put on a trip
/// this morning gets the driving screens this morning, with no new app version
/// and nobody ticking a box in the permissions screen.
///
/// ---------------------------------------------------------------------------
/// IT DOES NOT CALL THE API IN onInit
/// ---------------------------------------------------------------------------
/// Registering this at app start is the right place — once, permanent, next to
/// AuthController — but at that moment there is no token yet. A fetch in onInit
/// would 401, cache "not a parent, not crew", and the menu would stay empty for
/// the whole session with nothing to explain it.
///
/// So the fetch is explicit: `ensureLoaded()` from the drawer, which runs once
/// and only when there is something to draw, and `refreshProfile()` after a
/// login or a context switch.
///
/// It also fails quiet. A person with no transport at all is the common case,
/// and a menu showing an error where an entry would be is worse than a menu
/// with one fewer entry.
class TransportMenuController extends GetxController {
  final isParent = false.obs;
  final isCrew = false.obs;
  final canDispatch = false.obs;
  final loaded = false.obs;

  bool _inFlight = false;

  bool get showAnything => isParent.value || isCrew.value;

  /// Safe to call on every drawer build — it fetches once.
  void ensureLoaded() {
    if (loaded.value || _inFlight) return;
    refreshProfile();
  }

  /// Call after login, and after a context switch — a person can be a parent in
  /// one branch and crew in another, and the menu must follow the switch.
  Future<void> refreshProfile() async {
    if (_inFlight) return;
    _inFlight = true;

    try {
      final data = await TransportApi.profile();

      isParent.value = data['is_parent'] == true;
      isCrew.value = data['is_crew'] == true;
      canDispatch.value = data['can_dispatch'] == true;
      loaded.value = true;
    } catch (_) {
      // Left unloaded on failure, so the next drawer open tries again rather
      // than caching a "no transport" answer that came from a dropped
      // connection or a token that had not arrived yet.
      isParent.value = false;
      isCrew.value = false;
      canDispatch.value = false;
    } finally {
      _inFlight = false;
    }
  }

  /// After logout, so the next person to sign in does not inherit a menu.
  void clear() {
    isParent.value = false;
    isCrew.value = false;
    canDispatch.value = false;
    loaded.value = false;
  }
}
