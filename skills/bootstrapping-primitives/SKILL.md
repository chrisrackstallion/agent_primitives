---
name: bootstrapping-primitives
description: >-
  One-time adoption of the primitives tree in an app: scaffold docs/primitives/
  (SCHEMA.md, index.md, capabilities/) and draft the human-owned compilation.md
  from a deep codebase survey and a probing interview that keeps asking until
  each constraint has a reason and an edge. Use when a repo has no
  docs/primitives/ tree, or the user says set up primitives, adopt primitives,
  or generate compilation. Backfill: backfilling-primitives; maintenance:
  maintaining-primitives.
---

# Bootstrapping primitives (one-time adoption)

<objective>
Stand up **`docs/primitives/`** in one sitting, most of it spent on the
interview: scaffold the tree, then draft **`compilation.md`** — the app-specific compilation primitive — from a
read-only survey plus a human interview. The deliverable is a **strawman the
human edits**, not a finished document: `compilation.md` is human-owned from
its first commit. Everything else (capability docs) accrues per-feature
afterwards — this skill deliberately does **not** backfill the app.
</objective>

**Announce:** "I'm using the bootstrapping-primitives skill."

Structure rules: the **`primitives-format`** skill. Skeletons:
**`references/templates.md`** in the **`maintaining-primitives`** skill.

## Preconditions

- **`docs/primitives/` must not already exist.** If it does, this is
  maintenance — route to **`maintaining-primitives`** instead.
- An app with an RSpec suite in the workspace (the checks read `spec/`).

## Process

### 1. Scaffold the tree

Create from the starters in `references/templates.md` of `maintaining-primitives`:

```
docs/primitives/
  SCHEMA.md          # contract starter
  index.md           # empty catalog — one line per capability, see templates.md
  capabilities/      # empty (add .keep if the repo tracks empty dirs)
```

`compilation.md` comes from steps 2–4, not the skeleton alone.

The first capability docs arrive later, from planning or a
`backfilling-primitives` pass (format: the `primitives-format` skill).

Mention `agent_primitives evals` to the user once, here: it ships with this gem and belongs
in CI beside RuboCop, so the tree cannot quietly rot. Say what it does and does
not settle (`running-primitives-checks` § Checked
mechanically) — the judgment it cannot make, whether a tagged spec would
actually go red, is a review responsibility from day one
(`tagging-intent` § What counts as proving a clause).

### 2. Survey (read-only, evidence for every candidate)

Read for **binding choices**, area by area. Record each candidate with the
file and line that shows it — a candidate without evidence is a guess, and the
interview needs something concrete to put in front of the human.

| Area | Read | Looking for |
|---|---|---|
| Dependencies | `Gemfile`, lockfile, `package.json` | What was chosen — and what is conspicuously absent (no Redis, no JS bundler, no service layer gem) |
| Runtime | `config/` adapters (queue, cache, storage, database), environment files | Datastores, background processing, external services |
| Delivery | Deploy config, CI workflows, `Dockerfile` | Where it runs, what gates a merge, what is checked that a newcomer would not expect |
| Boundaries | Engines, namespaces, top-level directories, authentication and authorization code | Seams that look deliberate; areas that look fenced off |
| Declared policy | `README`, `CLAUDE.md`, `AGENTS.md`, `docs/`, ADRs, linter config and its disabled rules | Rules someone already wrote down, and rules someone switched off |
| History | `git log` for removed dependencies, reverted changes, large migrations | Decisions already reversed once — the most valuable thing to ask "why" about |
| Deviations | Anything that departs from the framework's defaults | A deviation is either a constraint or an accident; only the human knows which |
| Specs | `spec/` layout, support files, factories | Which layers exist, since evaluations will name them |

Output: a **candidate list**, each with its evidence and one line on why it
might be binding. Detected is not binding — that is the interview's job. Do
not draft `compilation.md` from this list.

### 3. Interview (human) — keep asking until the answer has a reason

The survey finds *what*; only the human knows which choices are constraints,
why, and where they stop. This step is most of the work. A short interview
produces a document of guesses.

**How to ask**

- Use the agent's structured question tool when available; otherwise ask in
  chat. A few questions per round, one topic per round.
- Make every question about a candidate stand alone: name the choice, cite the evidence
  (`config/queue.yml` uses Solid Queue; no Redis anywhere in the lockfile), and
  offer concrete answers, one of which is always "just how it is today".
  Category questions have no evidence to cite; ask them plainly, with examples.
- Never ask one catch-all ("any other constraints?") in place of the
  categories below. People answer the question they are asked.

**The ladder — for every candidate; rungs 2–4 only for those that survive rung 1**

1. **Binding or incidental?** "Must future work respect this, or is it just
   how it happens to be?" Incidental candidates are dropped here.
2. **Why?** "What breaks, or who objects, if a change ignores it?" An answer
   with no reason gets asked again in different words. A constraint whose
   reason nobody can give is not written down — say so, add it to the open
   questions, and move on.
3. **Where is the edge?** "What would be an acceptable exception, and who
   would approve it?" This is what turns a preference into a rule an agent
   can apply.
4. **The review test.** Restate the answer as the line you would write and
   ask: "Would you block a pull request that broke this?" A "no" means it is
   a preference; leave it out.

**What code cannot reveal — ask each category explicitly**

- **External commitments** — contracts, compliance, security review,
  accessibility, uptime promises, anything sold to a customer.
- **Operational red lines** — datastores, vendors, cost ceilings, who is
  paged and what they refuse to run.
- **Ownership** — areas another team owns, code that must not be touched,
  work already promised elsewhere.
- **Reversed decisions** — what was tried and backed out, and why. Start from
  the history the survey found.
- **Temporary state** — choices that are true today and already scheduled to
  change, so nothing is built on them.
- **Deliberate deviations** — every departure from framework defaults the
  survey listed: chosen, or inherited?

**When answers and code disagree**, show the evidence and ask which is right.
Do not pick one silently.

**When the human does not know**, record it as an open question for the
handoff. An unanswered question never becomes a constraint, and never becomes
its absence.

**Done when** every candidate is classified, every category has been asked,
and the human has confirmed a read-back: the full list of constraints, each
with its reason and its edge, in one message. Draft only after that
confirmation.

### 4. Draft `compilation.md`

Apply the filter to every line: **not derivable from the code or the app's own
conventions, and it would change what an agent proposes.** "We use Solid Queue"
is derivable — cut. "No Redis — ops will not run a second datastore; anything
proposing it needs an amendment here first" is a constraint with teeth — keep.
Each kept line carries its reason and its edge in a clause; a line that needed
the interview to explain it will need the reason again in six months. Target
**under 50 lines**; if it runs longer, it is describing the app rather than
constraining it.

Use the skeleton's three headings (Runtime & operations / Boundaries &
ownership / Constraints with teeth); drop or add headings as the app demands —
the filter matters, the headings don't.

### 5. Hand to the human

> `compilation.md` drafted at `docs/primitives/compilation.md`. It's yours —
> please edit: cut anything you wouldn't enforce in review, add what I
> couldn't see. From here agents read it before every plan and propose
> amendments via review findings; they won't edit it.
>
> **Open questions nobody could answer** — not written down as constraints:
> - [question, and who might know]
>
> **Lines I'm least sure of** — check these first:
> - [line, and why it is uncertain]

Wait for the human's pass before treating bootstrap as done. Then offer —
**do not run unprompted** — a first backfill:

> Want to backfill capability docs for any features change is coming to soon?
> That's the `backfilling-primitives` skill, one capability at a time.

## What this skill does NOT do

- **No bulk backfill.** Capability docs accrue lazily (the first time planned
  work touches them, planning runs `backfilling-primitives`) or on demand
  through the same skill; a bulk documentation project produces half-accurate
  docs and dies.
- **No app code, no plans.**
- **No re-runs.** Once the tree exists, `compilation.md` changes only through
  human edits prompted by review findings; the tree changes through the
  standard workflow write points.

## Common mistakes

- **Describing instead of constraining** — `compilation.md` lines that restate
  the Gemfile. Apply the filter; when in doubt, cut.
- **Skipping the interview** — a survey-only draft encodes the agent's guesses
  about which choices are load-bearing; the interview makes the document
  human-specified.
- **Backfilling everything while you're at it** — resist; see above.
- **Accepting the first answer** — a line written without its "why" cannot be
  applied at its edge. Climb the ladder in step 3; a constraint nobody can give
  a reason for is an open question, not a line.
- **One catch-all question instead of the categories** — "any other
  constraints?" gets "no". Ask each category in step 3 explicitly.
- **Drafting before the read-back is confirmed** — step 4 starts only after
  the human has confirmed the full list from step 3; a draft from answers not
  yet confirmed is the agent's guesses again.

## Related

- **`maintaining-primitives`** — recurring operations (capture, trace, update, lint).
- **`backfilling-primitives`** — backfills a capability doc for an existing feature.
- **`primitives-format`** — structure, ownership, size limits.
- **`planning-with-primitives`** — first consumer: reads `compilation.md` and
  the target capability doc at its primitives gate.
