import 'dart:io';

//Imports removed due to security reasons.

class AppProvider extends ChangeNotifier {
  late PageController _pageController;

  PageController get pageController => _pageController;

  set pageController(PageController pageController) {
    _pageController = pageController;
    notifyListeners();
  }

  int navIndex = 0;
  bool showKeyboardFocusOnSearch = false;
  TabController? tabController;
  bool isExperimentalFeaturesAllowed = false;
  bool shouldContinueToCreateTradingAccount = false;

  UserCubit get userCubit => UserCubit.read();

  UserProfile? get user => userCubit.userProfile;

  bool get isLoggedin => userCubit.isLoggedIn;

  ApexUserStatus? apexStatus = navigator.currentContext!
      .read<PortfolioBloc>()
      .state
      .data
      ?.apexUserStatus;

  bool isAuthenticating = false;
  bool didUserOnboard = false;
  IAPConfig? iapConfig;
  Plans? selectedPlan;
  String? tempPassword;

  void fetchIapconfig() async {
    iapConfig = await IAPConfig.getIAPConfig();
    notifyListeners();
  }

  set setShouldContinueToCreateTradingAccount(bool value) {
    shouldContinueToCreateTradingAccount = value;
    notifyListeners();
  }

  set setTempPassword(String? p) {
    tempPassword = p;
  }

  void setSelectedPlan(Plans? selected) async {
    selectedPlan = selected;
    notifyListeners();
  }

  set setExperimentalStatus(bool status) {
    isExperimentalFeaturesAllowed = status;
    notifyListeners();
  }

  set setKeyboardShowStatus(bool status) {
    showKeyboardFocusOnSearch = status;
    notifyListeners();
  }

  proceedIfLoggedIn(Function callback) {
    if (!isLoggedin) {
      loginModalSheet();
    } else {
      return callback();
    }
  }

  proceedIfLoggedInAndHasTradingAccount(Function callback,
      {bool fromInvestment = false}) {
    if (!isLoggedin) {
      loginModalSheet();
    } else {
      bool isStreaming = AppConfiguration.portfolioFromStreaming;
      String? userAccountStatus = isStreaming
          ? apexStatus?.status?.toLowerCase()
          : user?.userAccountStatus;
      bool? isUserAccountActive =
          isStreaming ? apexStatus?.isActive : user?.isUserAccountActive;
      if ([UserAccountStatusValue.complete, UserAccountStatusValue.pending]
              .contains(userAccountStatus.toString()) &&
          !(isUserAccountActive ?? false)) {
        return callback();
      } else {
        return callback();
      }
    }
  }

  proceedIfHasTradingAccount(Function callback, {bool fromInvestment = false}) {
    final hasTradingAccount = user?.hasTradingAccount ?? false;
    final isUserAccountActive = AppConfiguration.portfolioFromStreaming
        ? (apexStatus?.isActive ?? false)
        : (user?.isUserAccountActive ?? false);
    final userAccountStatus = AppConfiguration.portfolioFromStreaming
        ? apexStatus?.status?.toLowerCase()
        : user?.userAccountStatus;
    if (!hasTradingAccount) {
      return showCustomModalBottomSheet(const CreateTradingAccount());
    } else {
      if ([UserAccountStatusValue.complete, UserAccountStatusValue.pending]
              .contains(userAccountStatus) &&
          !isUserAccountActive) {
        return callback();
      } else if (userAccountStatus == UserAccountStatusValue.complete &&
          !(user?.hasAchAccount ?? false)) {
        return showCustomModalBottomSheet(
            LinkPlaidAccount(fromInvestments: fromInvestment));
      } else {
        return callback();
      }
    }
  }

  Future<bool> setSecureFlag() {
    if (Platform.isAndroid && !MagnifiAppInfo.isStagingApp) {
      return FlutterWindowManager.addFlags(FlutterWindowManager.FLAG_SECURE);
    }
    return Future.value(true);
  }

  set setUserOnboardStatus(bool status) {
    Prefs.setBool('userOnboardStatus', status);
    didUserOnboard = status;
    notifyListeners();
  }
}
