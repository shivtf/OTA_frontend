import '../network/api_client.dart';

class PaymentService {
  final _client = ApiClient.instance;

  // ── POST /payments/initiate ─────────────────────────────────────
  /// Returns Stripe checkout session URL to open in browser
  /// Response: { provider, sessionId, sessionUrl, publishableKey }
  Future<PaymentSession> initiatePayment(String bookingId) async {
    final res = await _client.post(
        '/payments/initiate',
        {
          'bookingId': bookingId,
        },
        auth: true);
    return PaymentSession.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /payments/confirm ──────────────────────────────────────
  /// Confirms payment after user completes Stripe checkout
  /// Response: { bookingId, bookingRef, status }
  Future<PaymentConfirmResult> confirmPayment({
    required String bookingId,
    required String sessionId,
  }) async {
    final res = await _client.post(
        '/payments/confirm',
        {
          'bookingId': bookingId,
          'sessionId': sessionId,
        },
        auth: true);
    return PaymentConfirmResult.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── GET /payments/:bookingId/status ─────────────────────────────
  /// Response: { bookingId, bookingRef, bookStatus, payment, refund }
  Future<PaymentStatusResult> getPaymentStatus(String bookingId) async {
    final res = await _client.get('/payments/$bookingId/status', auth: true);
    return PaymentStatusResult.fromJson(res['data'] as Map<String, dynamic>);
  }
}

class PaymentSession {
  final String provider;
  final String sessionId;
  final String sessionUrl;
  final String? publishableKey;

  PaymentSession({
    required this.provider,
    required this.sessionId,
    required this.sessionUrl,
    this.publishableKey,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> j) => PaymentSession(
        provider: j['provider'] as String? ?? 'stripe',
        sessionId: j['sessionId'] as String? ?? '',
        sessionUrl: j['sessionUrl'] as String? ?? '',
        publishableKey: j['publishableKey'] as String?,
      );
}

class PaymentConfirmResult {
  final String bookingId;
  final String bookingRef;
  final String status; // CONFIRMED

  PaymentConfirmResult({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
  });

  bool get isConfirmed => status == 'CONFIRMED';

  factory PaymentConfirmResult.fromJson(Map<String, dynamic> j) =>
      PaymentConfirmResult(
        bookingId: j['bookingId'] as String? ?? '',
        bookingRef: j['bookingRef'] as String? ?? '',
        status: j['status'] as String? ?? '',
      );
}

class PaymentStatusResult {
  final String bookingId;
  final String bookingRef;
  final String bookStatus;

  PaymentStatusResult({
    required this.bookingId,
    required this.bookingRef,
    required this.bookStatus,
  });

  factory PaymentStatusResult.fromJson(Map<String, dynamic> j) =>
      PaymentStatusResult(
        bookingId: j['bookingId'] as String? ?? '',
        bookingRef: j['bookingRef'] as String? ?? '',
        bookStatus: j['bookStatus'] as String? ?? '',
      );
}
