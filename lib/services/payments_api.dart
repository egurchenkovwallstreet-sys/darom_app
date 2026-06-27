import 'dart:convert';

import 'package:http/http.dart' as http;

import 'api_config.dart';
import 'auth_headers.dart';

class RobokassaPaymentForm {
  final String action;
  final String method;
  final Map<String, String> fields;

  const RobokassaPaymentForm({
    required this.action,
    required this.method,
    required this.fields,
  });

  factory RobokassaPaymentForm.fromJson(Map<String, dynamic> json) {
    final rawFields = json['fields'];
    final fields = <String, String>{};
    if (rawFields is Map) {
      rawFields.forEach((key, value) {
        fields['$key'] = '$value';
      });
    }
    return RobokassaPaymentForm(
      action: json['action'] as String? ?? '',
      method: (json['method'] as String? ?? 'POST').toUpperCase(),
      fields: fields,
    );
  }
}

class PaymentCreateResult {
  final bool mock;
  final int? invId;
  final int amountRub;
  final String? paymentUrl;
  final RobokassaPaymentForm? paymentForm;
  final String? message;

  const PaymentCreateResult({
    required this.mock,
    required this.amountRub,
    this.invId,
    this.paymentUrl,
    this.paymentForm,
    this.message,
  });

  factory PaymentCreateResult.fromJson(Map<String, dynamic> json) {
    final formJson = json['payment_form'];
    return PaymentCreateResult(
      mock: json['mock'] as bool? ?? false,
      invId: json['inv_id'] as int?,
      amountRub: json['amount_rub'] as int? ?? 0,
      paymentUrl: json['payment_url'] as String?,
      paymentForm: formJson is Map<String, dynamic>
          ? RobokassaPaymentForm.fromJson(formJson)
          : null,
      message: json['message'] as String?,
    );
  }
}

class PaymentStatusResult {
  final String status;
  final String productType;
  final int amountRub;

  const PaymentStatusResult({
    required this.status,
    required this.productType,
    required this.amountRub,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> json) {
    return PaymentStatusResult(
      status: json['status'] as String? ?? 'pending',
      productType: json['product_type'] as String? ?? '',
      amountRub: json['amount_rub'] as int? ?? 0,
    );
  }

  bool get isPaid => status == 'paid';
}

class PaymentsApi {
  PaymentsApi({http.Client? client}) : _client = client ?? http.Client();

  final http.Client _client;

  Future<PaymentCreateResult> createPayment({
    required String phone,
    required String productType,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/create');

    final response = await _client
        .post(
          uri,
          headers: await jsonAuthHeaders(),
          body: jsonEncode({
            'phone': phone,
            'product_type': productType,
          }),
        )
        .timeout(const Duration(seconds: 15));

    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw PaymentsApiException(body['error'] as String? ?? 'Не удалось создать оплату');
    }

    return PaymentCreateResult.fromJson(body);
  }

  Future<PaymentStatusResult> fetchStatus({
    required int invId,
    String? phone,
  }) async {
    final uri = Uri.parse('${ApiConfig.baseUrl}/api/payments/status').replace(
      queryParameters: {
        'inv_id': '$invId',
        if (phone != null && phone.isNotEmpty) 'phone': phone,
      },
    );

    final response = await _client.get(uri, headers: await authHeaders()).timeout(const Duration(seconds: 10));
    final body = jsonDecode(response.body) as Map<String, dynamic>;

    if (response.statusCode != 200) {
      throw PaymentsApiException(body['error'] as String? ?? 'Не удалось проверить оплату');
    }

    return PaymentStatusResult.fromJson(body);
  }

  void dispose() => _client.close();
}

class PaymentsApiException implements Exception {
  PaymentsApiException(this.message);

  final String message;

  @override
  String toString() => message;
}
