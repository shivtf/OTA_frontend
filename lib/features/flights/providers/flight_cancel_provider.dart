// lib/features/flights/providers/flight_cancel_provider.dart

import 'package:flutter/foundation.dart';
import '../../../core/network/api_client.dart';

// ── Refund result model ───────────────────────────────────────────────────────

class CancelRefund {
  final double amount;
  final String currency;
  final String? refundTo;
  final String instructions;
  final bool autoRefundInitiated;
  final String? stripeRefundStatus;

  const CancelRefund({
    required this.amount,
    required this.currency,
    this.refundTo,
    required this.instructions,
    required this.autoRefundInitiated,
    this.stripeRefundStatus,
  });

  factory CancelRefund.fromJson(Map<String, dynamic> json) => CancelRefund(
    amount: (json['amount'] as num?)?.toDouble() ?? 0.0,
    currency: json['currency'] as String? ?? 'USD',
    refundTo: json['refundTo'] as String?,
    instructions: json['instructions'] as String? ?? '',
    autoRefundInitiated: json['autoRefundInitiated'] as bool? ?? false,
    stripeRefundStatus: json['stripeRefundStatus'] as String?,
  );

  bool get hasRefund => amount > 0;
}

class CancelResult {
  final String bookingId;
  final String bookingRef;
  final String status;
  final CancelRefund refund;

  const CancelResult({
    required this.bookingId,
    required this.bookingRef,
    required this.status,
    required this.refund,
  });

  factory CancelResult.fromJson(Map<String, dynamic> json) => CancelResult(
    bookingId: json['bookingId'] as String,
    bookingRef: json['bookingRef'] as String,
    status: json['status'] as String,
    refund: CancelRefund.fromJson(json['refund'] as Map<String, dynamic>),
  );
}

// ── Provider ─────────────────────────────────────────────────────────────────

enum CancelStep { idle, loading, success, failed }

class FlightCancelProvider extends ChangeNotifier {
  final _client = ApiClient.instance;

  CancelStep _step = CancelStep.idle;
  String? _error;
  CancelResult? _result;

  CancelStep get step => _step;
  String? get error => _error;
  CancelResult? get result => _result;
  bool get isLoading => _step == CancelStep.loading;

  // ── POST /flights/bookings/:bookingId/cancel ──────────────────────────────
  Future<bool> cancelBooking({
    required String bookingId,
    required String reason,
  }) async {
    _step = CancelStep.loading;
    _error = null;
    _result = null;
    notifyListeners();

    try {
      final res = await _client.post(
        '/flights/bookings/$bookingId/cancel',
        {'reason': reason},
        auth: true,
      );

      _result = CancelResult.fromJson(res['data'] as Map<String, dynamic>);
      _step = CancelStep.success;
      notifyListeners();
      return true;
    } on ApiException catch (e) {
      _error = e.message;
      _step = CancelStep.failed;
      notifyListeners();
      return false;
    } catch (_) {
      _error = 'Cancellation failed. Please check your connection and try again.';
      _step = CancelStep.failed;
      notifyListeners();
      return false;
    }
  }

  void reset() {
    _step = CancelStep.idle;
    _error = null;
    _result = null;
    notifyListeners();
  }
}