import 'dart:developer';
import 'dart:io';
import 'package:dio/dio.dart';
import 'package:flutter_bloc/flutter_bloc.dart';
import 'package:esimtel/core/bloc/api_bloc.dart';
import 'package:esimtel/core/bloc/api_state.dart';
import 'package:esimtel/utills/api_end_points.dart';
import 'package:esimtel/utills/services/ApiService.dart';
import '../model/paymentverifyModel.dart';
import 'payment_verify_event.dart';

class PaymentVerifybloc
    extends
        ApiBloc<
          PaymentVerifyEvent,
          ApiState<PaymentVerifyModel>,
          PaymentVerifyModel
        > {
  final ApiService apiService;

  PaymentVerifybloc(this.apiService) : super(ApiInitial()) {
    on<PaymentVerifyEvent>(_onPaymentVerified);
  }

  Future<void> _onPaymentVerified(
    PaymentVerifyEvent event,
    Emitter<ApiState<PaymentVerifyModel>> emit,
  ) async {
    emit(loadingState());
    try {
      final result = await executeApiCall(event);
      emit(successState(result));
    } catch (e) {
      emit(errorState(e.toString()));
    }
  }

  @override
  Future<PaymentVerifyModel> executeApiCall(PaymentVerifyEvent event) async {
    Map<String, dynamic> parameterbody = {};
    if (Platform.isIOS) {
      //IOS
      parameterbody["order_id"] = event.esim_order_id;
      parameterbody["fromApp"] = 'ios';
      parameterbody["transactionId"] = event.transactionId;
      parameterbody["originalTransactionId"] = event.originalTransactionId;
    } else {
      //ANDROID
      parameterbody["gateway_order_id"] = event.gateway_order_id;
      parameterbody["order_id"] = event.esim_order_id;
      parameterbody["fromApp"] = 'android';
      parameterbody["package_name"] = event.packageName;
      parameterbody["purchase_token"] = event.purchaseToken;
      parameterbody["google_order_id"] = event.googleorderid;
    }
    //IF TOPUP
    if (event.isTopup == true) {
      parameterbody["iccid"] = event.iccid;
    }
    log('Payment Verify body: $parameterbody');

    try {
      final response = await apiService.post(
        ApiEndPoints.PAYMENTVERIFY,
        data: parameterbody,
      );
      print('Payment Verify Response: $response');

      return PaymentVerifyModel.fromJson(response);
    } on DioException catch (e) {
      throw e.message ?? 'Failed to fetch _onPaymentVerified';
    } catch (e) {
      log('erorr is $e');
      throw 'Unknown error occurred';
    }
  }

  @override
  ApiState<PaymentVerifyModel> loadingState() => ApiLoading();

  @override
  ApiState<PaymentVerifyModel> successState(PaymentVerifyModel response) =>
      ApiSuccess(response);

  @override
  ApiState<PaymentVerifyModel> errorState(String error) => ApiFailure(error);
}
