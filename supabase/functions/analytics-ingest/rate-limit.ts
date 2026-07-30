const buckets = new Map<string, { count: number; resetAt: number }>();
const encoder = new TextEncoder();

async function keyFor(request: Request): Promise<string> {
  const secret = Deno.env.get("VGI_INGEST_HASH_SECRET");
  if (!secret) throw new Error("VGI_INGEST_HASH_SECRET is missing");
  const address = request.headers.get("cf-connecting-ip")
    ?? request.headers.get("x-nf-client-connection-ip")
    ?? request.headers.get("x-real-ip")
    ?? request.headers.get("x-forwarded-for")?.split(",")[0]?.trim()
    ?? "unknown";
  const key = await crypto.subtle.importKey(
    "raw", encoder.encode(secret), { name: "HMAC", hash: "SHA-256" }, false, ["sign"],
  );
  const signature = await crypto.subtle.sign("HMAC", key, encoder.encode(address));
  return Array.from(new Uint8Array(signature))
    .map((byte) => byte.toString(16).padStart(2, "0")).join("");
}

export async function allowed(request: Request): Promise<boolean> {
  const key = await keyFor(request);
  const now = Date.now();
  const bucket = buckets.get(key);
  if (!bucket || bucket.resetAt <= now) {
    buckets.set(key, { count: 1, resetAt: now + 60000 });
    return true;
  }
  bucket.count += 1;
  return bucket.count <= 120;
}
