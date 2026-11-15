---
name: backfilling-primitives
description: >-
  Backfill a capability doc for a feature that already exists: read its specs
  and code for candidate intent clauses, then interview the human clause by
  clause — intended or accidental, why, where the edge is — and ask about
  unspecced behaviour, depended-on quirks, boundaries, and external promises
  before writing anything. Use when the user asks to backfill or capture an
  existing feature, or when planning finds an existing feature with no
  capability doc.
---

# Backfilling primitives (one capability, confirmed by the human)

<objective>
Produce **one capability doc** for a feature that already exists,
reconstructed from evidence and **confirmed by the human before anything is
written**. Read no more than the reading contract allows: `index.md`, the one
target capability doc (if any), and `compilation.md`
(`primitives-format` § Reading contract). Run it in the conversation with the
human — never hand it to a subagent, which cannot hold the interview.
</objective>

**Announce:** "I'm using the backfilling-primitives skill."

Structure rules: the **`primitives-format`** skill. Skeletons:
**`references/templates.md`** in the **`maintaining-primitives`** skill.
Tagging: the **`tagging-intent`** skill.

## When to use

Existing features get docs **lazily** (the first time planned work touches
them, planning runs this skill) or **on demand**. Never as a bulk
documentation project — batch requests run one capability at a time with
human confirmation between, ordered by where change is coming.

Entry points:

- **On demand** — the human names a feature.
- **From planning** — `planning-with-primitives` § Primitives gate found no
  doc for a shipped feature. Planning pauses here, and resumes once § 6 is
  done, treating the new doc as the capability its plan amends. Its final
  approval then moves the doc to `amending`
  (`planning-with-primitives` § At final approval).
- **An unconfirmed earlier backfill** — a doc whose provenance carries
  `intent reconstructed, unconfirmed` (see § 1).

## Process

### 1. Scope

A feature name or path list from the human. Check `index.md`: if it lists a
doc for the outcome and that doc's provenance has no
`intent reconstructed, unconfirmed` line, this is a `maintaining-primitives`
`update`, not a backfill.

If it has one, run § 4 on it: the doc's active clauses are the candidate list
(§ 2 and § 3 only add behaviour the clauses miss). § 5 then does not open
provenance, set status, or add the index line — it appends
`- YYYY-MM-DD — backfill intent confirmed by human.` A legacy clause the human
rewords is superseded, and one they call accidental is retired with
`retired_on: YYYY-MM-DD` (`primitives-format` § Lifecycle — ids never reused);
its `intent:` tags are moved or removed. `agent_primitives guard` then
reports `intent/deactivated` for each one. That notice is expected, because
the human's read-back confirmed it, so report it (§ 6). An `intent/rewritten`
notice means a clause was edited in place instead of superseded: restore it
and supersede it.

### 2. Specs first

Read the feature's spec files. In a suite following the app's testing
conventions for which spec layer owns a behaviour, behaviour-first system and
request spec descriptions *are* draft intent clauses, and each maps to its
`evaluations:` for free.

**Do not aggregate to fit the clause ceiling** — one behaviour per clause
(`primitives-format` § Intent clauses). If the honest clause list runs past
ten, the finding is that the **capability** should split, not that the
sentences should widen.

**Do not promote an adjacent spec into a proof** — the example you tag has
to go red if the clause stops being true
(`tagging-intent` § What counts as proving a clause).
Backfilled clauses arrive *wider* than any single existing example; where a
clause claims *only*, *never*, or *any* and one case is covered, either
narrow the clause to what the suite proves, or keep it wide and report the
uncovered half as a gap under § 5. Both are honest; tagging past it is
not.

Output: a **candidate** clause list, each with its spec description and path
as evidence.

### 3. Code second

Models, routes, policies for the Shape bullets (deltas only — nothing
derivable from the app's own conventions or stated in `compilation.md`).
Observable behaviour the code shows and no spec describes joins the candidate
list, with its file and line.

Do not write the capability doc from this list.

### 4. Interview (human) — every clause earns its place

The specs and code show what the feature *does*; only the human knows which of
it is *intended*, why, and where it stops. A backfill confirmed in minutes
records the code's behaviour as if someone had chosen it. This step is most of
the work.

**How to ask**

- Use the agent's structured question tool when available; otherwise ask in
  chat. A few questions per round, one topic per round.
- Make every question about a candidate stand alone: state the behaviour, cite
  the evidence (the spec description and path, or the file and line), and offer
  concrete answers, one of which is always "accidental — it just happens to do
  this". Category questions have no evidence to cite; ask them plainly, with
  examples.
- Never ask one catch-all ("anything else?") in place of the categories below.
  People answer the question they are asked.

**The ladder — for every candidate; rungs 2–4 only for those that survive rung 1**

1. **Intended or accidental?** "Must future work keep this, or is it just what
   the code happens to do?" If the answer is accidental, ask whether anyone
   would notice it changing: behaviour users or integrations depend on is a
   clause whatever its origin. Accidental and undepended-on is dropped here.
2. **Why?** "Who notices, or what breaks, if a change stops doing this?" An
   answer with no reason gets asked again in different words. A clause whose
   reason nobody can give is not written — it becomes an open question.
3. **Where is the edge?** "Who is this for, and who is excluded? What happens
   when the list is empty, the limit is hit, the user lacks permission, the
   call fails?" An answer that narrows the behaviour becomes the clause's
   wording — *only*, *never*, *any* — and the denial and boundary cases its
   proof needs. An answer that is a behaviour of its own (an empty state, a
   failure path) is a new candidate: one behaviour per clause.
4. **The review test.** Restate the answer as the one-sentence clause you will
   write and ask: "Would you block a pull request that broke this?" A "no"
   means it is not a promise; leave it out.

**What specs and code cannot reveal — ask each category explicitly**

- **Unspecced behaviour** — what users rely on that no spec covers, and the
  edge cases nobody wrote down: empty states, limits, permissions, failure
  paths. Each one confirmed is a clause, proven or not.
- **Accidental behaviour** — known bugs or quirks that users or integrations
  now depend on, and behaviour already slated to change or be deprecated. A
  quirk depended on is a clause; one slated to change is reported, not
  promised.
- **Boundaries and ownership** — what is out of this capability, which
  neighbouring capability owns it (check `index.md`), and who owns or approves
  changes here.
- **External promises** — contracts, compliance, SLAs, accessibility, anything
  sold to a customer that this behaviour must keep. Hold each against
  `compilation.md`: a promise that binds the whole app belongs there, as a
  proposed amendment for the human; one that binds this capability is a clause.

**When answers and the code disagree**, show the evidence and ask which is
right. Do not pick one silently. If the code is wrong, the clause states the
intent and the disagreement is reported as a bug.

**When the human does not know**, record it as an open question with who
might know. An unanswered question never becomes a clause, and never becomes
its absence.

**Done when** every candidate is classified, every category has been asked,
and the human has confirmed a read-back: the full clause list, each with its
reason, its edge, and its proof — the existing spec that will carry its tag,
or a gap — in one message. Write the doc only after that confirmation.

### 5. Write the doc

Only once § 4 is done. For an unconfirmed earlier backfill, apply the
clause changes the human confirmed and append the confirmation entry instead
(§ 1); items 3 and 6 below do not apply.

1. **`evaluations:` come from specs that already exist** — tag their examples
   now. Add the `intent:` tag to the examples as you write each clause — a
   clause naming a spec that does not carry the tag is a finding, not a
   capture.
2. **Gaps are findings, and they stay red** — observable behaviour with no
   spec home still gets its clause, with no `evaluations:`; no annotation
   excuses it (`primitives-format` § Evaluations). Say
   so when you report — list the uncovered clauses as blocking spec
   follow-up, and do not soften the clause or drop it to keep the run green.
3. **Provenance opens with one line:**
   `- YYYY-MM-DD — backfilled from existing behaviour; intent confirmed by human; prior history in git.`
   The read-back in § 4 is the confirmation, so no unconfirmed state ships.
   Do not mine git log for decision archaeology — noisy, low-yield.
4. **Edges and reasons** — each clause's edge is in its wording. A reason
   future work must respect beyond the clause goes in `## Shape`.
5. **Boundaries** — the answers sharpen the `index.md` line's discriminating
   outcome, and its `Owns:` where a resource is involved
   (`primitives-format` § Finding the right capability). What is out of
   scope, with a link to the neighbouring capability that owns it, and who
   approves changes go in `## Shape`.
6. Add the `index.md` line, `status: built` — the feature exists in
   production, and a clause with no spec is a red run rather than a reason to
   understate the status (`primitives-format` § Evaluations).
7. **Close** with `agent_primitives evals` and the diff read-back
   (`maintaining-primitives` § Close every writing pass by reading your own
   diff back).

### 6. Hand to the human

Report, as lists:

> Capability doc written at `docs/primitives/capabilities/<name>.md`.
>
> **Clauses with no proof** — blocking spec follow-up:
> - [clause id, and the case its spec needs]
>
> **Open questions nobody could answer** — not written as clauses:
> - [question, and who might know]
>
> **Accidental or slated to change** — not promised, so a future plan may
> change it:
> - [behaviour, and what the human said]
>
> **Code and intent disagree** — bugs: the clause states the intent, its
> proof stays red:
> - [clause id, the evidence, and what the code does instead]
>
> **Proposed `compilation.md` amendments** — app-wide promises; that file is
> yours:
> - [promise, and its reason]
>
> **Expected `intent/deactivated` notices** — confirming an earlier backfill
> only; each clause you superseded or retired at the read-back:
> - [clause id, superseded by or retired, and the human's reason]

When entered from planning, end by returning to `planning-with-primitives`
§ Primitives gate.

## Common mistakes

| Mistake | Instead |
|---|---|
| Confirming in minutes instead of interviewing | § 4 is most of the work; climb the ladder for every candidate. |
| Tagging before the clause is confirmed | Tag in § 5, after the read-back — a tag is a promise's proof. |
| Writing an accidental behaviour as a promise | Accidental and undepended-on is dropped at rung 1; slated to change is reported in § 6. |
| One catch-all question instead of the categories | Ask each category in § 4 explicitly. |
| Joining an edge case onto its clause with "and" | An edge that is a behaviour of its own is its own clause. |
| Writing the doc before the read-back is confirmed | § 5 starts only after the human confirms the full clause list. |
| Handing the pass to a subagent | A subagent cannot talk to the human; run it in the conversation. |

## Related

- **`primitives-format`** — structure, ownership, lifecycle, reading contract.
- **`tagging-intent`** — the `intent:` tag and what counts as proving a clause.
- **`running-primitives-checks`** — `evals` / `guard` / `proofs` reference.
- **`maintaining-primitives`** — `update`, `trace`, `lint`; the diff read-back.
- **`planning-with-primitives`** — its primitives gate sends shipped features with no doc here.
- **`bootstrapping-primitives`** — one-time tree scaffold; offers a first backfill.
