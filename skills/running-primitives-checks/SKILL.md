---
name: running-primitives-checks
description: >-
  Run and read the agent_primitives CLI — evals (is every clause proven), guard
  (what a change did to intent and its proofs), proofs (which examples prove a
  clause) — with the guard notice taxonomy, who resolves which notice, and what
  to do when a command returns nothing. Use when running or citing these
  commands, in CI or before handing work to a reviewer.
---

# Primitives CLI (evals, guard, proofs)

**Announce:** "I'm using the running-primitives-checks skill."

Three commands read the primitives tree (structure and ownership:
**`primitives-format`**). Each answers a question the
others cannot, and none replaces judgment about whether a proof would actually
go red (`tagging-intent` § What counts as proving a
clause).

## Checked mechanically

```bash
agent_primitives evals                    # from the app root; exits 1 on findings
```

It checks clause ↔ evaluation: unproven built clauses, evaluations naming a
file that does not exist or does not carry the tag, tags naming a clause that
is absent or superseded, tags in a file the clause's `evaluations:` does not
list, tags sitting on a group rather than an example, duplicate ids, dangling
supersessions, capability docs nested in a subdirectory, docs still in the
retired prose format, and malformed frontmatter or tags. It also checks
`plan:`: an `amending` doc must name its plan (`status/plan-unnamed`), and no
other doc may carry one (`status/plan-stale`). Three warnings never fail a run:
`clause/in-flight`, for an `amending` doc's clauses with no row yet;
`tag/in-flight`, for a tag on a rowless clause of a `planned` or `amending`
doc; and `status/plan-missing`, for a `plan:` naming a file that is gone.
Provenance is never read. Everything else — sizes, index sync, provenance
style — is judgment, and stays with the `lint` operation in
`maintaining-primitives`.

## What a change did to the record

```bash
agent_primitives guard --base main        # notices only; exit 0 whenever it ran
```

`evals` is stateless — it asks whether the tree is well-formed **now**, and a
whole class of drift passes it green. Reword a clause under the same id, hollow
out the example proving it, move a browser promise onto a model spec: every link
stays well-formed while the record stops describing the app. Seeing that needs a
**before**, so `guard` parses the tree twice — at `--base` and in the working
tree — and reports what got **smaller or different**. Growth is silent: new
clauses, new tagged examples, added evaluations and appended provenance produce
nothing.

| Notice | What moved |
|--------|------------|
| `intent/rewritten` | a clause promises something else under the same id, with no provenance entry |
| `intent/vanished` | a clause id is gone with no tombstone |
| `intent/deactivated` | a clause was superseded or retired — the sanctioned path, still worth seeing |
| `evaluation/dropped` · `evaluation/relayered` | an active clause is proven by less, or at a layer that may not hold it |
| `evaluation/moved` | the same layer, a different file — confirm it proves what the old one did |
| `status/closed-out` | an amendment closed out (`amending` → `built`) — confirm its rows were filed |
| `proof/removed` · `proof/weakened` · `proof/changed` | a tagged example went, lost assertions, or changed |
| `doc/removed` · `status/downgraded` · `provenance/rewritten` | the record itself got smaller |
| `doc/unreadable` | the doc stopped parsing, so nothing about it can be compared |

**Everything it prints is a notice and nothing fails.** Each of these has an
innocent cause as well as a suspicious one — a spec refactor legitimately
produces most of the proof notices — and a check that stops honest work is a
check that gets routed around.

The split in handling is what makes it useful. **Proof** notices belong to the
agent that caused them: restore the assertion, the example, or the row, then
re-run. **Intent** notices belong to the user. Only `intent/rewritten` is ever
discharged, by a new provenance entry naming the clause id — and an agent
writing that entry to quiet its own notice has laundered exactly the change
this exists to surface. Every other intent notice is never discharged: it
prints on every run until the change is reverted or the user rules on it. Surface
it instead; only a user decision amends intent
(`primitives-format` § Ownership and write points).

## Which examples prove a clause

```bash
agent_primitives proofs 'comment_threads#I2'   # a lookup; exit 0 always — quote the `#`
```

`evals` counts **files**. A clause naming `spec/policies/comment_policy_spec.rb`
is satisfied by **one** tag in that file — so a clause meant to be proven by four
denials is green with three tagged, and `guard` is silent too, because an untagged
new example is growth. That is the gap `proofs` fills: the tagged examples behind
each clause, per evaluation file, as a listing to hold against the plan's proof
set.

```
  I3  Only a published stage accepts entries.
      spec/policies/long_list_policy_spec.rb — 3 tagged examples
        :3   allows entry to a published stage    1 assertion
        :11  denies entry to an archived stage    2 assertions
        :16  denies entry to a locked stage       1 assertion
```

A planned example missing from the listing is found in the spec file and tagged —
or written. Untagged examples are deliberately **not** printed: they drowned the
report in any real spec file, and a reader holding the plan already knows which
example is missing; `--format json` carries them when a step needs the full
picture. A tag on a `describe` is named as proving nothing rather than listed
among the proofs — there is no example under it — and the footer counts every
tag `evals` will reject.

**Nothing here is an offence and the exit code is always 0.** Most examples in a
spec file carry no tag by design — only evaluation examples are tagged — so a
tagged count is a number to hold against the plan's **Intent impact** entry, which
names the cases the clause needs. Made a gate it would fire on nearly every file.
`--since <the ref the task started from>` (`HEAD` while the task is
uncommitted) prints one counted line per clause whose spec files a change
touched, untracked files included, which is the shape a task's verify step runs —
a count that comes up short is drilled into by naming the clause.

## None of these is quiet

Every one of them prints. `evals` closes with `6 capabilities, 37 clauses — no
offences`; `guard` with `compared against <ref>: no change to
intent or the specs that prove it`; `proofs` with a line per clause, or `no
intent clauses found`. A real failure prints a Bundler or Ruby stack on stderr.

So **an empty result is not a clean run — it is a missing result.** A call that
came back with no stdout, no stderr and no exit code observed nothing about the
tree, and "the CLI returned no output" describes the tool bridge, not the CLI.
The common shape is a subagent: a worker whose shell is withheld (a `readonly`
agent type) or whose result never arrived.

Retry once, then report **`UNVERIFIED (CLI unavailable)`** against the checks
that did not run, and name what rested on them. Reading the frontmatter and the
`intent:` tags by hand is a different check and does not discharge this one — a
hand audit that happens to agree is luck, and recorded as a pass it hides that
nothing ran.

## Handing the output to a reviewer

The arrangement that holds: whoever **can** run them does, once, and hands the
output over. Whoever runs the plan, dispatching a review, runs the commands and
pastes their stdout into the review prompt; the reviewer cites that block
instead of shelling out.

Run them yourself first (running these commands to describe scope is
orchestration, not implementation) and paste their **full stdout** into the
prompt under the heading **Mechanical primitives output (authoritative — do not
re-run)**. The reviewer may be read-only and have no shell at all — an empty
result would read to it as a silent CLI (§ None of these is quiet); running them
here removes that failure from the loop. Paste verbatim **including the summary
lines** — a truncated block reads as a clean run. If a command fails in your own
shell, fix that before dispatching rather than sending the reviewer a gap. No
tree → say `no primitives tree`.

A plan-phase review sends two commands:

```bash
agent_primitives evals
agent_primitives guard --base <ref>
```

An implementation-phase review sends **three** commands, not the plan phase's
two:

```bash
agent_primitives evals
agent_primitives guard --base <the ref this task started from>
agent_primitives proofs --since <the ref this task started from>
```

A whole-run review — the final sign-off over every task's combined scope — puts
`--base` / `--since` at the **branch point** so the block covers the whole run.
