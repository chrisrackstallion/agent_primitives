---
name: maintaining-primitives
description: >-
  Maintain the primitives tree under docs/primitives/ — capability docs with
  intent clauses, evaluations, append-only provenance, plus the human-owned
  compilation.md. Operations: capture (backfill an existing feature —
  backfilling-primitives), trace ("why is X like this"), update (sync
  status/evaluations/provenance), lint (health pass). Not for app code or plans; adoption setup:
  bootstrapping-primitives; checks: running-primitives-checks.
---

# Maintaining primitives (durable intent, evaluations, provenance)

<objective>
Keep the durable primitives tree under **`docs/primitives/`** healthy outside
the standard planning and execution write points: point backfills at
`backfilling-primitives`, answer "why is X like this" with citations, sync
docs after off-workflow changes, and run health passes.
</objective>

**Announce:** "I'm using the maintaining-primitives skill."

Structure, ownership, and size limits: the **`primitives-format`** skill
(read it before touching any path under `docs/primitives/`). CLI semantics
(`evals` / `guard` / `proofs`): the **`running-primitives-checks`** skill.
Skeletons: **`references/templates.md`**. One-time adoption (tree scaffold +
`compilation.md` interview): **`bootstrapping-primitives`**.

## When to use

- **Backfilling** a capability doc for an existing feature (`capture`) — the
  procedure is the **`backfilling-primitives`** skill.
- Answering **"why is X like this?"** with citations (`trace`).
- **Syncing** a doc after work landed outside the standard workflows (`update`).
- A **health pass** over the tree (`lint`).

**When not to use:** Writing plans (`planning-with-primitives` owns Intent
and Shape authorship during planning), executing plans
(`closing-out-primitives` owns the close-out pass), or app implementation.
Those workflows write to the tree at their own defined points — this skill
covers everything outside them.

Layout, ownership, and the three-file reading contract are
`primitives-format` § Layout / § Reading contract. The
one exception is **`lint`**, which sweeps every doc by design.

## Operations

| Op | Intent |
|----|--------|
| **capture** | Backfill a capability doc for an existing feature — the procedure is the **`backfilling-primitives`** skill. |
| **trace** | Read `index.md` → the capability doc → answer with citations to clause IDs, provenance lines, and spec paths. If the answer predates the doc, say so — provenance before the backfill line lives in git. |
| **update** | Sync one doc: status (including human-directed deprecation — `status: deprecated`, a provenance line saying why, and the index line moved to the Deprecated stub section), `evaluations:` against real spec homes and their `intent:` tags, one provenance line per event. Update `index.md` in the same change. Close with **`agent_primitives guard`** and read your own diff back (below). |
| **lint** | Run **`agent_primitives evals`** first, then the judgment checks below across the tree (the one whole-tree operation — exempt from the three-file contract); report findings, fix mechanical ones, leave judgment calls to the human. |

**Structural reshaping** — splitting an oversized capability, merging, or
renaming — is a human-approved **`update`**: redistribute the Intent clauses
to the new docs (tombstone pointers from the old doc, IDs never reused), carry
provenance forward by link rather than rewriting history, and sync `index.md`
in the same change. Lint only *reports* the split tripwire; the human decides;
an `update` pass executes.

### Close every writing pass by reading your own diff back

Any operation or skill that **wrote** to the tree ends with:

```bash
agent_primitives guard --base <the commit the pass started from>
```

It is notice-only and never fails, and it is the one check aimed at the pass
itself rather than at the tree: what did this change do to promises that already
existed. A maintainer holds the widest write access of any agent here, so it is
also the agent whose edits most need reading back.

- **Expected, and worth reporting**: `intent/deactivated` for a human-directed
  deprecation, `proof/changed` after a spec home moved, `evaluation/relayered`
  where the human approved the new layer.
- **Fix before reporting**: `evaluation/dropped` or `proof/removed` on a clause
  that is still active — a sync pass that removes proof from a live promise has
  gone past syncing.
- **Stop and hand to the human**: `intent/rewritten`, `intent/vanished`,
  `provenance/rewritten`. Clauses are human-co-owned and provenance is
  append-only; a maintainer that rewrote either has edited the record rather
  than maintained it. Report the notice verbatim, restore what you overwrote,
  and let the human decide. Never discharge one of these by writing the
  provenance entry that silences it — the entry states a decision, and the
  decision is not yours.

### lint — run the tool, then judge

**Step 1 — `agent_primitives evals`.** It settles everything mechanical
(`running-primitives-checks` § Checked mechanically).

```bash
agent_primitives evals                    # exits 1 on findings
agent_primitives evals --format json      # when you want to summarise a large tree
```

Report its findings as-is — they have file:line and a code, so do not restate
them in prose. Fix the unambiguous ones (a stale path, a missing tag). Leave
anything that changes what a clause *means* to the human. Its in-flight
warnings (`clause/in-flight`, `tag/in-flight` — `running-primitives-checks`
§ Checked mechanically) are an honest state — never "fixed" into silence. `clause/unproven` is closed by
writing the spec, never by editing the clause out of the doc.

**Step 2 — the judgment checks the tool cannot make:**

- **Umbrella clauses** — a clause built on *manage*, *handle*, *support*, or an
  `and` joining two different actions
  (`primitives-format` § Intent clauses). Mechanical
  hint: a clause needing four evaluations is usually a clause needing
  splitting. Report it as a proposed split with the per-action sentences written
  out — the ids are a human call.
- **Rows that do not prove their clause** — for each `built` clause, read its
  wording against its tagged examples and ask whether breaking the clause would
  turn one of them red
  (`tagging-intent` § What counts as proving a clause).
  Quantifiers are where the rot collects. Report it as an unproven clause with
  the missing case named; narrowing the clause instead is a human call. Check
  the reverse too — an evaluation that could be deleted with the clause still
  fully proven is a padded row.
- Every capability doc listed in `index.md`, and vice versa; statuses agree.
- **`index.md` lines that do not discriminate** — the tool checks a line
  exists, not that it earns its place
  (`primitives-format` § Finding the right capability).
  Read the list as a stranger deciding which doc to open: two lines that could
  describe each other's capability are a finding, as is a missing `Owns:` on a
  capability whose filename is not a resource name.
- **Names that fight the flat namespace**
  (`primitives-format` § Style) — propose renames
  sparingly and say the cost out loud: the filename is what `intent:` tags
  name, so a rename retags every proving example.
- An `amending` doc that is actually **abandoned**. `status/plan-missing`
  catches a plan file that is gone, but only a reader can tell that nobody is
  running a plan that is still on disk. Check its age and whether any branch
  still touches it. Unwinding one is a human call
  (`primitives-format` § Evaluations).
- A `built` doc with an **unmarked amendment** — its newest provenance line is
  `planned`, the plan is still running, and its new clauses fail
  `clause/unproven`. This is common in trees from before `amending` existed.
  Propose `status: amending` with `plan:` and the index line; the status is the
  human's call.
- **Size tripwires and prose padding inside the limits** —
  `primitives-format` § Size discipline and § Style.
- No content that belongs elsewhere: app code, plan tasks, restated app
  conventions, stray files outside the four allowed types.
- **Process noise in provenance** — run mechanics have no home in the tree
  (`primitives-format` § Provenance). Report as a
  finding; provenance is append-only, so the fix is a human call, not a
  rewrite.

## Delegation

A trace, update, or lint pass may be handed to a subagent the app defines for
primitives passes, if any; this skill stays canonical. That subagent starts
with no context, so its prompt needs the operation, the paths, and the
constraints pasted in. A backfill is not delegated — it needs the human
(`backfilling-primitives`).

## Related

- **`primitives-format`** — structure, ownership, size limits.
- **`running-primitives-checks`** — `evals` / `guard` / `proofs` reference.
- **`bootstrapping-primitives`** — one-time tree scaffold + `compilation.md`.
- **`backfilling-primitives`** — backfills a capability doc for an existing feature, interviewing the human.
- **`planning-with-primitives`** — creates/amends Intent and Shape at planning.
- **`closing-out-primitives`** — close-out pass writes `evaluations:`, status, provenance.
- **`reviewing-primitives`** — `primitives:` findings check traceability and eval coverage.
