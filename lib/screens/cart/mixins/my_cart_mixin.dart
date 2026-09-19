import 'dart:async';

import 'package:flutter/material.dart';
import 'package:provider/provider.dart';

import '../../../common/config.dart';
import '../../../common/constants.dart';
import '../../../common/extensions/extensions.dart';
import '../../../common/tools/biometrics_tools.dart';
import '../../../common/tools/flash.dart';
import '../../../common/tools/navigate_tools.dart';
import '../../../common/tools/price_tools.dart';
import '../../../common/tools/tools.dart';
import '../../../generated/l10n.dart';
import '../../../menu/maintab_delegate.dart';
import '../../../models/index.dart';
import '../../../routes/flux_navigate.dart';
import '../../../services/cart_validation.dart';
import '../../../services/service_config.dart';
import '../../../services/services.dart';
import '../../../widgets/product/product_bottom_sheet.dart';
import '../../checkout/checkout_screen.dart';

mixin MyCartMixin<T extends StatefulWidget> on State<T> {
  bool isLoading = false;
  String errMsg = '';
  bool _checkoutStarting = false;

  bool? get isModal;

  CartModel get cartModel => Provider.of<CartModel>(context, listen: false);

  void _loginWithResult(BuildContext context) async {
    await NavigateTools.navigateToLogin(
      context,
    );
    if (!mounted) return;

    final user = Provider.of<UserModel>(context, listen: false).user;
    if (user != null && user.name != null) {
      Tools.showSnackBar(ScaffoldMessenger.of(context),
          '${S.of(context).welcome} ${user.name} !');
      setState(() {});
    }
  }

  Future<void> clearCartPopup(BuildContext context) async {
    final confirmed = await context.showFluxDialogText(
      title: S.of(context).notice,
      body: S.of(context).confirmClearTheCart,
      primaryAction: S.of(context).clear,
      secondaryAction: S.of(context).keep,
      primaryAsDestructiveAction: true,
      directionButton: Axis.vertical,
    );
    if (confirmed) {
      cartModel.clearCart();
    }
  }

  void onCheckout(CartModel model) {
    var isLoggedIn = Provider.of<UserModel>(context, listen: false).loggedIn;
    final appModel = Provider.of<AppModel>(context, listen: false);
    final currencyRate = appModel.currencyRate;
    final currency = appModel.currency;

    var message;

    if (isLoading) return;

    if (kCartDetail['minAllowTotalCartValue'] != null) {
      if (kCartDetail['minAllowTotalCartValue'].toString().isNotEmpty) {
        var totalValue = model.getSubTotal() ?? 0;
        var minValue = PriceTools.getCurrencyFormatted(
            kCartDetail['minAllowTotalCartValue'], currencyRate,
            currency: currency);
        if (totalValue < kCartDetail['minAllowTotalCartValue'] &&
            model.totalCartQuantity > 0) {
          message = '${S.of(context).totalCartValue} $minValue';
        }
      }
    }

    if (kVendorConfig.disableMultiVendorCheckout &&
        ServerConfig().isVendorType()) {
      if (!model.isDisableMultiVendorCheckoutValid(
          model.productsInCart, model.getProductById)) {
        message = S.of(context).youCanOnlyOrderSingleStore;
      }
    }

    if (message != null) {
      FlashHelper.errorMessage(context, message: message);
      return;
    }

    if (model.totalCartQuantity == 0) {
      if (isModal == true) {
        try {
          ExpandingBottomSheet.of(context)!.close();
        } catch (e) {
          Navigator.of(context).pushNamed(RouteList.dashboard);
        }
      } else {
        final modalRoute = ModalRoute.of(context);
        if (modalRoute?.canPop ?? false) {
          Navigator.of(context).pop();
        }

        MainTabControlDelegate.getInstance().changeToDefaultTab();
      }
    } else if (isLoggedIn) {
      doCheckout();
    } else {
      _loginWithResult(context);
    }
  }

  Future<void> doCheckout() async {
    if (!mounted || _checkoutStarting || isLoading) return;
    _checkoutStarting = true;
    try {
      if (BiometricsTools.instance.isCheckoutSupported) {
        var didAuth = await BiometricsTools.instance.localAuth(context);
        if (!didAuth) {
          return;
        }
      }
      if (!mounted) return;
      showLoading();

      await Services().widget.doCheckout(
        context,
        success: () async {
          if (!mounted) return;
          hideLoading('');

          if (ServerConfig().isHaravan) {
            await FluxNavigate.pushNamed(
              RouteList.checkoutWithWebview,
              context: context,
              forceRootNavigator: true,
            );
            return;
          }

          var manualClosed = await FluxNavigate.pushNamed(
            RouteList.checkout,
            arguments: CheckoutArgument(isModal: isModal),
            forceRootNavigator: true,
            context: context,
          );

          if (true == manualClosed) {
            if (!mounted) return;
            if (isModal == true) {
              try {
                ExpandingBottomSheet.of(context)!.close();
              } catch (e) {
                if (ModalRoute.of(context)?.canPop ?? false) {
                  Navigator.of(context).pop();
                } else {
                  await Navigator.of(context).pushNamed(RouteList.dashboard);
                }
              }
            } else if (ModalRoute.of(context)?.canPop ?? false) {
              Navigator.of(context).pop();
            }
          }
        },
        error: (message) async {
          if (!mounted) return;
          if (message ==
              Exception('Token expired. Please logout then login again')
                  .toString()) {
            setState(() {
              isLoading = false;
            });
            //logout
            final userModel = Provider.of<UserModel>(context, listen: false);
            await userModel.logout();
            await Services().firebase.signOut();
            if (!mounted) return;
            _loginWithResult(context);
          } else {
            final displayError = message is CartValidationNotice
                ? message.message
                : 'تعذر الانتقال إلى الدفع. تحقق من الاتصال ثم أعد المحاولة.';
            hideLoading(displayError);
            unawaited(FlashHelper.errorMessage(context, message: displayError));
          }
        },
        loading: (isLoading) {
          if (!mounted) return;
          setState(() {
            this.isLoading = isLoading;
          });
        },
      );
    } catch (_) {
      if (mounted) {
        const message =
            'تعذر الانتقال إلى الدفع. تحقق من الاتصال ثم أعد المحاولة.';
        hideLoading(message);
        unawaited(FlashHelper.errorMessage(context, message: message));
      }
    } finally {
      _checkoutStarting = false;
      if (mounted && isLoading) hideLoading('');
    }
  }

  void showLoading() {
    if (!mounted) return;
    setState(() {
      isLoading = true;
      errMsg = '';
    });
  }

  void hideLoading(error) {
    if (!mounted) return;
    setState(() {
      isLoading = false;
      errMsg = error?.toString() ?? '';
    });
  }

  void onPressedClose(String layoutType, bool? isBuyNow) {
    if (isBuyNow!) {
      Navigator.of(context).pop();
      return;
    }

    if (Navigator.of(context).canPop() &&
        ['simpleType', 'flatStyle'].contains(layoutType) == false) {
      Navigator.of(context).pop();
    } else {
      ExpandingBottomSheet.of(context, isNullOk: true)?.close();
    }
  }
}
