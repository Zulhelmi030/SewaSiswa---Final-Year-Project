import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import Stripe from "https://esm.sh/stripe@14.0.0?target=deno"
import { createClient } from "https://esm.sh/@supabase/supabase-js@2"

const stripe = new Stripe(Deno.env.get('STRIPE_SECRET_KEY') as string, {
  apiVersion: '2023-10-16',
  httpClient: Stripe.createFetchHttpClient(),
})

const cryptoProvider = Stripe.createSubtleCryptoProvider()

serve(async (request) => {
  const signature = request.headers.get('Stripe-Signature')

  // First step is to verify the event. The .text() method must be used to provide the
  // raw body to Stripe's signature verification
  const body = await request.text()
  let receivedEvent
  try {
    receivedEvent = await stripe.webhooks.constructEventAsync(
      body,
      signature!,
      Deno.env.get('STRIPE_WEBHOOK_SECRET') as string,
      undefined,
      cryptoProvider
    )
  } catch (err: any) {
    console.error(`Webhook Error: ${err.message}`)
    return new Response(err.message, { status: 400 })
  }

  console.log(`🔔 Event received: ${receivedEvent.type}`)

  if (receivedEvent.type === 'payment_intent.succeeded') {
    const paymentIntent = receivedEvent.data.object as Stripe.PaymentIntent
    const metadata = paymentIntent.metadata

    console.log('Payment succeeded with metadata:', metadata)

    // Check if we have the necessary metadata
    if (metadata && metadata.rental_id && metadata.sender_id && metadata.receiver_id) {
      
      // Initialize Supabase admin client to bypass Row Level Security
      const supabaseAdmin = createClient(
        Deno.env.get('SUPABASE_URL') ?? '',
        Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
      )

      try {
        // Insert the payment record into the database
        const { error } = await supabaseAdmin
          .from('payments')
          .insert({
            rental_id: metadata.rental_id,
            sender_id: metadata.sender_id,
            receiver_id: metadata.receiver_id,
            amount: paymentIntent.amount / 100.0, // Convert from cents to ringgit/dollars
            status: 'paid', // Mark it directly as paid since the webhook confirmed it
            method: metadata.method || 'gateway',
          })

        if (error) {
          console.error('Supabase DB Insert Error:', error)
          return new Response(JSON.stringify({ error: 'DB insert failed' }), { status: 500 })
        }

        console.log('Successfully inserted payment into database!')
      } catch (dbError) {
        console.error('Database Error:', dbError)
      }
    } else {
      console.error('Missing metadata in PaymentIntent!')
    }
  }

  return new Response(JSON.stringify({ ok: true }), { status: 200 })
})
