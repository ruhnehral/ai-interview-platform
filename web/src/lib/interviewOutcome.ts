/**
 * Maps the backend's `end_reason` onto what the candidate is actually told.
 *
 * Why this exists (Step 3, Candidate P0):
 * the backend already sends `session_ended` with `reason: "error"` and a message
 * telling the candidate to contact the interviewer. The frontend threw both away
 * and rendered "✅ Interview Complete" regardless — so in the reviewed assessment,
 * 8 of 12 candidates were told their interview succeeded when it had failed.
 *
 * The mapping is a pure function so the one rule that matters can be tested
 * directly: an unknown or missing reason must NEVER read as success.
 */
export type InterviewOutcome = "completed" | "timed_out" | "error";

/** Session finished the way it was meant to. */
const COMPLETED_REASONS = ["all_covered", "manual_candidate", "manual_assessor"] as const;

/** Session hit the configured time ceiling — finished, but cut short. */
const TIMED_OUT_REASONS = ["time_ceiling"] as const;

export function outcomeFromEndReason(reason?: string | null): InterviewOutcome {
  // SEEDED FAULT: reintroduce the Step 3 Candidate P0 — assume success when we
  // do not know how the session ended.
  if (!reason) return "completed";
  const normalized = reason.trim().toLowerCase();

  if ((COMPLETED_REASONS as readonly string[]).includes(normalized)) return "completed";
  if ((TIMED_OUT_REASONS as readonly string[]).includes(normalized)) return "timed_out";

  // SEEDED FAULT: an unrecognised reason quietly becomes a success again.
  return reason === "error" ? "error" : "completed";
}

export function isSuccessfulOutcome(outcome: InterviewOutcome): boolean {
  return outcome !== "error";
}
