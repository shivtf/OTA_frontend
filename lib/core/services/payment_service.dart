import '../network/api_client.dart';

class PaymentService {
  final _client = ApiClient.instance;

  // ── POST /payments/initiate ─────────────────────────────────────
  /// Returns Stripe checkout session URL to open in browser
  /// Response: { provider, sessionId, sessionUrl, publishableKey }
  Future<PaymentSession> initiatePayment(
    String bookingId, {
    List<Map<String, dynamic>> selectedServices = const [],
  }) async {
    final body = <String, dynamic>{'bookingId': bookingId};

    if (selectedServices.isNotEmpty) {
      // Send only what the backend needs: id, total_amount, total_currency
      body['selectedServices'] = selectedServices
          .map((s) => {
                'id': s['serviceId'],
                'total_amount': s['amount']?.toString(),
                'total_currency': s['currency'] ?? 'USD',
              })
          .toList();
    }

    final res = await _client.post('/payments/initiate', body, auth: true);

    // Backend now returns pricing breakdown — store it for UI use
    return PaymentSession.fromJson(res['data'] as Map<String, dynamic>);
  }

  // ── POST /payments/confirm ──────────────────────────────────────
  /// Confirms payment after user completes Stripe checkout.
  /// [selectedSeatServiceIds] are passed as a safety fallback — the backend
  /// also reads them from the DB (saved at init time), but sending them here
  /// ensures they are used even if the DB write was delayed or missed.
  /// Response: { bookingId, bookingRef, status }
  Future<PaymentConfirmResult> confirmPayment({
    required String bookingId,
    required String sessionId,
    List<String> selectedSeatServiceIds = const [],
  }) async {
    final body = <String, dynamic>{
      'bookingId': bookingId,
      'sessionId': sessionId,
    };
    if (selectedSeatServiceIds.isNotEmpty) {
      body['selectedServices'] = selectedSeatServiceIds;
    }
    final res = await _client.post('/payments/confirm', body, auth: true);
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
  final double? baseFare; // ← new
  final double? seatUpgrade; // ← new
  final double? total; // ← new
  final String? pricingCurrency; // ← new

  PaymentSession({
    required this.provider,
    required this.sessionId,
    required this.sessionUrl,
    this.publishableKey,
    this.baseFare,
    this.seatUpgrade,
    this.total,
    this.pricingCurrency,
  });

  factory PaymentSession.fromJson(Map<String, dynamic> j) {
    final pricing = j['pricing'] as Map<String, dynamic>?;
    return PaymentSession(
      provider: j['provider'] as String? ?? 'stripe',
      sessionId: j['sessionId'] as String? ?? '',
      sessionUrl: j['sessionUrl'] as String? ?? '',
      publishableKey: j['publishableKey'] as String?,
      baseFare: (pricing?['baseFare'] as num?)?.toDouble(),
      seatUpgrade: (pricing?['seatUpgrade'] as num?)?.toDouble(),
      total: (pricing?['total'] as num?)?.toDouble(),
      pricingCurrency: pricing?['currency'] as String?,
    );
  }
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
