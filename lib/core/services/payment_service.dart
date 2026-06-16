import 'package:flutter/material.dart';
import 'package:flutter_stripe/flutter_stripe.dart';
import 'package:supabase_flutter/supabase_flutter.dart';

class PaymentService {
  Future<void> makePayment({
    required BuildContext context,
    required int amountInCents,
    required String currency,
    Map<String, dynamic>? metadata,
  }) async {
    try {
      // 1. Get client secret from Supabase Edge Function
      debugPrint('>>> PaymentService: calling edge function...');
      final supabase = Supabase.instance.client;
      final res = await supabase.functions.invoke(
        'payment-intent',
        body: {
          'amount': amountInCents,
          'currency': currency,
          'metadata': ?metadata, // ! metadata can be null
        },
      );

      debugPrint('>>> PaymentService: response status = ${res.status}');
      debugPrint('>>> PaymentService: response data = ${res.data}');
      /*print('Publishable key: ${Stripe.publishableKey}');*/
      /*print('Key length: ${Stripe.publishableKey.length}');*/

      final data = res.data;
      final clientSecret = data['clientSecret'];
      debugPrint('>>> PaymentService: clientSecret = $clientSecret');

      if (clientSecret == null) {
        debugPrint('>>> PaymentService: ERROR - clientSecret is null!');
        if (!context.mounted) return;
        ScaffoldMessenger.of(context).showSnackBar(
          const SnackBar(content: Text('Error: Could not create payment')),
        );
        return;
      }

      // 2. Initialize the payment sheet
      debugPrint('>>> PaymentService: initializing payment sheet...');
      await Stripe.instance.initPaymentSheet(
        paymentSheetParameters: SetupPaymentSheetParameters(
          paymentIntentClientSecret: clientSecret,
          merchantDisplayName: 'SewaSiswa',
          style: ThemeMode.system,
        ),
      );

      // 3. Present the sheet
      debugPrint('>>> PaymentService: presenting payment sheet...');
      await Stripe.instance.presentPaymentSheet();

      // 4. If no exception thrown, payment succeeded
      debugPrint('>>> PaymentService: PAYMENT SUCCESSFUL!');
      
      final receiverId = metadata?['receiver_id'] as String?;
      final senderId = supabase.auth.currentUser?.id;
      final amount = (amountInCents / 100).toStringAsFixed(0);
      
      if (receiverId != null) {
        try {
          await supabase.from('notifications').insert({
            'user_id': receiverId,
            'title': 'Payment Received!',
            'message': 'You received a payment of RM $amount.',
            'type': 'payment',
          });
        } catch (_) {}
      }
      
      if (senderId != null) {
        try {
          await supabase.from('notifications').insert({
            'user_id': senderId,
            'title': 'Payment Successful',
            'message': 'Your payment of RM $amount was successful.',
            'type': 'payment',
          });
        } catch (_) {}
      }

      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(const SnackBar(content: Text('Payment successful!')));
    } on StripeException catch (e) {
      debugPrint(
        '>>> PaymentService: StripeException = ${e.error.localizedMessage}',
      );
      if (!context.mounted) return;
      ScaffoldMessenger.of(context).showSnackBar(
        SnackBar(content: Text('Payment failed: ${e.error.localizedMessage}')),
      );
    } catch (e) {
      debugPrint('>>> PaymentService: UNEXPECTED ERROR = $e');
      if (!context.mounted) return;
      ScaffoldMessenger.of(
        context,
      ).showSnackBar(SnackBar(content: Text('Error: $e')));
    }
  }
}
