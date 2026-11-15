---
name: planning-with-primitives
description: >-
  The primitives steps of specifying and planning a feature: seed or amend the
  capability doc, write intent clauses before tasks, declare the Intent impact
  block naming each clause's proof cases, and sync status and provenance at plan
  approval. Use when writing a requirements spec or an implementation plan in an
  app with a docs/primitives/ tree.
---

# Planning with primitives

**Announce:** "I'm using the planning-with-primitives skill."

This skill applies only when the app has a `docs/primitives/` tree; the
workflow skill that sent you here owns everything else about the spec or plan.

## In a requirements spec

- **Ground** — When the app has a `docs/primitives/` tree, the spec's
  grounding includes `docs/primitives/index.md` (an existing capability makes
  this brainstorm an **amendment** to it, not a new doc) and `compilation.md`
  (human-owned constraints that bound every approach you propose) — read both
  **before proposing approaches**, not after the design is agreed.
- **Write spec** — **When the app has a `docs/primitives/` tree**, also create
  or update the capability doc (`docs/primitives/capabilities/<name>.md`): the
  spec's agreed outcomes become one-sentence Intent clauses (`I1`, `I2`, …),
  **one behaviour each** — split umbrella outcomes ("users can manage X") per
  action, and keep architecture and technology choices out of `intent:` (they
  are `## Shape`) — and the chosen direction a rough `## Shape`. The spec
  carries a **`## Intent`** block naming new and impacted clauses and the layer
  that will prove each (see **Intent (in the spec)**) — per the
  `primitives-format` skill. `status: shaping` applies only to docs this
  brainstorm **creates**; when updating an existing doc (a `planned` or `built`
  capability), leave its status untouched — a brainstorm never downgrades
  status. What's explicitly out of scope is worth a provenance line.
  The planner's primitives gate (§ Primitives gate below) confirms and extends
  this doc instead of re-deriving intent.
- **After the design** — When the app has a `docs/primitives/` tree, seed the
  capability doc per **Write spec** above (`status: shaping`; Intent clauses
  from the spec's outcomes; one `shaped` provenance line noting explicit scope
  exclusions) and add its `index.md` line.

### Intent (in the spec)

When the app has a `docs/primitives/` tree, the spec states the intent it settles
**before** the sequence that ships it, separating new promises from clauses
merely relied on:

```markdown
## Intent

**New** — seeded into `docs/primitives/capabilities/team_invitations.md`

- I1 An admin can invite a person by email address. — proven at: request spec
- I2 An invitation expires 14 days after it is sent. — proven at: model spec

**Impacted** — existing clauses this work touches

- `accounts#I3` A member sees only their own account. — unchanged; must not break

**Out of scope** — bulk invites, invite links. [One line each. These become
provenance, not clauses.]
```

Name the **layer** that will prove each new clause, coarsely — one word, no file
paths or task numbers (the planner's job). **If the only honest answer is
"a journey spec", the clause is too broad and wants splitting** before a plan is
written around it. What is and is not a clause:
`primitives-format` § Intent clauses — run the **durable**
test on every line, since a brainstorm is where architecture and technology
choices are most likely to be mistaken for intent.

## Primitives gate

Runs **before drafting anything**, when the app has a **`docs/primitives/`**
tree (see the **`primitives-format`** skill and `maintaining-primitives`). If
the tree does not exist, skip this gate — optionally mention
`bootstrapping-primitives` once — and omit the **Capability:** header line
(§ Intent impact block).

The reading contract is three files, never more: **`index.md`**, the **one**
target capability doc, and **`compilation.md`**.

1. **Read `docs/primitives/index.md`.** Does an existing capability own this
   outcome? If yes, this plan is an **amendment** to that capability — never
   create a second doc whose intent overlaps an existing one (a plan defect
   the reviewer will flag). **One capability per plan — always.**
   Work spanning two capabilities is two plans (independent subsystems split
   into separate plans): clause IDs are only unambiguous within one
   doc, and every downstream mechanism targets exactly one doc. The
   reading-contract allowance for opening a second capability doc is for
   **context**, never a second target.

   **This does not mean one plan per capability.** A capability large enough
   to ship in stages gets **several sequenced plans**, each an amendment to
   the same doc serving its own clauses — what the requirements spec's
   `## Delivery sequence` enumerates. Later plans append their own provenance
   line and set the status per § At final approval, exactly like any other
   amendment.
2. **Read `docs/primitives/compilation.md`.** These are human-owned, app-wide
   constraints; the plan must not contradict them. If the right approach
   genuinely requires breaking one, **stop and say so** — the constraint
   changes by human amendment, not by a plan working around it.
3. **Read (or create) the capability doc** under
   `docs/primitives/capabilities/<name>.md`:
   - **Exists (from brainstorming, `status: shaping`, or earlier work):**
     confirm and extend. Classify every part of this plan against the `intent:`
     clauses — serves an existing clause / **supersedes** one (`superseded_by:`
     plus `superseded_on:`, new id — never renumber or delete) / adds a new
     clause. Read
     `## Provenance` before proposing an approach: do not re-litigate a
     recorded rejection or "fix" a recorded deliberate decision without
     saying so explicitly.
   - **Exists, and this plan changes no behaviour (refactor, migration,
     architecture change):** the fourth classification, and the one with no
     `intent:` edit in it. Leave every clause and `status:` untouched; the active
     clauses become the plan's **regression contract** — list them as
     `unchanged` entries in the Intent impact block and write `no intent delta`.
     Record what future work must respect in `## Shape`, and append a
     `refactored` provenance line only when a constraint actually changed;
     tidying that leaves no constraint behind earns no entry. If a clause's
     wording has to change for the work to be correct, this is **not** this
     branch — it is an amendment, and it takes the supersession mechanics above.
   - **Missing, new feature:** create it now. The requirements-gate answers
     **are** the `intent:` clauses — transcribe them into frontmatter as
     one-sentence `clause:` entries (`I1`, `I2`, …). **Split as you
     transcribe.** Gate answers arrive in umbrella form — *"users need to
     manage their comments"* — and one behaviour per clause is the rule
     (`primitives-format` § Intent clauses). Draft
     `## Shape` (deltas only) from the approach-gate outcome. Skeleton:
     `references/templates.md` in the `maintaining-primitives` skill.
   - **Missing, existing feature:** planning pauses and runs
     `backfilling-primitives` to completion. It then resumes with that doc as
     the capability this plan amends.
4. **Write the `intent:` clauses and Shape before drafting tasks.** Tasks then cite clause
   ids (`serves I1, I4` / `supersedes I4 → I5`) instead of restating
   requirements — the plan is ephemeral; the capability doc is the durable
   record.

   Write each clause **falsifiable** — a spec must be able to go red when it
   stops being true — and then **plan the spec homes that would**. A clause
   carrying a quantifier (*only*, *never*, *any*, *every*, *at most*) is not
   covered by one happy path: its task list names the denial or boundary case at
   the layer that owns it (the app's testing conventions for which spec layer
   owns a behaviour), usually a policy or request spec rather than
   another system spec — and its **Intent impact** entry names those cases one by
   one, because a proof set promised in prose is one nothing can count. A clause whose proof was never planned becomes a green
   row that proves nothing at close-out
   (`tagging-intent` § What counts as proving a clause). When this gate **creates** a doc (new feature),
   add its `docs/primitives/index.md` line at creation —
   final approval then updates it.

**Write points:** during drafting this skill writes the **`intent:` clauses** and **Shape**;
at final approval it also flips `status:` to `planned` (or `built` →
`amending` with `plan:`), appends the one
`planned` provenance line, and syncs `index.md` (see **At final approval**
below). `evaluations:`, `status: built`, and the `built` provenance line
belong to execution close-out (`closing-out-primitives`); do not fill
them from intention. A backfilled doc's `evaluations:`, transcribed from
already-existing specs, are written by `backfilling-primitives` (§ 5. Write the
doc), not at plan time.

## Intent impact block

In the plan header, after the title and its note:

```markdown
**Capability:** `docs/primitives/capabilities/<name>.md` — serves I1–I4
[Clause IDs this plan serves, supersedes, or adds. Omit this line and the
Intent impact block below only when the app has no `docs/primitives/` tree.]

**Intent impact:** every clause this plan touches, and where its proof will land.

- **I5** Only the author can delete a comment — **new**
  - `spec/policies/comment_policy_spec.rb`
    - deny: reader
    - deny: other author
    - deny: archived post
  - `spec/requests/comments_spec.rb` (Task 3)
    - redirects a non-author
- **I4** Anyone can delete a comment — **superseded by I5**
  - spec deleted in Task 3; entry retires at close-out
- **I1** A reader can reply to any comment — **unchanged — regression contract**
  - `spec/system/comment_threads_spec.rb` (exists)
```

One entry per clause: the clause on the first line with its change in bold, one
line per proof file under it, one line per case under that. The change is one of
**new**, **amended**, **superseded by I\<n>**, or **unchanged — regression
contract**. That last value is not filler: it is the explicit list of promises
this plan must not break, and it is what makes a **Shape-only plan** expressible
— a refactor's block is all regression-contract entries, and it says `no intent
delta` where new clauses would go. List changed clauses first, so the delta
reads before the contract.

An entry names the **cases**, not only the files, whenever a clause needs more
than one example in the same file — the three denials under
`spec/policies/comment_policy_spec.rb` above. A file name alone is the granularity
`agent_primitives evals` can check, and it is satisfied by **one** tag in that
file: so a clause whose four denials were promised in prose passes every gate
with three of them tagged. Named cases are countable —
`agent_primitives proofs 'comment_threads#I5'` lists the tagged examples
behind the clause, and both execution close-out and review check that listing
against this entry.

Where proof lands is a **plan**, and it lives in this file only. It is never copied
into the doc's `evaluations:` — those are filled at close-out from the specs the
implementing agent actually reported, never from intention. Declaring the layer up front
is still the point: a clause whose only conceivable proof is a wide journey spec
is a clause that wants splitting, and this block is where that becomes visible
(`primitives-format` § Intent clauses).

## Citing clauses in tasks

```markdown
### Task N: [Resource or slice name] (serves I1, I4)

[The clause citation replaces restated requirements — the capability doc owns
intent. Use `(supersedes I4 → I5)` when the task changes intent. Omit the
parenthetical only when the app has no primitives tree.]
```

In the plan's self-review:

- **Primitives trace (when the tree exists):** Every task's behaviour maps to
  an active Intent clause in the capability doc; every clause this plan
  touches appears in the header's **Capability:** line; supersessions are
  explicit in both plan and doc; nothing contradicts `compilation.md` or the
  doc's recorded Shape and Provenance. Untraceable behaviour means either a
  missing clause (add it) or scope creep (cut it).

## At final approval

Once the plan is finally approved (its last review Approved with no further
edits to the plan):

1. Flip the capability doc's frontmatter to **`status: planned`** — or, when
   the doc is `built` and this plan adds or supersedes a clause, to
   **`status: amending`** with **`plan: docs/plans/YYYY-MM-DD-<feature>.md`**
   naming this plan (`primitives-format` § Evaluations). A plan with no intent
   delta leaves a `built` doc at `built`: every clause already has its row.
2. Append **one** provenance line covering the whole planning session — one
   line per event, not per edit, and nothing about how the plan got written
   (`primitives-format` § Provenance):

   ```markdown
   - YYYY-MM-DD — planned: docs/plans/YYYY-MM-DD-<feature>.md. [Rejected
     alternatives from the header's Alternatives considered, one line.]
   ```

3. Add or update the capability's line in `docs/primitives/index.md`.

## When the plan is revised

**Primitives sync (when the tree exists):** classify the revision. Tactics
only (snippets, file map, task order) → capability doc untouched. Changes to
**what the feature does** (scope, outcome) → amend the Intent clauses in the
same edit as the plan (add / supersede; pre-approval clauses not yet
referenced by an approved plan may simply be edited). No provenance line per
revision — the single `planned` line at final approval covers the session.
