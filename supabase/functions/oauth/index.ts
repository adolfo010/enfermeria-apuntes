import "jsr:@supabase/functions-js/edge-runtime.d.ts";

const SUPABASE_URL = Deno.env.get("SUPABASE_URL")!;
const SERVICE_KEY = Deno.env.get("SUPABASE_SERVICE_ROLE_KEY")!;
const CLIENT_ID = Deno.env.get("GOOGLE_CLIENT_ID") ?? "";
const CLIENT_SECRET = Deno.env.get("GOOGLE_CLIENT_SECRET") ?? "";
const REDIRECT_URI = Deno.env.get("GOOGLE_REDIRECT_URI") ?? "";
const FRONTEND_URL = Deno.env.get("FRONTEND_URL") ?? "https://example.com";

const SCOPES = ["https://www.googleapis.com/auth/drive"].join(" ");

function corsHeaders(extra: Record<string, string> = {}) {
  return {
    "Access-Control-Allow-Origin": "*",
    "Access-Control-Allow-Headers": "authorization, x-client-info, apikey, content-type",
    ...extra,
  };
}

function redirect(location: string) {
  return new Response(null, { status: 302, headers: corsHeaders({ Location: location }) });
}

async function rest(path: string, init: RequestInit = {}) {
  return fetch(`${SUPABASE_URL}/rest/v1/${path}`, {
    ...init,
    headers: {
      apikey: SERVICE_KEY,
      Authorization: `Bearer ${SERVICE_KEY}`,
      "Content-Type": "application/json",
      ...(init.headers || {}),
    },
  });
}

async function requireAuthenticated(req: Request): Promise<void> {
  const auth = req.headers.get("Authorization") ?? "";
  if (!auth.startsWith("Bearer ")) throw new Error("UNAUTHORIZED");
  const token = auth.slice(7).trim();
  if (!token) throw new Error("UNAUTHORIZED");
  const userRes = await fetch(`${SUPABASE_URL}/auth/v1/user`, {
    headers: { apikey: SERVICE_KEY, Authorization: `Bearer ${token}` },
  });
  if (!userRes.ok) throw new Error("UNAUTHORIZED");
}

async function saveTokens(access_token: string, refresh_token: string | undefined, expires_in: number) {
  const expires_at = new Date(Date.now() + expires_in * 1000).toISOString();
  const body: Record<string, unknown> = {
    id: "rossana",
    access_token,
    expires_at,
    updated_at: new Date().toISOString(),
  };
  if (refresh_token) body.refresh_token = refresh_token;
  const res = await rest("oauth_tokens", {
    method: "POST",
    headers: { Prefer: "resolution=merge-duplicates" },
    body: JSON.stringify(body),
  });
  if (!res.ok) throw new Error("No se pudo guardar el token: " + await res.text());
}

Deno.serve(async (req: Request) => {
  if (req.method === "OPTIONS") return new Response("ok", { headers: corsHeaders() });

  const url = new URL(req.url);
  const parts = url.pathname.split("/").filter(Boolean);
  const action = parts[parts.length - 1];

  try {
    if (action === "start") {
      const params = new URLSearchParams({
        client_id: CLIENT_ID,
        redirect_uri: REDIRECT_URI,
        response_type: "code",
        access_type: "offline",
        prompt: "consent",
        scope: SCOPES,
      });
      return redirect(`https://accounts.google.com/o/oauth2/v2/auth?${params.toString()}`);
    }

    if (action === "callback") {
      const code = url.searchParams.get("code");
      const err = url.searchParams.get("error");
      if (err) return redirect(`${FRONTEND_URL}?auth=error&reason=${encodeURIComponent(err)}`);
      if (!code) return new Response("Falta el código de Google", { status: 400, headers: corsHeaders() });

      const tokenRes = await fetch("https://oauth2.googleapis.com/token", {
        method: "POST",
        headers: { "Content-Type": "application/x-www-form-urlencoded" },
        body: new URLSearchParams({
          code,
          client_id: CLIENT_ID,
          client_secret: CLIENT_SECRET,
          redirect_uri: REDIRECT_URI,
          grant_type: "authorization_code",
        }),
      });
      const tokenJson = await tokenRes.json();
      if (!tokenRes.ok) return redirect(`${FRONTEND_URL}?auth=error&reason=${encodeURIComponent(JSON.stringify(tokenJson))}`);
      await saveTokens(tokenJson.access_token, tokenJson.refresh_token, tokenJson.expires_in);
      return redirect(`${FRONTEND_URL}?auth=ok`);
    }

    if (action === "status") {
      await requireAuthenticated(req);
      const res = await rest("oauth_tokens?id=eq.rossana&select=updated_at,expires_at");
      if (!res.ok) throw new Error("No se pudo consultar el estado de Google Drive");
      const rows = await res.json();
      const connected = Array.isArray(rows) && rows.length > 0;
      return new Response(JSON.stringify({ connected }), {
        headers: corsHeaders({ "Content-Type": "application/json" }),
      });
    }

    return new Response("Ruta no encontrada", { status: 404, headers: corsHeaders() });
  } catch (e) {
    const msg = String((e as any)?.message || e);
    const status = msg === "UNAUTHORIZED" ? 401 : 500;
    return new Response(JSON.stringify({ error: msg }), {
      status,
      headers: corsHeaders({ "Content-Type": "application/json" }),
    });
  }
});
