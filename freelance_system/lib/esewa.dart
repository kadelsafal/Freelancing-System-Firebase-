import 'dart:convert';
import 'package:flutter/material.dart';
import 'package:http/http.dart' as http;
import 'package:esewa_flutter_sdk/esewa_config.dart';
import 'package:esewa_flutter_sdk/esewa_flutter_sdk.dart';
import 'package:esewa_flutter_sdk/esewa_payment.dart';
import 'package:esewa_flutter_sdk/esewa_payment_success_result.dart';

class EsewaService {
  static const String clientId =
      'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R';
  static const String secretId = 'BhwIWQQADhIYSxILExMcAgFXFhcOBwAKBgAXEQ==';
  static const String merchantCode =
      'JB0BBQ4aD0UqIThFJwAKBgAXEUkEGQUBBAwdOgABHD4DChwUAB0R'; // Usually same as clientId

  void pay() {
    try {
      EsewaFlutterSdk.initPayment(
        esewaConfig: EsewaConfig(
          environment: Environment.test, // Change to Environment.live for prod
          clientId: clientId,
          secretId: secretId,
        ),
        esewaPayment: EsewaPayment(
          productId: "1d71jd81",
          productName: "Product One",
          productPrice: "20",
          callbackUrl: "", // optional
        ),
        onPaymentSuccess: (EsewaPaymentSuccessResult data) {
          debugPrint(":::SUCCESS::: => $data");
          verifyTransactionStatus(data);
        },
        onPaymentFailure: (data) {
          debugPrint(":::FAILURE::: => $data");
        },
        onPaymentCancellation: (data) {
          debugPrint(":::CANCELLATION::: => $data");
        },
      );
    } catch (e) {
      debugPrint("EXCEPTION: ${e.toString()}");
    }
  }

  Future<void> verifyTransactionStatus(EsewaPaymentSuccessResult result) async {
    final refId = result.refId ?? '';
    final productId = result.productId ?? '';
    final amount = result.totalAmount ?? '';

    try {
      final url = Uri.parse(
          'https://rc.esewa.com.np/mobile/transaction?txnRefId=$refId'); // for test. Remove 'rc' in production
      final response = await http.get(url);

      if (response.statusCode == 200) {
        final data = jsonDecode(response.body);
        final status = data[0]["transactionDetails"]["status"];
        final message = data[0]["message"]["successMessage"];

        if (status == "COMPLETE") {
          debugPrint("✅ Transaction Verified: $message");
          // TODO: Proceed with order confirmation or DB update
        } else {
          debugPrint("❌ Verification Failed: $status");
        }
      } else {
        debugPrint("❌ HTTP Error: ${response.statusCode}");
      }
    } catch (e) {
      debugPrint("❌ Exception in verification: $e");
    }
  }
}

Future<void> verifyUsingProductIdAndAmount(
    String productId, String amount) async {
  final url = Uri.parse(
      'https://rc.esewa.com.np/mobile/transaction?productId=$productId&amount=$amount');
  final response = await http.get(url);

  if (response.statusCode == 200) {
    final data = jsonDecode(response.body);
    final status = data[0]["transactionDetails"]["status"];
    debugPrint("Status: $status");
  } else {
    debugPrint("API Error: ${response.statusCode}");
  }
}
