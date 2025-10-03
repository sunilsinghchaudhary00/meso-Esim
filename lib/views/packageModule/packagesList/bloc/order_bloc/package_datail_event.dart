import 'package:esimtel/core/bloc/api_event.dart';

class BuyNowEvent extends ApiEvent {
  final String? packageid;
  final bool? isTopu;
  final String? topUpiccid;
  final String? orderPrice;
  final String? orderGatewayType;


  const BuyNowEvent({
    required this.packageid,
    this.isTopu = false,
    this.topUpiccid,
    this.orderPrice,
    this.orderGatewayType
  });
}
