import { validatePayload } from "./validation.ts";

const NOW = Date.parse("2026-08-03T12:00:00.000Z");

function payload(occurredAt?: string) {
  return {
    type: "pageview",
    visitorKey: "visitor_test",
    sessionKey: "session_test",
    eventKey: "event_test",
    occurredAt,
  };
}

function assertEquals(actual: unknown, expected: unknown) {
  if (actual !== expected) {
    throw new Error(`Expected ${String(expected)}, received ${String(actual)}`);
  }
}

function assertThrows(action: () => unknown) {
  try {
    action();
  } catch {
    return;
  }
  throw new Error("Expected function to throw");
}

Deno.test("uses the trusted receipt time when occurredAt is omitted", () => {
  const result = validatePayload(payload(), NOW);
  assertEquals(result.occurredAt, "2026-08-03T12:00:00.000Z");
});

Deno.test("accepts timestamps within the ingestion window", () => {
  const result = validatePayload(payload("2026-08-03T11:59:00.000Z"), NOW);
  assertEquals(result.occurredAt, "2026-08-03T11:59:00.000Z");
});

Deno.test("rejects timestamps older than 24 hours", () => {
  assertThrows(() => validatePayload(payload("2026-08-02T11:59:59.999Z"), NOW));
});

Deno.test("rejects timestamps more than five minutes in the future", () => {
  assertThrows(() => validatePayload(payload("2026-08-03T12:05:00.001Z"), NOW));
});
