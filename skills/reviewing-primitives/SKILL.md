---
name: reviewing-primitives
description: >-
  Review a plan or a change against the primitives tree: traceability to intent
  clauses, a complete Intent impact block, supersession hygiene, evaluation
  adequacy read from proofs output, provenance candidates — and the audit that
  keeps intent tags intact through a spec refactor. Use when reviewing plans or
  code, or refactoring specs, in an app with a docs/primitives/ tree.
---

# Reviewing primitives

**Announce:** "I'm using the reviewing-primitives skill."

This skill applies only when the app has a `docs/primitives/` tree; the
workflow skill that sent you here owns everything else about the review or the
refactor.

## Inputs

Runs when the app has a **`docs/primitives/`** tree (`primitives-format` § Layout).
Read the **one** capability doc named by the plan header's **Capability:** line
(or located via `docs/primitives/index.md`) plus `compilation.md` — never the
whole tree. No tree → note "No primitives tree" in the report and skip.

**The mechanical output arrives with the prompt.** Whoever runs the plan, when
delegating the review, runs the commands `running-primitives-checks`
§ Handing the output to a reviewer names for the review's phase and pastes
their stdout under
**Mechanical primitives output (authoritative — do not re-run)**
(`running-primitives-checks` § Handing the output to a reviewer) — cite that
block. Run them yourself only when you are the top-level agent with a working
shell:

```bash
agent_primitives evals                            # clause coverage; exits 1 on findings
agent_primitives guard --base <the diff's base>   # what this change did to the record
agent_primitives proofs --since <the diff's base> # tagged-example counts per touched clause
```

**No block and no working shell → `UNVERIFIED (CLI unavailable)`** per
`running-primitives-checks` § None of these is quiet; `Status: Approved`
resting on the mechanical checks is not available on one. Ask the delegating
agent once for the output first, and report the unverified checks in the
**primitives:** section.

What each command checks — and the guard notice taxonomy with its
proof-vs-intent handling split — is
the **`running-primitives-checks`** skill. Cite `evals` file:line
output rather than re-deriving it by hand, and cite `guard` notices with a
verdict rather than copying them in as findings. Two turn into findings: an
**intent** notice with no matching entry in the plan's **Intent impact** block
(scope creep into intent, whatever the code does), and a **proof** notice on a
still-active clause (**Eval adequacy** below, with the before-state attached —
name what stopped being covered). Never clear a notice by editing the tree — a
reviewer that writes the provenance entry discharging an intent notice has
laundered the finding it was reading.

## Checks

Prefix these findings **`primitives:`**. They are checkable properties, not
suggestions:

- **Traceability** — every behaviour in the plan or diff maps to an active
  `intent:` clause. Untraceable behaviour is a finding: either a missing clause
  or scope creep. A plan whose header lacks the **Capability:** line when the
  tree exists is a finding.
- **Intent impact declared** — plan phase: the header carries a complete, honest
  **Intent impact** block per `planning-with-primitives` § Intent impact block; a
  missing block, an omitted touched clause, an undelivered case, or `no intent
  delta` beside a wording change is a finding.
- **Clause admissibility** — every new or amended clause passes the four tests
  in `primitives-format` § Intent clauses; run the
  durable test first, since it disposes of all four at once.
- **Clause granularity** — plan phase: one behaviour per clause, umbrella verbs
  and `and`-joins split, layer-only splits merged
  (`primitives-format` § Intent clauses).
- **No overlap** — a new capability doc whose intent overlaps an existing one
  is a plan defect (should be an amendment). Read `index.md` end to end before
  accepting a new doc — the only place overlap is visible without opening the
  whole tree. If two lines are too vague to tell apart, report **that** as the
  finding: an indiscriminate index line is how duplicate capabilities get
  created (`primitives-format`
  § Finding the right capability).
- **Compilation and Shape** — nothing contradicts `compilation.md` or the
  doc's recorded Shape; a change that needs a constraint amended says so
  explicitly rather than working around it. These are `philosophy:`-grade.
- **Supersession hygiene** — intent changes follow
  `primitives-format` § Lifecycle: the plan schedules row
  retirement and dead-spec deletion, post-close-out both have happened (pending
  during per-task loops is not a finding).
- **Eval coverage** — plan phase: every touched clause gets a spec home in the
  plan's tasks. Rows for **new** work are written at close-out — a plan
  pre-filling them from intention is a finding; rows transcribed from
  **already-existing specs** (a `backfilling-primitives` pass, earlier
  close-outs) are legitimately present at plan time
  (`primitives-format` § Evaluations). Implementation phase, **per-task reviews**: rows are
  not yet written — close-out fills them after all tasks approve — so check
  that the task delivered the spec homes its cited clauses need, not the
  rows. **Post-close-out reviews only:** every touched clause has a row
  pointing at real reported specs; `status: built` with a missing row is a
  finding, and no annotation excuses one. A doc still `amending`, or an index
  line still saying `planned` or `amending`, on a branch that completes its
  plan is a finding: close-out flips both to `built`
  (`closing-out-primitives` § Close-out pass). Check the tags landed on the
  **examples** that prove each clause — a tag on a `describe` or `context` is a
  finding, because it keeps resolving after the example it stood for is
  deleted.
- **Eval adequacy** — the check `agent_primitives evals` cannot make: **would
  breaking the clause turn a tagged example red?** Start from the
  **`proofs`** output for each touched clause: `proofs --since <base>` counts the
  tagged examples per clause the change touched, and
  `proofs '<capability>#I<n>'` lists them for one. Read the counts and listings
  against the plan's **Intent
  impact** entry, which names the cases the clause needs. A case the entry named that is missing from the tagged listing is a finding —
  `evals` is green on it, because one tag makes the whole file a carrier, so a
  clause meant to be proven by four denials passes with three tagged. Then read
  each touched clause's wording against its evaluations. A quantifier (*only*, *never*, *any*, *every*) proven by one
  happy path is a finding; so is an example asserting the affordance (form
  renders, `200` returned) where the clause names an outcome; so is a denial
  bolted onto a canonical journey instead of living in the policy or request
  spec that owns it (`tagging-intent`
  § What counts as proving a clause). Report the missing case, not "add more
  tests" — name the clause, the half that is unproven, and the layer it belongs
  at.

  Then run it the other way: **is every listed evaluation necessary?** An
  evaluation you could delete with the clause still fully proven is padding.
  More than ~3 on one clause is a tripwire — usually two promises sharing an id
  (`primitives-format` § Size discipline).
- **Provenance conflicts** — the work does not re-litigate a recorded rejection
  or undo a recorded deliberate decision without saying so
  (`primitives-format` § Provenance).

**Provenance candidates (non-blocking):** list decisions, constraints, and
accepted debt that pass the earns-its-place test of
`primitives-format` § Provenance in the report's
**primitives:** section, so the close-out pass (`closing-out-primitives`
§ Close-out pass) can file them as one-line entries.

## Report section

The review report carries this section:

```markdown
### primitives: (traceability, compilation, evals, provenance)
_Only when the app has a `docs/primitives/` tree; otherwise state "No primitives tree" and omit the findings._

**Mechanical checks:** [`evals` / `guard` / `proofs` summary lines quoted from the pasted **Mechanical primitives output** block — or `UNVERIFIED (CLI unavailable)`, the checks that did not run, and the findings that would have rested on them.]

- [confidence: X.X] `[file or area]`: [Direct statement — untraceable behaviour, compilation/Shape contradiction, missing evaluation, supersession hygiene, provenance conflict.] — `primitives-format` § Capability doc format
  **Verified:** [Capability doc + code you read to confirm, and the `agent_primitives evals` result — or that it was unavailable.]

**Provenance candidates (non-blocking):** decisions, constraints, or accepted debt worth a one-line provenance entry at close-out. Only durable value — not every implementation detail.
- ...
```

## Auditing tagged examples in a spec refactor

### Intent audit — does this `it` block carry an `intent:` tag?

**Only when the app has a `docs/primitives/` tree.** A tagged example is a
capability doc's evaluation, so a verdict on it is a verdict on the record too:

- **MOVE** — the tag travels with the example, and the clause's `evaluations:`
  gains the new path and loses the old one.
- **MERGE** — the surviving example carries the union of the tags. Check the
  merge did not swallow the half that proved a quantifier: two examples proving
  *"only the author can edit"* — one permitting, one denying — cannot become one
  example without the clause losing a side
  (`tagging-intent` § What counts as proving a clause).
- **DELETE** — a tagged example is only deletable if its clause is still proven
  elsewhere afterwards. If it is the last proof, the deletion is out of scope for
  a refactor: it removes coverage, not duplication. Flag it and leave it.
- **REWRITE** — re-read the clause against the rewritten example. A rewrite that
  drops to a lower layer for speed can quietly turn an outcome assertion into an
  affordance assertion.

Take **`agent_primitives proofs '<capability>#I<n>'`** before and after each
touched clause: it lists each evaluation file's tagged examples with a count,
so a tag dropped in a merge or a split shows as a number that went down. `evals` cannot see it — one surviving tag makes the whole file a
carrier — and `guard`'s `proof/removed` only fires when a tagged example is gone,
not when a surviving one lost its tag.

Never resolve a tag by deleting it from the example — that silently unproves a
clause while keeping the suite green, and `agent_primitives evals` will then
fail on the doc rather than on the spec that caused it. Finish the session with
`agent_primitives evals` green.

Then run **`agent_primitives guard --base <the commit this session started
from>`**. A spec refactor is the single largest legitimate source of its notices,
which is exactly why it is worth reading here: `guard` lists every tagged example
that lost assertions (`proof/weakened`), disappeared (`proof/removed`), or moved
to another layer (`evaluation/relayered`) — the audit-plan verdicts, read back off
what actually happened rather than off what the plan intended. Reconcile each
notice against its MERGE / DELETE / REWRITE verdict. One with no verdict behind it
is coverage this session dropped by accident; restore it. Notices about **intent**
(`intent/rewritten`, `intent/vanished`) mean the session edited promises, which a
spec refactor never does — stop and surface those.

### Anti-pattern

| Anti-pattern | Instead |
|--------------|---------|
| Deleting an `intent:` tag, or the last example proving a clause | Unproves a capability while the suite stays green; flag it and leave the example |

### Before declaring the refactor done

- [ ] Every `intent:` tag moved with its example, still sits on an `it` block, and its clause's `evaluations:` paths were updated; no tag was deleted to resolve a verdict
- [ ] `agent_primitives evals` is green (only when the app has a `docs/primitives/` tree)
- [ ] Every `agent_primitives guard` notice reconciles to an audit-plan verdict; no intent notices
