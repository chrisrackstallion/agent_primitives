---
name: closing-out-primitives
description: >-
  The primitives steps of implementing and finishing planned work: verify each
  task with proofs and guard, classify a revision as bug or intent change, then
  the close-out pass — fill evaluations from real specs, reconcile against the
  plan's Intent impact block, triage guard notices, flip status, append
  provenance. Use when implementing or completing a plan in an app with a
  docs/primitives/ tree.
---

# Closing out primitives

**Announce:** "I'm using the closing-out-primitives skill."

This skill applies only when the app has a `docs/primitives/` tree; the
workflow skill that sent you here owns everything else about running the plan
or implementing its tasks.

## Before starting work

**Capability doc:** if the plan header has a **Capability:** line, read that
one doc (`docs/primitives/capabilities/<name>.md`) and `docs/primitives/compilation.md`
now — agents always read `compilation.md` when the tree exists — and never the
whole tree (`primitives-format` § Reading contract). The capability doc
supplies the Intent clauses and Shape excerpts pasted into the implementing
agent's prompts, and it is the doc the close-out pass updates. If the line's path
does not resolve (doc renamed or deleted since planning), check `index.md`
for a rename; if it is genuinely gone, **stop and flag to the user** — do not
execute against a missing capability doc. No Capability line:
if `docs/primitives/` exists, **flag it to the user before proceeding** — the
plan predates primitives or skipped its gate (the reviewer treats that as a
plan defect), and executing it silently would drift the tree. Only when the
app has no tree do you skip everything primitives-related in this run.

When dispatching a task to the implementing agent, **paste the Intent clauses
this task cites, the relevant Shape bullets, and any `compilation.md`
constraints the task touches** into the prompt's context — the implementing
agent reads zero primitives files; the excerpt is its whole primitives context
and the only channel app-wide constraints reach it by.

## Working from an excerpt

If the task prompt includes **capability excerpts** (Intent clauses like
`I1 — …`, Shape bullets, and any `compilation.md` constraints from
`docs/primitives/`), treat the clauses as acceptance-criteria context and the
Shape bullets and compilation constraints as binding for this task. Do not
open or edit `docs/primitives/` yourself — the excerpt is your whole
primitives context by design.

## Verifying one task

**When the app has a `docs/primitives/` tree and the task served an intent clause,** run **`agent_primitives proofs --since HEAD`** and read it against the plan's **Intent impact** entry for each clause you served. The entry names the cases the clause needs; the output counts each clause's tagged examples. A count that comes up short against the entry means a proof you wrote and never tagged, or never wrote — drill in with **`agent_primitives proofs '<capability>#I<n>'`**, whose tagged listing shows which planned case is missing, then find the example in the spec file and tag it (or write it) before reporting. No other check can see this, because `evals` treats one tag as proof of the whole file and `guard` says nothing about an untagged new example. Quote each touched clause's tagged-count line in your report's test and verification results, so the count reaches review rather than your reading of it. If the task's spec list does not cover a cited clause's full wording, say so in your report instead of tagging past it.

**When the task touched a spec carrying an `intent:` tag,** finish with **`agent_primitives guard --base HEAD`** (notices only — it never fails). It reports what your work did to promises that already existed. A **proof** notice (`proof/removed`, `proof/weakened`, `evaluation/dropped`) on a still-active clause is yours to fix before reporting: you took coverage off a promise the app still makes, so restore the assertion or the example. An **intent** notice (`intent/rewritten`, `intent/vanished`, `provenance/rewritten`) means an intent clause moved — **you do not own that file**. Report it in the completion notes and change nothing: intent is amended by the user's decision, never by the implementing agent, and never by writing the provenance line that silences the notice (`primitives-format` § Ownership and write points).

## When finished work is revised

**Classify against Intent (when a capability doc exists):** read the doc's
`intent:` frontmatter and decide which of two revisions this is — the distinction
surfaces *before* delegating, not after:

- **The code failed the intent** (bug): "fixed" matches an existing clause.
  No Intent change and **no provenance line**; if the fix moved or added spec
  homes, sync `evaluations:` (and the specs' `intent:` tags) once the fix is
  Approved — a row sync alone is not a provenance event.
- **The intent changed** ("it should do X instead"): "fixed" contradicts a
  clause. Amend the clauses (supersede / add, per the `primitives-format` skill)
  alongside the fix. Once the fix is Approved: tombstone the superseded
  clause (`superseded_by:` / `superseded_on:`, per `primitives-format`
  § Lifecycle), add or update `evaluations:` for the amended clauses
  from the fix's **reported** specs, retag those examples, and append
  one provenance line:
  `- YYYY-MM-DD — revised: I<n> amended (X instead of Y) per user feedback.`
  Report all of it in the revision's completion report (below).

If the fix comes back blocked and the user abandons an intent-change revision,
**revert the clause amendments made when classifying it** — no shipped change
references them, so the draft-stage edit rule applies
(`primitives-format` § Lifecycle); note the reversal in chat, not provenance.

The revision's completion report includes:

- Primitives sync, if any (clause amendments, `evaluations:`, the one provenance
  line — per the classification above), and the `agent_primitives guard --base <ref>`
  notices for the revision. A bug-fix revision that produced an intent notice is
  a misclassified revision: the fix changed a promise. Say so to the user rather than
  writing the provenance line that quiets it.

## Close-out pass

While a plan runs, `docs/primitives/**` edits are orchestration bookkeeping, not
app code — whoever runs the plan appends provenance lines, syncs
`evaluations:`, flips `status:`, keeps the capability's `index.md` line in
sync, and amends Intent clauses when a revision's classification calls for it
(a user-directed intent change, § When finished work is revised), directly per
the **`primitives-format`** skill. Structural primitives work (splitting a
capability, lint passes) goes to **`maintaining-primitives`**; backfills go to
**`backfilling-primitives`**, run with the human rather than a subagent.

Required when the plan has a **Capability:** line, once every task is Approved.
Part of the definition of done — **not an offer to the user**. Whoever runs the
plan updates the capability doc directly (see above):

1. **Evaluations** — fill or update `evaluations:` on each intent clause this
   plan touched, from the **specs the implementing agent actually reported** — never
   from what the plan promised. The named spec must also carry the
   **`intent:` tag** (the `tagging-intent` skill); add it if the
   implementing agent did not. Delete-listed specs must actually be gone.

   **Reconcile against the plan's Intent impact block**, case by case, with
   **`agent_primitives proofs --since <ref>`** — each entry names the cases a
   clause needs and that output counts each clause's tagged examples; a count
   that comes up short is drilled into with
   **`agent_primitives proofs '<capability>#I<n>'`**, whose tagged listing
   shows which planned case is missing. Do this before filling the row —
   `evals` counts files, not cases
   (`running-primitives-checks` § Which examples prove a
   clause). A case the entry named and the listing does not show
   goes back through the implement → review loop, not into `evaluations:`.
   A declared case no spec delivered is a gap. A clause listed `unchanged — regression contract`
   whose evaluation had its **assertions** edited is the one to stop on: a
   refactor may move an evaluation's file, never change what it asserts — an
   edited assertion means behaviour moved and the plan was a mislabelled
   amendment; say so rather than filing the row. `agent_primitives guard`
   (step 2 of this pass) names that case mechanically as `proof/weakened`.

   **Read the reported examples against the clause before filling the row** —
   breaking the clause has to turn one of them red
   (`tagging-intent` § What counts as proving a clause).
   A clause claiming *only*, *never*, or *any* that came back with a single
   happy-path example goes back through the implement → review loop for the
   missing spec, not into a row that proves less than the clause says.
2. **Run the mechanical checks** — they are the check, not a formality:

   ```bash
   agent_primitives evals                 # exits 1 on findings
   agent_primitives guard --base <ref>    # notices only; never fails a run
   agent_primitives proofs --since <ref>  # tagged-example counts per touched clause
   ```

   `evals` green is a precondition for step 3. Every error is closed by
   writing the spec and tagging the example, never by editing the doc
   (`primitives-format` § Evaluations). The non-blocking warnings,
   `clause/in-flight` and `tag/in-flight`, mark rows this plan still owes.
   Step 1 files them, so one still showing is a row this pass missed.
   `status/plan-missing` means `plan:` names a file that is not on disk: point
   it at where the plan moved.

   `guard` reads what this run did to promises that already existed
   (`running-primitives-checks` § What a change did to the
   record). Pass the commit the run started from — the branch point
   (`--base main`) for a whole-branch close-out. Then act by kind, because the
   two kinds have opposite handling:

   - **Proof got smaller** (`proof/removed`, `proof/weakened`,
     `evaluation/dropped`, `evaluation/relayered`) — a live clause is proven by
     less than it was. Send it back through the implement → review loop to
     restore the proof, then re-run. Do not file the `evaluations:` row over
     the top of it.
   - **Intent moved** (`intent/rewritten`, `intent/vanished`, `doc/removed`,
     `status/downgraded`, `provenance/rewritten`) — **surface to the user and
     stop; do not resolve.** Only `intent/rewritten` is discharged, by a new
     provenance entry naming the clause id, and writing that entry to silence
     your own notice is the one move this check exists to catch. The others
     are never discharged; they print until the change is reverted or the
     user rules on it. Only a user decision amends intent
     (`primitives-format` § Ownership and write points).
   - **Expected movement** (`intent/deactivated`, `proof/changed`,
     `evaluation/moved`, `status/closed-out`) — normal when the plan called for it. Confirm each
     against the plan's **Intent impact** block and report them
     (§ What to report); an unplanned one belongs in the group above.
   - **`doc/unreadable`** — the capability doc stopped parsing, so nothing about
     it was compared and this run's `guard` output means nothing for that
     capability. `evals` fails on it too. Fix the frontmatter and re-run both
     before reading either result.
3. **Status** — flip `planned` or `amending` to **`status: built`**, removing
   `plan:` in the same edit, only when `agent_primitives evals` reports no
   errors and no in-flight warnings for this capability; otherwise report the
   gap instead of flipping.
4. **Provenance** — append **one** line for the whole run:

   ```markdown
   - YYYY-MM-DD — built [or amended]: docs/plans/<plan>.md. [Accepted debt,
     rejected alternatives, or notable reviewer-approved exceptions, one line.]
   ```

   **No run mechanics** — those belong in this run's handoff report
   (§ What to report) and git (`primitives-format` § Provenance).

   Fold in any **`primitives:` provenance candidates** from the reviewer
   reports (decisions, constraints, accepted debt) — one line each, only those
   that pass the same earns-its-place test.
5. **Index** — update the capability's `docs/primitives/index.md` line to the
   new status (it still says `planned` or `amending` from plan approval — sync
   it, don't merely confirm it).

If a reviewer report proposed a **`compilation.md` amendment**, surface it to
the user — that file is human-owned; whoever runs the plan never edits it.

## What to report

The run's completion package for the user carries:

- **Primitives close-out** summary (§ Close-out pass): status, `evaluations:` updated, `agent_primitives evals` result, the provenance line appended — or why status could not flip. Include each touched clause's tagged-example count from `agent_primitives proofs`, so the user sees the count and not only the claim that it was checked.
- **`agent_primitives guard` notices** (§ Close-out pass), each with what it was: planned, corrected during close-out, or **awaiting the user's decision** — intent notices are never resolved by whoever runs the plan, so any that remain are the first thing the user must rule on.
