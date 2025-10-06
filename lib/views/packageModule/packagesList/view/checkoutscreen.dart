import 'dart:convert';
import 'dart:developer';
import 'dart:io';
import 'package:cached_network_image/cached_network_image.dart';
import 'package:easy_localization/easy_localization.dart';
import 'package:esimtel/utills/UserService.dart';
import 'package:esimtel/utills/appColors.dart';
import 'package:esimtel/utills/paymentUtils/fibpaymentservice.dart';
import 'package:esimtel/views/packageModule/packagesList/bloc/order_bloc/order_now_bloc.dart';
import 'package:esimtel/views/packageModule/packagesList/model/ordernowModel.dart';
import 'package:esimtel/views/packageModule/packagesList/view/GPaymentUtils.dart';
import 'package:flutter/material.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:get/get.dart';
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/global.dart' as global;
import 'package:esimtel/views/navbarModule/bloc/navbar_bloc.dart';
import 'package:in_app_purchase/in_app_purchase.dart';
import 'package:in_app_purchase_android/in_app_purchase_android.dart';
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/order_bloc/package_datail_event.dart';
import '../bloc/payment_verify_bloc/bloc/payment_verify_bloc.dart';
import '../bloc/payment_verify_bloc/bloc/payment_verify_event.dart';
import '../bloc/payment_verify_bloc/model/paymentverifyModel.dart';
import '../bloc/razorpay_error_bloc/razorpay_error_bloc.dart';
import '../bloc/razorpay_error_bloc/razorpay_error_event.dart';
import 'package:in_app_purchase_storekit/in_app_purchase_storekit.dart';

import 'fibpaymentscree.dart';

class Checkoutscreen extends StatefulWidget {
  dynamic packageListInfo;
  final bool isTopUp;
  final String? iccid;
  Checkoutscreen({
    super.key,
    required this.packageListInfo,
    this.isTopUp = false,
    this.iccid,
  });

  @override
  State<Checkoutscreen> createState() => _CheckoutscreenState();
}

class _CheckoutscreenState extends State<Checkoutscreen> {
  dynamic formattedRupees;
  dynamic esimOrderId;
  bool isloading = false;
  final userService = UserService.to;
  late GPaymentUtils _gpaymentUtils;
  String? selectedPaymentMethod;
  dynamic verified_esim_order_id = '';
  dynamic payment_order_id = '';
  final fibPaymentService = FIBPaymentService();

  @override
  void initState() {
    super.initState();

    final paiseString = widget.packageListInfo.netPrice.toString();
    final rupees = (double.tryParse(paiseString) ?? 0);
    formattedRupees = rupees.toStringAsFixed(0);
    log('🔹 initState $paiseString and ruppe is $rupees ');

    // ✅ Initialize Google Payment Billing
    _initializeGoogleBilling();

    // ✅ Initialize Alternative Google Payment Billing
    _setupAlternativeBillingListener();
  }

  // Build App Link Button
  Widget _buildAppLinkButton(
    String text,
    String url,
    IconData icon,
    Color color,
  ) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: () async {
          if (await canLaunchUrl(Uri.parse(url))) {
            await launchUrl(Uri.parse(url));
          } else {
            _showErrorDialog(
              "Cannot open FIB app. Please install the FIB app from Play Store.",
            );
          }
        },
        borderRadius: BorderRadius.circular(10),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(10),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Icon(icon, color: color, size: 20),
              const SizedBox(width: 12),
              Expanded(
                child: Text(
                  text,
                  style: TextStyle(
                    fontWeight: FontWeight.w500,
                    color: Colors.grey.shade800,
                  ),
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 16,
              ),
            ],
          ),
        ),
      ),
    );
  }

  void _showErrorDialog(String message) {
    showDialog(
      context: context,
      builder: (BuildContext context) {
        return AlertDialog(
          title: Text("Payment Error"),
          content: Text(message),
          actions: [
            TextButton(
              onPressed: () => Navigator.of(context).pop(),
              child: Text("OK"),
            ),
          ],
        );
      },
    );
  }

  @override
  void dispose() {
    _gpaymentUtils.dispose();
    super.dispose();
  }

  @override
  Widget build(BuildContext context) {
    return SafeArea(
      top: false,
      child: Scaffold(
        appBar: AppBar(title: const Text('Checkout Screen').tr()),
        body: SingleChildScrollView(
          padding: const EdgeInsets.all(16.0),
          child: BlocListener<OrderNowBloc, ApiState<OrderNowModel>>(
            listener: (context, state) async {
              if (state is ApiLoading) {
                setState(() {
                  isloading = true;
                });
              }
              if (state is ApiFailure) {
                setState(() {
                  isloading = false;
                });
              }
              if (state is ApiSuccess) {
                log('ApiSuccess caleld');
                Get.back();
                setState(() {
                  isloading = false;
                  esimOrderId = state.data!.data!.esimOrderId;
                  verified_esim_order_id = state.data?.data?.esimOrderId;
                  payment_order_id = state.data?.data?.gatewayOrderId;
                });
                log(
                  'called fib or billing ${state.data?.data!.payment_gateway}',
                );
                if (state.data?.data!.payment_gateway == 'GpayInAppPurchase') {
                  //! check billing or fib then call for verificaitoin
                  _gpaymentUtils.buyConsumableProduct(
                    payment_order_id.toString(),
                  );
                } else {
                  // Get.back();
                  Get.to(
                    () => FIBPaymentScreen(
                      esimOrderId: esimOrderId,
                      isTopUp: widget.isTopUp,
                      iccid: widget.iccid,
                      amount: state.data!.data!.amount.toString(),
                      paymentResponse: {},
                      packageId: widget.packageListInfo.id.toString(),
                    ),
                  );
                }
              }
            },

            child: Column(
              crossAxisAlignment: CrossAxisAlignment.stretch,
              children: [
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Package Details',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                        ),
                        const SizedBox(height: 10),
                        Row(
                          children: [
                            widget.packageListInfo!.country != null
                                ? ClipRRect(
                                    borderRadius: BorderRadius.circular(8),
                                    child: CachedNetworkImage(
                                      imageUrl:
                                          "${widget.packageListInfo!.country?.image}",
                                      width: 60,
                                      height: 60,
                                      fit: BoxFit.cover,
                                      placeholder: (context, url) =>
                                          Skeletonizer(
                                            child: Container(
                                              width: 60,
                                              height: 60,
                                              color: Colors.grey[200],
                                            ),
                                          ),
                                      errorWidget: (context, url, error) =>
                                          Container(
                                            width: 60,
                                            height: 60,
                                            color: Colors.grey[200],
                                            child: const Icon(
                                              Icons.error,
                                              color: Colors.red,
                                            ),
                                          ),
                                    ),
                                  )
                                : SizedBox(),
                            const SizedBox(width: 16),
                            widget.packageListInfo!.country != null
                                ? Expanded(
                                    child: Column(
                                      crossAxisAlignment:
                                          CrossAxisAlignment.start,
                                      children: [
                                        Text(
                                          widget.packageListInfo!.country?.name,
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 16.sp,
                                                color: AppColors.textColor,
                                              ),
                                        ),
                                        const SizedBox(height: 4),
                                        Text(
                                          'Coverage: ${widget.packageListInfo!.country?.name}',
                                          style: Theme.of(context)
                                              .textTheme
                                              .bodyMedium!
                                              .copyWith(
                                                fontSize: 16.sp,
                                                color: AppColors.textGreyColor,
                                              ),
                                        ),
                                      ],
                                    ),
                                  )
                                : SizedBox(),
                          ],
                        ),
                        SizedBox(height: 5.w),
                        _buildDetailRow('Data', widget.packageListInfo!.data),
                        Divider(color: AppColors.dividerColor),
                        _buildDetailRow(
                          'Validity',
                          widget.packageListInfo!.day,
                        ),
                        Divider(color: AppColors.dividerColor),
                        _buildDetailRow(
                          'Package ID',
                          widget.packageListInfo!.id,
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),

                // Payment Summary Section
                Card(
                  elevation: 1,
                  shape: RoundedRectangleBorder(
                    side: BorderSide(color: AppColors.dividerColor),
                    borderRadius: BorderRadius.circular(12),
                  ),
                  child: Padding(
                    padding: const EdgeInsets.all(16.0),
                    child: Column(
                      crossAxisAlignment: CrossAxisAlignment.start,
                      children: [
                        Text(
                          'Payment Summary',
                          style: Theme.of(context).textTheme.bodyMedium!
                              .copyWith(
                                fontSize: 17.sp,
                                fontWeight: FontWeight.w500,
                                color: AppColors.textColor,
                              ),
                        ),
                        const SizedBox(height: 16),
                        Divider(color: AppColors.dividerColor),
                        _buildDetailRow(
                          'Subtotal',

                          '${global.activeCurrency} ${global.formatPrice(double.parse(formattedRupees))}',
                        ),
                        Divider(color: AppColors.dividerColor),
                        _buildDetailRow(
                          'Tax',
                          '${global.activeCurrency} ${global.formatPrice(0.00)}',
                        ),
                        Divider(color: AppColors.dividerColor),
                        _buildDetailRow(
                          'Total',
                          '${global.activeCurrency} ${global.formatPrice(double.parse(formattedRupees))}',
                        ),
                      ],
                    ),
                  ),
                ),
                const SizedBox(height: 24),
              ],
            ),
          ),
        ),
        bottomSheet: Padding(
          padding: EdgeInsets.only(bottom: 3.w, left: 3.w, right: 3.w),
          child: BlocConsumer<PaymentVerifybloc, ApiState<PaymentVerifyModel>>(
            listener: (context, state) {
              if (state is ApiFailure) {
                global.showToastMessage(message: state.error!);
              }
              if (state is ApiSuccess) {
                Get.find<BottomNavController>().navigateToTab(2);
                global.showToastMessage(message: state.data!.message!);
              }
            },
            builder: (context, state) {
              return ElevatedButton(
                onPressed: isloading
                    ? null
                    : () {
                        _showPaymentMethodDialog(context);
                      },
                style: ElevatedButton.styleFrom(
                  minimumSize: const Size.fromHeight(50),
                  shape: RoundedRectangleBorder(
                    borderRadius: BorderRadius.circular(12),
                  ),
                  backgroundColor: isloading ? Colors.grey[400] : null,
                ),
                child: isloading
                    ? const SizedBox(
                        height: 24,
                        width: 24,
                        child: CircularProgressIndicator(
                          color: Colors.white,
                          strokeWidth: 2,
                        ),
                      )
                    : Text(
                        'Pay ${global.activeCurrency} $formattedRupees ',
                        style: TextStyle(fontSize: 17.sp),
                      ),
              );
            },
          ),
        ),
      ),
    );
  }

  Widget _buildDetailRow(dynamic label, dynamic value) {
    return Row(
      mainAxisAlignment: MainAxisAlignment.spaceBetween,
      children: [
        Text(
          label,
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
        Text(
          value.toString(),
          style: Theme.of(context).textTheme.bodyMedium!.copyWith(
            fontSize: 16.sp,
            fontWeight: FontWeight.w500,
            color: AppColors.textColor,
          ),
        ),
      ],
    );
  }

  void _initializeGoogleBilling() {
    log('🔹 _initializeGoogleBilling');
    _gpaymentUtils = GPaymentUtils(
      onMessage: (message) {
        global.showToastMessage(message: message);
        setState(() {
          isloading = false;
        });
      },
      onPurchaseVerified: (purchaseDetails) {
        // Decode into Map
        final Map<String, dynamic> decoded = jsonDecode(
          purchaseDetails.verificationData.localVerificationData,
        );
        final _esim_order_id = verified_esim_order_id;
        final _gateway_order_id = payment_order_id;

        // Platform-specific additional info
        if (Platform.isIOS) {
          // Common log for both platforms

          final transactionID = decoded["transactionId"];
          final originalTransactionId = decoded["originalTransactionId"];

          print('''
          📦 Verify Purchase Info (${Platform.operatingSystem.toUpperCase()}):
            • esim_order_id   : $_esim_order_id  
            • transactionId   : $transactionID
            • originalTransactionId : $originalTransactionId
           
       ''');
          context.read<PaymentVerifybloc>().add(
            PaymentVerifyEvent(
              isTopup: widget.isTopUp,
              iccid: widget.iccid,
              esim_order_id: _esim_order_id,
              transactionId: transactionID,
              originalTransactionId: originalTransactionId,
            ),
          );
        } else if (Platform.isAndroid) {
          context.read<PaymentVerifybloc>().add(
            PaymentVerifyEvent(
              isTopup: widget.isTopUp,
              iccid: widget.iccid,
              esim_order_id: _esim_order_id,
              packageName: decoded["packageName"],
              gateway_order_id: _gateway_order_id,
              purchaseToken: decoded["purchaseToken"],
              googleorderid: decoded["orderId"],
            ),
          );
        }
      },
      onPurchasedError: (purchaseDetails) {
        final Map<String, dynamic> errorData = {
          'status': purchaseDetails.status.toString(),
          'error': {
            'source': purchaseDetails.error?.source,
            'code': purchaseDetails.error?.code,
            'message': purchaseDetails.error?.message,
            'details': purchaseDetails.error?.details,
          },
        };
        final String jsonError = jsonEncode(errorData);
        context.read<RazorpayErrorBloc>().add(
          RazorpayEvent(esimOrderId: esimOrderId, code: jsonError),
        );
      },

      onPurchasePending: () {
        global.showToastMessage(message: 'Payment is pending...');
        setState(() {
          isloading = true;
        });
      },
    );

    _gpaymentUtils.initialize();
  }

  void _setupAlternativeBillingListener() async {
    log('🔹 Setup Alternative Billing Listener');
    if (Platform.isAndroid) {
      final androidAddition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseAndroidPlatformAddition>();

      androidAddition.userChoiceDetailsStream.listen((details) async {});
    } else if (Platform.isIOS) {
      final iosAddition = InAppPurchase.instance
          .getPlatformAddition<InAppPurchaseStoreKitPlatformAddition>();
      iosAddition.showPriceConsentIfNeeded();
    }
  }

  // Payment Method Selection Dialog
  void _showPaymentMethodDialog(BuildContext context) {
    showDialog(
      context: context,
      barrierDismissible: false,
      builder: (BuildContext context) {
        return Dialog(
          shape: RoundedRectangleBorder(
            borderRadius: BorderRadius.circular(20),
          ),
          elevation: 0,
          backgroundColor: Colors.transparent,
          child: Container(
            width: MediaQuery.of(context).size.width * 0.9,
            padding: const EdgeInsets.all(0),
            decoration: BoxDecoration(
              color: Colors.white,
              borderRadius: BorderRadius.circular(20),
              boxShadow: [
                BoxShadow(
                  color: Colors.black.withOpacity(0.1),
                  blurRadius: 20,
                  offset: const Offset(0, 10),
                ),
              ],
            ),
            child: Column(
              mainAxisSize: MainAxisSize.min,
              children: [
                // Header
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.all(24),
                  decoration: BoxDecoration(
                    gradient: LinearGradient(
                      begin: Alignment.topLeft,
                      end: Alignment.bottomRight,
                      colors: [Colors.blue.shade600, Colors.purple.shade600],
                    ),
                    borderRadius: const BorderRadius.only(
                      topLeft: Radius.circular(20),
                      topRight: Radius.circular(20),
                    ),
                  ),
                  child: Column(
                    children: [
                      Icon(
                        Icons.payment_rounded,
                        color: Colors.white,
                        size: 40,
                      ),
                      const SizedBox(height: 2),
                      Text(
                        "Choose Payment Method",
                        style: TextStyle(
                          color: Colors.white,
                          fontSize: 18.sp,
                          fontWeight: FontWeight.w700,
                        ),
                      ),
                      const SizedBox(height: 8),
                      Text(
                        "Select your preferred payment option",
                        style: TextStyle(
                          color: Colors.white.withOpacity(0.9),
                          fontSize: 14.sp,
                        ),
                        textAlign: TextAlign.center,
                      ),
                    ],
                  ),
                ),

                // Payment Options
                Padding(
                  padding: const EdgeInsets.all(24),
                  child: Column(
                    children: [
                      // Google Billing Option
                      _buildPaymentOption(
                        icon: Icons.smartphone_rounded,
                        title: "Google Play Billing",
                        subtitle: "Pay with your Google Account",
                        color: Colors.green,
                        onTap: () {
                          //. fib send payment
                          _onCreateOrderclicked(context,'GpayInAppPurchase');
                        },
                      ),

                      const SizedBox(height: 5),

                      // Divider
                      Row(
                        children: [
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                          Padding(
                            padding: const EdgeInsets.symmetric(horizontal: 12),
                            child: Text(
                              "OR",
                              style: TextStyle(
                                color: Colors.grey.shade500,
                                fontWeight: FontWeight.w600,
                              ),
                            ),
                          ),
                          Expanded(
                            child: Divider(
                              color: Colors.grey.shade300,
                              thickness: 1,
                            ),
                          ),
                        ],
                      ),

                      const SizedBox(height: 5),

                      // FIB Payment Option
                      _buildPaymentOption(
                        icon: Icons.account_balance_rounded,
                        title: "FIB Payment",
                        subtitle: "QR Code & Bank Transfer",
                        color: Colors.blue,
                        onTap: () {
                          _onCreateOrderclicked(context, 'FIB');
                          log('tick tick fib');
                        },
                      ),
                    ],
                  ),
                ),

                // Cancel Button
                Container(
                  width: double.infinity,
                  padding: const EdgeInsets.fromLTRB(24, 0, 24, 10),
                  child: OutlinedButton(
                    onPressed: () {
                      Navigator.of(context).pop();
                    },
                    style: OutlinedButton.styleFrom(
                      padding: const EdgeInsets.symmetric(vertical: 16),
                      shape: RoundedRectangleBorder(
                        borderRadius: BorderRadius.circular(12),
                      ),
                      side: BorderSide(color: Colors.grey.shade300),
                    ),
                    child: Text(
                      "Cancel",
                      style: TextStyle(
                        color: Colors.grey.shade700,
                        fontWeight: FontWeight.w600,
                        fontSize: 16,
                      ),
                    ),
                  ),
                ),
              ],
            ),
          ),
        );
      },
    );
  }

  void _onCreateOrderclicked(BuildContext context , String paymentType) {
    if (widget.isTopUp == true) {
      context.read<OrderNowBloc>().add(
        BuyNowEvent(
          isTopu: true,
          topUpiccid: widget.iccid,
          packageid: widget.packageListInfo.id.toString(),
          orderGatewayType: paymentType,
        ),
      );
    } else {
      context.read<OrderNowBloc>().add(
        BuyNowEvent(
          packageid: widget.packageListInfo.id.toString(),
          orderPrice: formattedRupees.toString(),
          orderGatewayType: paymentType,
        ),
      );
    }
  }

  // Payment Option Widget
  Widget _buildPaymentOption({
    required IconData icon,
    required String title,
    required String subtitle,
    required Color color,
    required VoidCallback onTap,
  }) {
    return Material(
      color: Colors.transparent,
      child: InkWell(
        onTap: onTap,
        borderRadius: BorderRadius.circular(16),
        child: Container(
          padding: const EdgeInsets.all(16),
          decoration: BoxDecoration(
            color: color.withOpacity(0.05),
            borderRadius: BorderRadius.circular(16),
            border: Border.all(color: color.withOpacity(0.2)),
          ),
          child: Row(
            children: [
              Container(
                padding: const EdgeInsets.all(12),
                decoration: BoxDecoration(
                  color: color.withOpacity(0.1),
                  shape: BoxShape.circle,
                ),
                child: Icon(icon, color: color, size: 24),
              ),
              const SizedBox(width: 16),
              Expanded(
                child: Column(
                  crossAxisAlignment: CrossAxisAlignment.start,
                  children: [
                    Text(
                      title,
                      style: TextStyle(
                        fontSize: 16.sp,
                        fontWeight: FontWeight.w600,
                        color: Colors.grey.shade800,
                      ),
                    ),
                    const SizedBox(height: 4),
                    Text(
                      subtitle,
                      style: TextStyle(
                        fontSize: 14.sp,
                        color: Colors.grey.shade600,
                      ),
                    ),
                  ],
                ),
              ),
              Icon(
                Icons.arrow_forward_ios_rounded,
                color: Colors.grey.shade400,
                size: 18,
              ),
            ],
          ),
        ),
      ),
    );
  }
}
