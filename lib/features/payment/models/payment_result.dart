// lib/features/payment/models/payment_result.dart
//
// Unified result returned by EVERY PaymentProvider implementation.
// The PaymentController and PaymentScreen only ever see this type —
// never anything Stripe- or Duffel-specific.

enum PaymentStatus {
  idle,
  processing,
  success,
  failure,
  cancelled,
  pending,
}

class PaymentResult {
  const PaymentResult({
    required this.status,
    this.transactionId,
    this.bookingReference,
    this.errorMessage,
    this.errorCode,
    this.providerName,
    this.metadata = const {},
  });

  final PaymentStatus status;

  /// Provider-level transaction / payment-intent ID.
  final String? transactionId;

  /// Confirmed booking reference (Duffel order ID, PNR from your backend, etc.)
  final String? bookingReference;

  final String? errorMessage;
  final String? errorCode;

  /// Which provider processed this payment ('stripe' | 'duffel').
  final String? providerName;

  /// Extra provider-specific data the success screen can optionally display.
  final Map<String, dynamic> metadata;

  // ── Convenience ──────────────────────────────────────────────────────────
  bool get isSuccess    => status == PaymentStatus.success;
  bool get isFailure    => status == PaymentStatus.failure;
  bool get isCancelled  => status == PaymentStatus.cancelled;
  bool get isPending    => status == PaymentStatus.pending;
  bool get isProcessing => status == PaymentStatus.processing;

  // ── Named constructors ───────────────────────────────────────────────────
  factory PaymentResult.success({
    required String transactionId,
    String? bookingReference,
    String? providerName,
    Map<String, dynamic> metadata = const {},
  }) =>
      PaymentResult(
        status: PaymentStatus.success,
        transactionId: transactionId,
        bookingReference: bookingReference,
        providerName: providerName,
        metadata: metadata,
      );

  factory PaymentResult.failure({
    required String errorMessage,
    String? errorCode,
    String? providerName,
  }) =>
      PaymentResult(
        status: PaymentStatus.failure,
        errorMessage: errorMessage,
        errorCode: errorCode,
        providerName: providerName,
      );

  factory PaymentResult.cancelled({String? providerName}) => PaymentResult(
        status: PaymentStatus.cancelled,
        providerName: providerName,
      );

  factory PaymentResult.pending({
    String? transactionId,
    String? providerName,
  }) =>
      PaymentResult(
        status: PaymentStatus.pending,
        transactionId: transactionId,
        providerName: providerName,
      );

  @override
  String toString() =>
      'PaymentResult(status:$status, txId:$transactionId, '
      'ref:$bookingReference, error:$errorMessage, provider:$providerName)';
}
