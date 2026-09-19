import 'dart:async';

import 'package:flutter/material.dart';
import 'package:random_string/random_string.dart';

import '../common/config.dart';
import '../common/constants.dart';
import '../common/tools/error_key.dart';
import '../data/boxes.dart';
import '../generated/l10n.dart';
import '../services/index.dart';
import '../services/native_browser_session.dart';
import 'entities/cookie_data.dart';
import 'entities/user.dart';

abstract class UserModelDelegate {
  void onLoaded(User? user);

  void onLoggedIn(User user);

  void onLogout(User? user);
}

class UserModel with ChangeNotifier {
  UserModel();

  final Services _service = Services();
  User? user;
  bool loggedIn = false;
  bool loading = false;
  UserModelDelegate? delegate;

  void updateUser(User newUser) {
    user = newUser;
    _saveUser(user);
    notifyListeners();
  }

  Future<String?> submitForgotPassword(
      {String? forgotPwLink, Map<String, dynamic>? data}) async {
    return await _service.api
        .submitForgotPassword(forgotPwLink: forgotPwLink, data: data);
  }

  /// Social sign-in is intentionally disabled. Kanz uses phone verification.
  Future<void> loginApple({Function? success, Function? fail, context}) async {
    fail?.call('تسجيل الدخول متاح برقم الجوال فقط.');
  }

  /// Login by Firebase phone
  Future<void> loginFirebaseSMS(
      {String? phoneNumber,
      required Function success,
      Function? fail,
      required BuildContext context}) async {
    try {
      user = await _service.api.loginSMS(token: phoneNumber);
      await _saveUser(user);
      success(user);

      notifyListeners();
    } catch (err) {
      fail!(S.of(context).loginErrorServiceProvider(err.toString()));
    }
  }

  /// Social sign-in is not offered by Kanz. Accounts use phone verification.
  Future<void> loginFB({Function? success, Function? fail, context}) async {
    fail?.call('تسجيل الدخول متاح برقم الجوال فقط.');
  }

  Future<void> loginGoogle({Function? success, Function? fail, context}) async {
    fail?.call('تسجيل الدخول متاح برقم الجوال فقط.');
  }

  Future<void> loginWithCookie(
    String cookie, {
    Function? success,
    Function? fail,
    context,
  }) async {
    try {
      loading = true;
      notifyListeners();
      user = await _service.api.getUserInfo(cookie);

      if (user == null) {
        final cookies = cookie.convertToCookies();
        final hasInfoUser = cookies.any((element) =>
            ['pro_loyalty_api_session', 'customer_sig']
                .contains(element.name) &&
            element.value.isNotEmpty);

        if (hasInfoUser) {
          printLog('[loginWithUserWebAccess]:[ROUTE:] recheck cookie');
          await Future.delayed(const Duration(seconds: 2));
          user = await _service.api.getUserInfo(cookie);
        }

        if (user == null) {
          if (hasInfoUser) {
            throw Exception(ErrorKeyConstant.registerUnableToSyncAccount.name);
          }

          throw Exception(ErrorKeyConstant.registerInvalid.name);
        }
      }

      user!.cookie = cookie;

      await _saveUser(user);
      success?.call(user!);
      loading = false;
      notifyListeners();
    } catch (err) {
      loading = false;
      fail?.call(err.toString());
      notifyListeners();
    }
  }

  Future<void> _saveUser(User? user) async {
    await browserSession.changeAccount(user?.id?.toString());
    unawaited(Services().firebase.syncPublicNotificationDevice(user: user));
    try {
      if (Services().firebase.isEnabled && ServerConfig().isVendorType()) {
        Services().firebase.saveUserToFirestore(user: user);
      }

      // save to Preference
      UserBox().isLoggedIn = true;
      loggedIn = true;

      // save the user Info as local storage
      UserBox().userInfo = user;
      this.user = user;
      delegate?.onLoaded(user);

      //reload Home screen to show product price based on role
      if ((kAdvanceConfig.enableWooCommerceWholesalePrices ||
              kAdvanceConfig.b2bKingConfig.enabled) &&
          ServerConfig().isWooPluginSupported) {
        eventBus.fire(const EventLoadedAppConfig());
      }
    } catch (err) {
      printLog(err);
    }
  }

  Future<void> getUser() async {
    try {
      final localUser = UserBox().userInfo;
      if (localUser != null) {
        await browserSession.changeAccount(localUser.id?.toString());
        user = localUser;
        loggedIn = true;
        final userInfo = await _service.api.getUserInfo(user!.cookie);

        if (userInfo != null) {
          userInfo.isSocial = user!.isSocial;
          user = userInfo;
        }
        await setUser(user, acceptNull: true);
      } else {
        if (kPaymentConfig.guestCheckout &&
            ServerConfig().isNeedToGenerateTokenForGuestCheckout) {
          delegate?.onLoaded(User()..cookie = _getGenerateCookie());
        }
        notifyListeners();
      }
    } catch (err) {
      printLog(err);
    }
  }

  void setLoading(bool isLoading) {
    loading = isLoading;
    notifyListeners();
  }

  Future<void> setUser(User? user, {bool acceptNull = false}) async {
    if (user != null || acceptNull) {
      this.user = user;
      await _saveUser(user);
      if (ServerConfig().isHaravan && ['null', null].contains(user?.id)) {
        UserBox().isLoggedIn = false;
        loggedIn = false;
        user?.id = null;
      }

      notifyListeners();
    }
  }

  Future<void> createUser({
    String? username,
    String? email,
    String? password,
    String? firstName,
    String? lastName,
    String? phoneNumber,
    bool? isVendor,
    required Function success,
    Function? fail,
  }) async {
    try {
      loading = true;
      notifyListeners();
      Services().firebase.createUserWithEmailAndPassword(
          email: email ?? username, password: password!);

      user = await _service.api.createUser(
        firstName: firstName,
        lastName: lastName,
        username: username,
        email: email,
        password: password,
        phoneNumber: phoneNumber,
        isVendor: isVendor ?? false,
      );
      await _saveUser(user);
      success(user);

      loading = false;
      notifyListeners();
    } catch (err, trace) {
      fail!(err.toString());
      printError(err, trace);
      loading = false;
      notifyListeners();
    }
  }

  Future<void> logout() async {
    loggedIn = false;
    try {
      await browserSession.clear();
    } catch (_) {
      // Local logout still completes; new web pages remain gated until retry.
      printLog('[Logout] Browser cleanup requires retry');
    }
    try {
      unawaited(Services().firebase.signOut());
    } catch (err) {
      printLog(err);
    }

    delegate?.onLogout(user);
    unawaited(_service.api.logout(user?.cookie));
    user = null;

    if (kPaymentConfig.guestCheckout &&
        ServerConfig().isNeedToGenerateTokenForGuestCheckout) {
      delegate?.onLoaded(User()..cookie = _getGenerateCookie());
    }

    UserBox().cleanUpForLogout();
    notifyListeners();

    //reload Home screen to show correct product price without basing on role
    if ((kAdvanceConfig.enableWooCommerceWholesalePrices ||
            kAdvanceConfig.b2bKingConfig.enabled) &&
        ServerConfig().isWooPluginSupported) {
      eventBus.fire(const EventLoadedAppConfig());
    }
  }

  Future<void> login({
    required String username,
    required String password,
    required Function(User user) success,
    required Function(String message) fail,
  }) async {
    try {
      loading = true;
      notifyListeners();
      user = await _service.api.login(
        username: username,
        password: password,
      );

      final userEmail =
          (user?.email?.isNotEmpty ?? false) ? user?.email : username;
      Services().firebase.loginFirebaseEmail(
            email: userEmail,
            password: password,
          );

      if (user == null) {
        throw 'Something went wrong!!!';
      }
      await _saveUser(user);
      success(user!);
      loading = false;
      notifyListeners();
    } catch (err) {
      loading = false;
      fail(err.toString());
      notifyListeners();
    }
  }

  /// Use for generate fake cookie for guest check out
  String _getGenerateCookie() {
    var cookie = UserBox().userCookie;
    cookie ??= 'OCSESSID=${randomNumeric(30)}; PHPSESSID=${randomNumeric(30)}';
    UserBox().userCookie = cookie;
    return cookie;
  }
}
