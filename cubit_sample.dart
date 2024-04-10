//Imports removed due to security reasons.

class LocalAuthCubit extends Cubit<LocalAuthState> {
  LocalAuthCubit({required this.service}) : super(LocalAuthState.initial());

  final MagnifiLocalAuthService service;

  Future<bool> initiateLocalAuth(InitateLocalAuth event) async {
    if (state.status == AuthenticationStatus.authenticated) {
      if (event.callback != null) {
        event.callback!();
      }
      return true;
    }
    final Map<String, dynamic> response = await service.authenticate();

    final notSuccesful = response['authReason'] == "NOT SUCCESSFUL";

    emit(state.copyWith(
      status: response['status'],
      authReason: response['authReason'],
    ));

    final userProvider = UserCubit.read();

    if (state.authReason == "NO AUTH MODE") {
      MagnifiStorage.userCredentials = null;
    }

    if (["NO AUTH MODE", "CANCELLED", "ERROR", "AUTH_IN_PROGRESS_CANCELLED"]
            .contains(state.authReason) &&
        (event.handleError ?? true)) {
      final userProvider = UserCubit.read();
      userProvider.logout();
      Future.delayed(
        const Duration(milliseconds: 300),
        () => loginModalSheet(),
      );
    } else if (state.status != null &&
        state.status == AuthenticationStatus.authenticated) {
      if (event.lockedOut) {
        if (userProvider.isLoggedIn) {
          if (NavigationService.canPop) {
            NavigationService.pop();
          } else {
            NavigationService.popUntil(Routes.app);
          }
          navigator.currentContext?.read<PortfolioBloc>().reconnect();
        } else {
          NavigationService.popAllandPushNamed(Routes.authInterstitial);
        }
      } else if (event.callback != null) {
        event.callback!();
      }
    }
    MagnifiAnalytics.track("Local Auth", properties: {
      "status": response['status'].toString(),
      "authReason": response['authReason'],
    });
    return !notSuccesful;
  }

  Future<void> lockedDueToInactivity() async {
    if (UserCubit.read().isLoggedIn) {
      Logger.info("Locked due to inactivity");
      NavigationService.pushNamed(Routes.authBlocker);
      emit(state.copyWith(
        status: AuthenticationStatus.lockedDueToInactivity,
        authReason: "Locked due to inactivity".toUpperCase(),
        isAvailable: state.isAvailable,
      ));
    }
  }

  Future<void> checkSystemLock() async {
    final hasSystemLock = await service.hasSystemLockSupport();
    emit(state.copyWith(
      isAvailable: hasSystemLock,
      status: null,
      authReason: null,
    ));
    prettyLogger(state.toString());
  }

  Future<void> intentionalBypass() async {
    Future.delayed((const Duration(seconds: 4)), () async {
      if (state.isAvailable != null && state.isAvailable!) {
        String? d = ModalRoute.of(navigator.currentContext!)?.settings.name;
        prettyLogger(d);
        NavigationService.pop();
      }
    });
    prettyLogger(state.toString());
  }

  void logout() {
    emit(LocalAuthState.initial());
  }
}
