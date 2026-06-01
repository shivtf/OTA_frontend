// lib/core/config/app_config.dart
//
// Central application configuration.
// ─────────────────────────────────────────────────────────────────────────────
// SWITCHING PROVIDERS:
//   Change paymentGateway = PaymentGateway.duffel  ← ONLY this one line.
//   Nothing in the UI or business logic changes.
//
// In CI / production, drive from --dart-define:
//   flutter run --dart-define=PAYMENT_GATEWAY=duffel

enum PaymentGateway { stripe, duffel }

class AppConfig {
  AppConfig._();

  // ── 🔑 THE ONE LINE YOU CHANGE TO SWITCH PROVIDERS ────────────────────────
  //
  // Option A – hard-code for local dev:
  //   static PaymentGateway get paymentGateway => PaymentGateway.stripe;
  //
  // Option B – drive from --dart-define (recommended for CI/CD):
  //   flutter run --dart-define=PAYMENT_GATEWAY=duffel

  static PaymentGateway get paymentGateway {
    const raw = String.fromEnvironment(
      'PAYMENT_GATEWAY',
      defaultValue: 'stripe',
    );
    return raw.toLowerCase() == 'duffel'
        ? PaymentGateway.duffel
        : PaymentGateway.stripe;
  }

  // ── Stripe ─────────────────────────────────────────────────────────────
  static const String stripePublishableKey = String.fromEnvironment(
    'STRIPE_PUBLISHABLE_KEY',
    defaultValue: 'pk_test_your_key_here',
  );

  // ── Backend ────────────────────────────────────────────────────────────
  static const String backendBaseUrl = String.fromEnvironment(
    'BACKEND_BASE_URL',
    defaultValue: 'https://ota-jnuy.onrender.com/api/v1',
  );

  // ── Duffel ─────────────────────────────────────────────────────────────
  static const String duffelApiKey = String.fromEnvironment(
    'DUFFEL_API_KEY',
    defaultValue: 'duffel_test_your_key_here',
  );
  static const String duffelApiBase = String.fromEnvironment(
    'DUFFEL_API_BASE',
    defaultValue: 'https://api.duffel.com',
  );

  // ── Feature flags ──────────────────────────────────────────────────────
  static const bool enablePaymentRetry = bool.fromEnvironment(
    'ENABLE_PAYMENT_RETRY',
    defaultValue: true,
  );
  static const int maxRetryAttempts = int.fromEnvironment(
    'MAX_RETRY_ATTEMPTS',
    defaultValue: 3,
  );
}
