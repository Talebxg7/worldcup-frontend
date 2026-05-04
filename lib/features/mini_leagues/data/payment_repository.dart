import '../../../core/network/api_client.dart';

class RoomPaymentSession {
  final int paymentId;
  final String provider;
  final int amountCents;
  final String? checkoutUrl;
  final String? paymentIntent;
  final String? ephemeralKey;
  final String? customer;

  const RoomPaymentSession({
    required this.paymentId,
    required this.provider,
    required this.amountCents,
    required this.checkoutUrl,
    this.paymentIntent,
    this.ephemeralKey,
    this.customer,
  });

  factory RoomPaymentSession.fromJson(Map<String, dynamic> json) {
    return RoomPaymentSession(
      paymentId: (json['payment_id'] as num?)?.toInt() ?? 0,
      provider: (json['provider'] as String?) ?? '',
      amountCents: (json['amount_cents'] as num?)?.toInt() ?? 0,
      checkoutUrl: json['checkout_url'] as String?,
      paymentIntent: json['payment_intent'] as String?,
      ephemeralKey: json['ephemeral_key'] as String?,
      customer: json['customer'] as String?,
    );
  }
}

class RoomPaymentRepository {
  Future<RoomPaymentSession> createRoomPayment({
    required String provider,
  }) async {
    final res = await ApiClient.instance.post(
      '/payments/create-room-payment',
      data: {'provider': provider},
    );
    return RoomPaymentSession.fromJson(Map<String, dynamic>.from(res.data as Map));
  }

  Future<bool> confirmRoomPayment(int paymentId) async {
    final res = await ApiClient.instance.post(
      '/payments/confirm-room-payment',
      data: {'payment_id': paymentId},
    );
    final json = Map<String, dynamic>.from(res.data as Map);
    return (json['status'] as String?) == 'paid';
  }
}
