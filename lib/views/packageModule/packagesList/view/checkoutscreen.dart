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
import 'package:sizer/sizer.dart';
import 'package:skeletonizer/skeletonizer.dart';
import 'package:url_launcher/url_launcher.dart';
import '../bloc/order_bloc/package_datail_event.dart';
import '../bloc/payment_verify_bloc/bloc/payment_verify_bloc.dart';
import '../bloc/payment_verify_bloc/bloc/payment_verify_event.dart';
import '../bloc/payment_verify_bloc/model/paymentverifyModel.dart';
import '../bloc/razorpay_error_bloc/razorpay_error_bloc.dart';
import '../bloc/razorpay_error_bloc/razorpay_error_event.dart';

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
                final fibLink =
                    state.data?.data?.gatewayResponse?.personalAppLink ?? '';
                log('fib link is $fibLink');
                if (fibLink.isNotEmpty) {
                  await launchUrl(
                    Uri.parse(fibLink),
                    mode: LaunchMode.externalApplication,
                  );
                } else {
                  log("Payment URL is empty");
                  //show toast
                  global.showToastMessage(message: 'Payment URL not Found');
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
                        // _showPaymentMethodDialog(context);
                        _onCreateOrderclicked(context, 'FIB');
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

  void _onCreateOrderclicked(BuildContext context, String paymentType) {
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
