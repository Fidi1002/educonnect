import { createClient } from 'jsr:@supabase/supabase-js@2';

const supabaseUrl = Deno.env.get('SUPABASE_URL') ?? '';
const serviceRoleKey = Deno.env.get('SUPABASE_SERVICE_ROLE_KEY') ?? '';

if (!supabaseUrl || !serviceRoleKey) {
  throw new Error(
    'SUPABASE_URL dan SUPABASE_SERVICE_ROLE_KEY wajib diisi untuk dispatch-push.',
  );
}

const supabase = createClient(supabaseUrl, serviceRoleKey, {
  auth: { autoRefreshToken: false, persistSession: false },
});

type Delivery = {
  id: string;
  notification_id: string;
  token_id: string;
  user_uid: string;
  device_token: string;
  platform: string;
  push_provider: string;
  payload: {
    title?: string;
    body?: string;
    category?: string;
    target_type?: string;
    target_id?: string;
    notification_id?: string;
    [key: string]: unknown;
  };
};

type ServiceAccount = {
  project_id: string;
  client_email: string;
  private_key: string;
};

function base64UrlEncode(input: Uint8Array): string {
  let binary = '';
  for (const byte of input) {
    binary += String.fromCharCode(byte);
  }
  return btoa(binary).replace(/\+/g, '-').replace(/\//g, '_').replace(/=+$/g, '');
}

function base64UrlEncodeString(input: string): string {
  return base64UrlEncode(new TextEncoder().encode(input));
}

function pemToArrayBuffer(pem: string): ArrayBuffer {
  const normalized = pem
      .replace(/-----BEGIN PRIVATE KEY-----/g, '')
      .replace(/-----END PRIVATE KEY-----/g, '')
      .replace(/\s+/g, '');
  const binary = atob(normalized);
  const bytes = new Uint8Array(binary.length);
  for (let index = 0; index < binary.length; index += 1) {
    bytes[index] = binary.charCodeAt(index);
  }
  return bytes.buffer;
}

async function createSignedJwt(serviceAccount: ServiceAccount): Promise<string> {
  const now = Math.floor(Date.now() / 1000);
  const header = { alg: 'RS256', typ: 'JWT' };
  const claimSet = {
    iss: serviceAccount.client_email,
    scope: 'https://www.googleapis.com/auth/firebase.messaging',
    aud: 'https://oauth2.googleapis.com/token',
    iat: now,
    exp: now + 3600,
  };

  const unsignedToken = [
    base64UrlEncodeString(JSON.stringify(header)),
    base64UrlEncodeString(JSON.stringify(claimSet)),
  ].join('.');

  const cryptoKey = await crypto.subtle.importKey(
    'pkcs8',
    pemToArrayBuffer(serviceAccount.private_key),
    {
      name: 'RSASSA-PKCS1-v1_5',
      hash: 'SHA-256',
    },
    false,
    ['sign'],
  );

  const signature = await crypto.subtle.sign(
    'RSASSA-PKCS1-v1_5',
    cryptoKey,
    new TextEncoder().encode(unsignedToken),
  );

  return `${unsignedToken}.${base64UrlEncode(new Uint8Array(signature))}`;
}

function loadServiceAccount(): ServiceAccount {
  const rawJson = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON');
  const rawBase64 = Deno.env.get('FIREBASE_SERVICE_ACCOUNT_JSON_BASE64');

  let parsed: Partial<ServiceAccount> = {};

  if (rawJson && rawJson.trim().length > 0) {
    parsed = JSON.parse(rawJson) as Partial<ServiceAccount>;
  } else if (rawBase64 && rawBase64.trim().length > 0) {
    const decoded = atob(rawBase64);
    parsed = JSON.parse(decoded) as Partial<ServiceAccount>;
  } else {
    parsed = {
      project_id: Deno.env.get('FIREBASE_PROJECT_ID') ?? '',
      client_email: Deno.env.get('FIREBASE_CLIENT_EMAIL') ?? '',
      private_key: Deno.env.get('FIREBASE_PRIVATE_KEY') ?? '',
    };
  }

  const serviceAccount = {
    project_id: parsed.project_id?.trim() ?? '',
    client_email: parsed.client_email?.trim() ?? '',
    private_key: (parsed.private_key ?? '').replace(/\\n/g, '\n').trim(),
  };

  if (
    !serviceAccount.project_id ||
    !serviceAccount.client_email ||
    !serviceAccount.private_key
  ) {
    throw new Error(
      'Firebase service account belum lengkap. Isi FIREBASE_SERVICE_ACCOUNT_JSON, FIREBASE_SERVICE_ACCOUNT_JSON_BASE64, atau FIREBASE_PROJECT_ID/FIREBASE_CLIENT_EMAIL/FIREBASE_PRIVATE_KEY.',
    );
  }

  return serviceAccount;
}

async function getAccessToken(serviceAccount: ServiceAccount): Promise<string> {
  const assertion = await createSignedJwt(serviceAccount);

  const response = await fetch('https://oauth2.googleapis.com/token', {
    method: 'POST',
    headers: { 'Content-Type': 'application/x-www-form-urlencoded' },
    body: new URLSearchParams({
      grant_type: 'urn:ietf:params:oauth:grant-type:jwt-bearer',
      assertion,
    }),
  });

  const tokenJson = await response.json();
  if (!response.ok || !tokenJson.access_token) {
    throw new Error(
      `Gagal membuat access token Google OAuth: ${JSON.stringify(tokenJson)}`,
    );
  }

  return tokenJson.access_token as string;
}

function buildDataPayload(payload: Delivery['payload']): Record<string, string> {
  const result: Record<string, string> = {};
  for (const [key, value] of Object.entries(payload)) {
    if (value == null) {
      continue;
    }
    result[key] = typeof value === 'string' ? value : JSON.stringify(value);
  }
  return result;
}

async function markFailed(deliveryId: string, message: string) {
  await supabase.rpc('mark_push_delivery_failed', {
    p_delivery_id: deliveryId,
    p_error: message,
  });
}

Deno.serve(async () => {
  try {
    const serviceAccount = loadServiceAccount();
    const accessToken = await getAccessToken(serviceAccount);

    const { data, error } = await supabase.rpc('claim_pending_push_deliveries', {
      p_limit: 50,
    });

    if (error) {
      return new Response(
        JSON.stringify({
          ok: false,
          stage: 'claim_pending_push_deliveries',
          error: error.message,
        }),
        { status: 500, headers: { 'Content-Type': 'application/json' } },
      );
    }

    const deliveries = (data ?? []) as Delivery[];
    if (deliveries.length === 0) {
      return new Response(
        JSON.stringify({ ok: true, claimed: 0, sent: 0, failed: 0 }),
        { headers: { 'Content-Type': 'application/json' } },
      );
    }

    let sent = 0;
    let failed = 0;

    for (const delivery of deliveries) {
      try {
        const response = await fetch(
          `https://fcm.googleapis.com/v1/projects/${serviceAccount.project_id}/messages:send`,
          {
            method: 'POST',
            headers: {
              'Content-Type': 'application/json',
              Authorization: `Bearer ${accessToken}`,
            },
            body: JSON.stringify({
              message: {
                token: delivery.device_token,
                notification: {
                  title: delivery.payload.title ?? 'EduConnect',
                  body: delivery.payload.body ?? '',
                },
                data: buildDataPayload(delivery.payload),
                android: {
                  priority: 'high',
                },
              },
            }),
          },
        );

        const rawText = await response.text();
        if (!response.ok) {
          failed += 1;
          await markFailed(delivery.id, `HTTP ${response.status}: ${rawText}`);
          continue;
        }

        let providerMessageId = rawText;
        try {
          const parsed = JSON.parse(rawText) as { name?: string };
          providerMessageId = parsed.name ?? rawText;
        } catch (_) {
          // Keep raw response as fallback when response is not JSON.
        }

        await supabase.rpc('mark_push_delivery_sent', {
          p_delivery_id: delivery.id,
          p_provider_message_id: providerMessageId,
        });
        sent += 1;
      } catch (error) {
        failed += 1;
        await markFailed(delivery.id, error.toString());
      }
    }

    return new Response(
      JSON.stringify({
        ok: failed === 0,
        claimed: deliveries.length,
        sent,
        failed,
      }),
      { headers: { 'Content-Type': 'application/json' } },
    );
  } catch (error) {
    return new Response(
      JSON.stringify({
        ok: false,
        stage: 'bootstrap',
        error: error instanceof Error ? error.message : String(error),
      }),
      { status: 500, headers: { 'Content-Type': 'application/json' } },
    );
  }
});
