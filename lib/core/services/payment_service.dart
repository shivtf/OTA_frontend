// lib/core/services/payment_service.dart
import '../network/api_client.dart';

class PaymentService {
  final _client = ApiClient.instance;

  // ── POST /payments/initiate ─────────────────────────────────────
  /// Creates a Stripe payment intent for a given bookingId.
  /// Returns { clientSecret, bookingId, amount, currency }
  Future<PaymentIntent> initiatePayment(String bookingId) async {
    final res = await _client.post('/payments/initiate', {
      'bookingId': bookingId,
    }, auth: true);
    return PaymentIntent.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /payments/confirm ─────────────────────────────────────
  /// Confirms payment and triggers booking confirmation.
  Future<PaymentResult> confirmPayment(String bookingId) async {
    final res = await _client.post('/payments/confirm', {
      'bookingId': bookingId,
    }, auth: true);
    return PaymentResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /payments/:bookingId/refund ────────────────────────────
  Future<PaymentResult> refundPayment(String bookingId) async {
    final res = await _client.post(
      '/payments/$bookingId/refund',
      {},
      auth: true,
    );
    return PaymentResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /payments/:bookingId/status ─────────────────────────────
  Future<PaymentStatus> getPaymentStatus(String bookingId) async {
    final res = await _client.get('/payments/$bookingId/status', auth: true);
    return PaymentStatus.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class PaymentIntent {
  final String clientSecret;
  final String bookingId;
  final double amount;
  final String currency;

  PaymentIntent({
    required this.clientSecret,
    required this.bookingId,
    required this.amount,
    required this.currency,
  });

  factory PaymentIntent.fromJson(Map<String, dynamic> j) => PaymentIntent(
    clientSecret: j['clientSecret'] as String? ?? '',
    bookingId: j['bookingId'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble() ?? 0.0,
    currency: j['currency'] as String? ?? 'USD',
  );
}

class PaymentResult {
  final String status;
  final String? refundId;
  final String? message;
  final Map<String, dynamic> raw;

  PaymentResult({
    required this.status,
    this.refundId,
    this.message,
    required this.raw,
  });

  factory PaymentResult.fromJson(Map<String, dynamic> j) => PaymentResult(
    status: j['status'] as String? ?? '',
    refundId: j['refundId'] as String?,
    message: j['message'] as String?,
    raw: j,
  );
}

class PaymentStatus {
  final String status;
  final double? amount;
  final String? currency;
  final String bookingId;

  PaymentStatus({
    required this.status,
    this.amount,
    this.currency,
    required this.bookingId,
  });

  factory PaymentStatus.fromJson(Map<String, dynamic> j) => PaymentStatus(
    status: j['status'] as String? ?? '',
    amount: (j['amount'] as num?)?.toDouble(),
    currency: j['currency'] as String?,
    bookingId: j['bookingId'] as String? ?? '',
  );
}
