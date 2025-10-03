import 'dart:async';
import 'dart:developer';
import 'dart:io';

import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/billing_client_wrappers.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';
import 'package:in_app_purchase_storekit/store_kit_wrappers.dart';

class GPaymentUtils {
  final InAppPurchase _inAppPurchase = InAppPurchase.instance;
  StreamSubscription<List<PurchaseDetails>>? _subscription;
  final Function(String message) onMessage;
  final Function(PurchaseDetails purchaseDetails) onPurchaseVerified;
  final Function() onPurchasePending;
  final Function(PurchaseDetails purchaseDetails) onPurchasedError;
  GPaymentUtils({
    required this.onMessage,
    required this.onPurchaseVerified,
    required this.onPurchasePending,
    required this.onPurchasedError,
  });

  void initialize() {
    final Stream<List<PurchaseDetails>> purchaseUpdated =
        _inAppPurchase.purchaseStream;
    _subscription = purchaseUpdated.listen(
      (purchaseDetailsList) {
        _listenToPurchaseUpdated(purchaseDetailsList);
      },
      onDone: () {
        _subscription?.cancel();
      },
      onError: (error) {
        onMessage('In-app purchase error: $error');
      },
    );
  }

  Future<void> restorePurchases() async {
    await _inAppPurchase.restorePurchases();
  }

  void dispose() {
    _subscription?.cancel();
  }

  void _listenToPurchaseUpdated(List<PurchaseDetails> purchaseDetailsList) {
    for (final purchaseDetails in purchaseDetailsList) {
      switch (purchaseDetails.status) {
        case PurchaseStatus.pending:
          onPurchasePending();
          break;
        case PurchaseStatus.canceled:
          onMessage('Purchase was canceled by the user.');
          onPurchasedError(purchaseDetails);
          break;
        case PurchaseStatus.error:
          onMessage('Payment failed: ${purchaseDetails.error?.message}');
          onPurchasedError(purchaseDetails);
          if (purchaseDetails.error?.message.contains(
                "You already own this item",
              ) ==
              true) {
            restorePurchases();
          }
          break;
        case PurchaseStatus.purchased:
        case PurchaseStatus.restored:
          onPurchaseVerified(purchaseDetails);

          _inAppPurchase.completePurchase(purchaseDetails);
          break;
      }
    }
  }

  Future<void> buyConsumableProduct(String productId) async {
    final String formattedProductId = productId.replaceAll('-', '_');
    final Set<String> productIds = <String>{formattedProductId};

    try {
      if (Platform.isIOS) {
        final InAppPurchaseStoreKitPlatformAddition iosPlatformAddition =
            _inAppPurchase
                .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
        await iosPlatformAddition.setDelegate(ExamplePaymentQueueDelegate());
      }
      ProductDetailsResponse? response;
      try {
        response = await _inAppPurchase.queryProductDetails(productIds);
      } on Exception catch (e) {
        log('❌ Failed to query product details: $e');
      }

      if (response!.notFoundIDs.isNotEmpty) {
        onMessage('Product not found: ${response.notFoundIDs.join(', ')}');
        return;
      }
      log('query product list is ${response.productDetails.length}');
      final ProductDetails productDetails = response.productDetails.first;
      final PurchaseParam purchaseParam = PurchaseParam(
        productDetails: productDetails,
      );

      if (Platform.isAndroid) {
        // 🔹 Check if Alternative Billing is required
        final androidAddition = _inAppPurchase
            .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

        final isAltBillingAvailable = await androidAddition
            .isAlternativeBillingOnlyAvailable();
        log('alternate billing is ${isAltBillingAvailable.responseCode}');
        if (isAltBillingAvailable.responseCode == BillingResponse.ok) {
          log('alternate billing is ok');

          // 🔹 Show mandatory info dialog
          final dialogResult = await androidAddition
              .showAlternativeBillingOnlyInformationDialog();
          if (dialogResult.responseCode != BillingResponse.ok) {
            onMessage("User dismissed alternative billing dialog");
            return;
          }

          // 🔹 Switch to alternative billing mode
          await androidAddition.setBillingChoice(
            BillingChoiceMode.alternativeBillingOnly,
          );

          // 🔹 Run your custom checkout flow (replace this with your real logic)
          final bool paymentSuccess = await _runCustomCheckout();

          if (paymentSuccess) {
            // 🔹 Report purchase back to Google
            final reportingDetails = await androidAddition
                .createAlternativeBillingOnlyReportingDetails();

            log(
              "Report_token: ${reportingDetails.externalTransactionToken} response code ${reportingDetails.responseCode}",
            );

            // Send reportingDetails.reportingToken to your backend
          } else {
            log("Alternative billing payment failed or canceled");
          }
          return;
        }
      }
      log('ios/android params are ${purchaseParam.productDetails.title}');
      await _inAppPurchase.buyConsumable(purchaseParam: purchaseParam);
    } catch (e) {
      onMessage('Error during purchase: ${e.toString()}');
    }
  }

  /// Example stub for your own payment processor.
  /// Replace this with  Razorpay, PayPal, UPI, etc.
  Future<bool> _runCustomCheckout() async {
    // Open your custom checkout screen
    // return true if payment succeeds
    // return false if payment fails/cancelled
    log('run custom checkout');
    return Future.value(true);
  }
}

class ExamplePaymentQueueDelegate implements SKPaymentQueueDelegateWrapper {
  @override
  bool shouldContinueTransaction(
    SKPaymentTransactionWrapper transaction,
    SKStorefrontWrapper storefront,
  ) {
    return true;
  }

  @override
  bool shouldShowPriceConsent() {
    return false;
  }
}
