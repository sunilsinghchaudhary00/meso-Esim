import 'dart:developer';
import 'dart:typed_data';
import 'package:fib_iraq_payment/fib_iraq_payment.dart';

/// A service wrapper for FIB Payment
class FIBPaymentService {
  final FIBService _fibService = FIBService();

  /// Configure the service with credentials
  void init({
    required String clientId,
    required String clientSecret,
    String mode = "stage", // stage | dev | prod
  }) {
    log('fib initialized');
    _fibService.clientId = clientId;
    _fibService.clientSecret = clientSecret;
    _fibService.mode = mode;
  }

  /// Create a new payment
  /// 
  /// [amount] = the amount to be paid
  /// [description] = description shown in FIB app
  /// [callbackUrl] = your backend endpoint that FIB will notify after payment
  Future<Map<String, dynamic>> createPayment({
    required int amount,
    required String description,
    required String callbackUrl,
  }) async {
    final payment = await _fibService.createPayment(
      amount,
      description,
      callbackUrl,
    );
    return payment;
  }

  /// Get Payment QR Code as [Uint8List]
  Uint8List? getQrImage(String base64Data) {
    try {
      return _fibService.base64ToImage(base64Data.split(',')[1]);
    } catch (e) {
      return null;
    }
  }

  /// Check status of a payment
  Future<Map<String, dynamic>> checkPaymentStatus(String paymentId) async {
    final status = await _fibService.checkPaymentStatus(paymentId);
    return status;
  }
}
