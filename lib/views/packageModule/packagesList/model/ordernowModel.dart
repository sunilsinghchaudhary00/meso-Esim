import 'dart:convert';

OrderNowModel orderNowModelFromJson(String str) => OrderNowModel.fromJson(json.decode(str));

String orderNowModelToJson(OrderNowModel data) => json.encode(data.toJson());

class OrderNowModel {
  bool? success;
  Data? data;
  String? message;

  OrderNowModel({
    this.success,
    this.data,
    this.message,
  });

  factory OrderNowModel.fromJson(Map<String, dynamic> json) => OrderNowModel(
        success: json["success"],
        data: json["data"] == null ? null : Data.fromJson(json["data"]),
        message: json["message"],
      );

  Map<String, dynamic> toJson() => {
        "success": success,
        "data": data?.toJson(),
        "message": message,
      };
}

class Data {
  int? esimOrderId;
  String? gatewayOrderId;
  dynamic amount;
  String? currency;
  String? gatewayKey;
  String? name;
  String? description;
  String? phone;
  String? email;
  dynamic iccid;
  String? paymentGateway;
  GatewayResponse? gatewayResponse;

  Data({
    this.esimOrderId,
    this.gatewayOrderId,
    this.amount,
    this.currency,
    this.gatewayKey,
    this.name,
    this.description,
    this.phone,
    this.email,
    this.iccid,
    this.paymentGateway,
    this.gatewayResponse,
  });

  factory Data.fromJson(Map<String, dynamic> json) => Data(
        esimOrderId: json["esim_order_id"],
        gatewayOrderId: json["gateway_order_id"],
        amount: json["amount"],
        currency: json["currency"],
        gatewayKey: json["gateway_key"],
        name: json["name"],
        description: json["description"],
        phone: json["phone"],
        email: json["email"],
        iccid: json["iccid"],
        paymentGateway: json["payment_gateway"],
        gatewayResponse: json["gateway_response"] == null
            ? null
            : GatewayResponse.fromJson(json["gateway_response"]),
      );

  Map<String, dynamic> toJson() => {
        "esim_order_id": esimOrderId,
        "gateway_order_id": gatewayOrderId,
        "amount": amount,
        "currency": currency,
        "gateway_key": gatewayKey,
        "name": name,
        "description": description,
        "phone": phone,
        "email": email,
        "iccid": iccid,
        "payment_gateway": paymentGateway,
        "gateway_response": gatewayResponse?.toJson(),
      };
}

class GatewayResponse {
  String? qrCode;
  String? readableCode;
  String? businessAppLink;
  String? corporateAppLink;
  String? validUntil;
  String? personalAppLink;

  GatewayResponse({
    this.qrCode,
    this.readableCode,
    this.businessAppLink,
    this.corporateAppLink,
    this.validUntil,
    this.personalAppLink,
  });

  factory GatewayResponse.fromJson(Map<String, dynamic> json) => GatewayResponse(
        qrCode: json["qrCode"],
        readableCode: json["readableCode"],
        businessAppLink: json["businessAppLink"],
        corporateAppLink: json["corporateAppLink"],
        validUntil: json["validUntil"],
        personalAppLink: json["personalAppLink"],
      );

  Map<String, dynamic> toJson() => {
        "qrCode": qrCode,
        "readableCode": readableCode,
        "businessAppLink": businessAppLink,
        "corporateAppLink": corporateAppLink,
        "validUntil": validUntil,
        "personalAppLink" : personalAppLink
      };
}
