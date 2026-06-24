import { serve } from "https://deno.land/std@0.168.0/http/server.ts"
import { createClient } from 'https://esm.sh/@supabase/supabase-js@2'
import { JWT } from 'npm:google-auth-library'

serve(async (req) => {
  console.log('--- Edge Function Triggered ---')
  
  try {
    // 1. Get the payload from the Database Webhook
    const payload = await req.json()
    console.log('1. Webhook Payload received:', JSON.stringify(payload))
    
    const record = payload.record 
    if (!record || !record.user_id) {
      console.error('Error: Invalid webhook payload (missing record or user_id)')
      return new Response(JSON.stringify({ error: 'Invalid webhook payload' }), { status: 400 })
    }

    // 2. Initialize Supabase client
    console.log('2. Initializing Supabase Client')
    const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? ''
    const supabaseServiceKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? ''
    const supabase = createClient(supabaseUrl, supabaseServiceKey)

    // 3. Get the receiver's FCM token from users table
    console.log(`3. Fetching FCM token for user_id: ${record.user_id}`)
    const { data: userData, error } = await supabase
      .from('users')
      .select('fcm_token')
      .eq('id', record.user_id)
      .single()

    if (error) {
      console.error('Error fetching user data:', error.message)
      return new Response(JSON.stringify({ error: error.message }), { status: 500 })
    }

    if (!userData?.fcm_token) {
      console.log('Result: User has no FCM token saved. Skipping push notification.')
      return new Response(JSON.stringify({ message: 'User has no FCM token, skipping push.' }), { status: 200 })
    }

    const fcmToken = userData.fcm_token
    console.log(`-> Found FCM Token: ${fcmToken.substring(0, 15)}...`)

    // 4. Authenticate with Firebase using Service Account Key
    console.log('4. Authenticating with Firebase via Service Account Secret')
    const serviceAccountStr = Deno.env.get('FIREBASE_SERVICE_ACCOUNT')
    if (!serviceAccountStr) {
       console.error('Error: FIREBASE_SERVICE_ACCOUNT secret is missing from Supabase Dashboard.')
       return new Response(JSON.stringify({ error: 'Missing FIREBASE_SERVICE_ACCOUNT secret' }), { status: 500 })
    }
    
    const serviceAccount = JSON.parse(serviceAccountStr)
    const jwtClient = new JWT({
      email: serviceAccount.client_email,
      key: serviceAccount.private_key,
      scopes: ['https://www.googleapis.com/auth/firebase.messaging'],
    });

    console.log('-> Requesting Google Access Token...')
    const tokens = await jwtClient.getAccessToken();
    console.log('-> Token acquired successfully.')

    // 5. Send Push Notification via Firebase v1 API
    console.log('5. Sending payload to Firebase Cloud Messaging')
    const fcmPayload = {
      message: {
        token: fcmToken,
        notification: {
          title: record.title,
          body: record.body,
        },
      }
    }

    const response = await fetch(
      `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
      {
        method: 'POST',
        headers: {
          'Content-Type': 'application/json',
          Authorization: `Bearer ${tokens.token}`,
        },
        body: JSON.stringify(fcmPayload),
      }
    );

    const resData = await response.json()
    console.log('6. Firebase Response:', JSON.stringify(resData))
    
    return new Response(JSON.stringify(resData), {
      headers: { 'Content-Type': 'application/json' },
      status: response.ok ? 200 : 400
    })
    
  } catch (err) {
    console.error('Unhandled Exception in Edge Function:', err)
    return new Response(JSON.stringify({ error: err.message }), { status: 500 })
  }
})
