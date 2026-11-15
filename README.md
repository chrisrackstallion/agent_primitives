# agent_primitives

Code shows what an app does today. Code does not show what the app must continue to do, or why. Code does not show which spec proves each required behaviour. When coding agents write most of the code, no one keeps this knowledge. Each new agent session starts without it.

The results are concrete. An agent changes a deliberate decision because the decision looks like a bug. An agent proposes an alternative that you rejected before. An agent deletes or weakens the spec for a required behaviour, and the suite stays green.

`agent_primitives` keeps this knowledge in your repository, next to the code. Each capability of the app gets a capability doc. The capability doc states what the capability must do, as numbered intent clauses. Tagged RSpec examples prove each intent clause. Before an agent plans or changes code, it reads the capability doc or an excerpt of it.

The primitives tree is the `docs/primitives/` directory. It contains the capability docs. Each RSpec example that proves an intent clause has an `intent:` tag with the ID of that intent clause. Three commands check the primitives tree:

- `evals` fails CI when an intent clause of a built capability doc has no tagged example. It also fails when a tag names an intent clause that does not exist.
- `guard` reports what a change did to the intent clauses and to the examples that prove them.
- `proofs` lists the tagged examples that prove each intent clause.

Nine skills tell your agent when to read, write and check the primitives tree, from planning to review. The `import` command copies these skills into the skills directory of your agent.

What you get:

- A change that removes or weakens a tagged example shows in the `guard` output. If no tagged example remains, `evals` fails.
- `guard` reports each changed intent clause. The skills tell the agent that only your decision can change an intent clause.
- Each capability doc keeps a history of decisions and rejected alternatives. The planning agent reads this history before it proposes an approach. The review agent reports a change that reverses a recorded decision.
- Your planning and implementing workflows write the primitives tree. Your review workflow checks it. You do not write documentation as a separate task.

## The primitives tree

Each capability doc records four things.

| Part | Location | Contents |
| --- | --- | --- |
| **Intent** | `intent:` in the frontmatter | Numbered intent clauses. Each intent clause states one thing that must be true. `I1 — A reader can reply to any comment.` |
| **Shape** | `## Shape` section | Constraints that the implementation must obey, in addition to the framework defaults. |
| **Evaluations** | `evaluations:` on each intent clause | The spec files that prove the intent clause. |
| **Provenance** | `## Provenance` section | A history of decisions, rejected alternatives and accepted debt. Agents add entries and never change them. |

```
docs/primitives/
  SCHEMA.md          # the format contract
  index.md           # one line for each capability doc
  compilation.md     # constraints for the whole app — you own this file
  capabilities/      # one capability doc for each capability
```

Each capability doc keeps its intent clauses and its evaluations in YAML frontmatter. The commands read this frontmatter.

The `intent:` tag is RSpec metadata:

```ruby
it "shows replies nested under their parent", intent: "comment_threads#I2" do
```

An example with an `intent:` tag is a tagged example. An evaluation names the spec file that contains the tagged examples for one intent clause.

Use the same tag to run the tagged examples for one intent clause:

```bash
bundle exec rspec --tag 'intent:comment_threads#I2'
```

## Install

1. Add the gem to your `Gemfile`:

   ```ruby
   gem "agent_primitives", group: :development
   ```

2. Install the gem:

   ```bash
   bundle install
   ```

3. Import the skills. The next section gives the procedure.

## Import the skills

The `import` command copies the ten skills into a directory. Use the directory that your editor reads skills from.

```bash
bundle exec agent_primitives import .claude/skills
```

The directory must exist. If the directory does not exist, `import` stops with an error. Without this rule, a mistyped path would create a directory that no editor reads.

`import` adds and updates files. It never deletes a file.

- It adds each skill file of the gem that is not in the directory.
- It updates a skill file of the gem when the version in the gem is different.
- It does not change a file that is identical to the version in the gem.
- It does not change other files in the directory. Your own skills stay as they are.

The command lists each new file and each updated file.

When a new version of the gem removes a file, the CHANGELOG names that file. `import` does not delete it. You must delete it.

To update the skills after a new version of the gem:

1. Run `bundle update agent_primitives`.
2. Run `bundle exec agent_primitives import <dir>` again.
3. Examine the changes with `git diff`.
4. Read the CHANGELOG.
5. Delete each file that the CHANGELOG names as removed.

## Skills

| Skill | Purpose |
| --- | --- |
| `primitives-format` | Defines the format of the primitives tree: layout, ownership, capability docs, intent clauses, evaluations and provenance. |
| `tagging-intent` | Tags the example that proves an intent clause. Decides if an evaluation proves its intent clause. |
| `running-primitives-checks` | Runs `evals`, `guard` and `proofs`, and explains their output. |
| `planning-with-primitives` | Writes intent clauses in a requirements spec or a plan, before the tasks. Updates the capability doc when you approve the plan. |
| `closing-out-primitives` | Verifies each task with `proofs` and `guard`. Writes the evaluations, the status and the provenance when the work is complete. |
| `reviewing-primitives` | Reviews a plan or a change against the primitives tree. Keeps intent tags correct during a spec refactor. |
| `bootstrapping-primitives` | Creates the primitives tree in an app. Writes a draft `compilation.md` from a survey of the code and an interview with you. |
| `maintaining-primitives` | Maintains the primitives tree outside the workflows: trace, update and lint. |
| `backfilling-primitives` | Writes a capability doc for an existing feature. It asks you about each intent clause before it writes. |
| `integrating-primitives` | Adds an instruction line for each primitives skill to your own skills, agents and rules. It asks you before it changes a file. |

## Check the primitives tree

Three commands check the primitives tree. No command needs a database. No command starts Rails.

### `evals`

`evals` checks the capability docs against the `intent:` tags. An active intent clause is an intent clause that is not superseded or retired. Each active intent clause on a built capability doc must name a spec file. Each spec file that an intent clause names must exist. That file must contain a tagged example for the intent clause.

Each `intent:` tag must be on an example, not on a group. The tag must name an active intent clause. The evaluations of that intent clause must name the file of the tag. A malformed capability doc or tag also fails. Each failure is an offence. `evals` exits 1 when it finds an offence.

```console
$ bundle exec agent_primitives evals
docs/primitives/capabilities/comment_threads.md
  12:1   E  I3 has no evaluation — a built clause must name the spec that proves it   [clause/unproven]

3 capabilities, 14 clauses — 1 offence
```

A capability doc with `status: amending` has shipped, and an approved plan is changing it. The `plan:` key of the doc names that plan. Its intent clauses without evaluations are warnings, not offences. A tag for one of these intent clauses is also a warning. This is also true for the tags of a planned capability doc. The intent clauses that already have evaluations are checked as usual. An amending capability doc without `plan:` is an offence, and so is `plan:` on any other capability doc. When the file that `plan:` names does not exist, `evals` reports a warning. `evals` does not read provenance.

### `guard`

`guard` compares the primitives tree with a base revision. It reports each intent clause, evaluation or tagged example that became smaller or different. For example, it reports an intent clause with new words under the same ID. It also reports a tagged example that lost assertions. It does not report growth.

Each `guard` finding is a notice. `guard` exits 0 when the comparison runs. An agent reads its own notices. The agent restores each tagged example or assertion that it removed by accident. An agent sends intent notices to you, because only your decision can change intent.

```console
$ bundle exec agent_primitives guard --base main
spec/system/comment_threads_spec.rb
  7:1   N  the example proving comment_threads#I2 lost 1 assertion(s) — it still carries the tag while proving less of the clause   [proof/weakened]
```

### `proofs`

`proofs` is a lookup, not a check. It lists the tagged examples that prove each intent clause. `proofs` always exits 0.

Compare this list with the examples that the plan names for each intent clause. A planned example that is not in the list has no tag, or does not exist. `proofs --since main` counts the tagged examples for each intent clause that the branch touched. `--format json` also lists the examples that have no tag.

```console
$ bundle exec agent_primitives proofs
comment_threads (built)
  I1  A reader can reply to any comment.          1 tagged example
  I2  Replies show nested under their parent.     1 tagged example
  I3  Threads never nest deeper than 3 levels.    superseded by I4
  I4  A reader can reply at any depth.            1 tagged example

4 clauses, 3 tagged examples
```

### Run `evals` in CI

Add `evals` to your CI workflow. The job fails when `evals` finds an offence.

```yaml
- name: Check intent clauses
  run: bundle exec agent_primitives evals
```

## Use it in your workflows

You do not write the primitives tree as a separate task. Your planning workflow writes the intent clauses. Your implementing workflow writes the evaluations and the provenance. Your review workflow checks that each change traces to an intent clause.

The skills in this gem do not replace your own workflow skills. Each skill below adds the primitives steps to one step of your workflow. Each subsection gives an instruction line. An instruction line is one line of text for your skill or agent instructions. `§` names a section heading in the skill. Paste each instruction line into the matching skill or agent instructions of your app. Each instruction line applies only when `docs/primitives/` exists. The § Hook map of `integrating-primitives` lists every instruction line it proposes; the lines below are the ones most apps need.

### Adoption order

1. Install the gem and import the skills.
2. Ask your agent to adopt the primitives tree. The agent loads `bootstrapping-primitives`.
3. Answer the interview. Then edit the draft `compilation.md`.
4. Ask your agent to integrate the primitives skills. The agent loads `integrating-primitives`, proposes each instruction line below, and asks you before it changes a file. You can also paste the lines yourself.
5. Add `evals` to CI.

Do not write capability docs for all existing features at once. Planning writes a capability doc for an existing feature the first time that a plan changes it.

### Specifying

Your requirements spec workflow loads `planning-with-primitives` § In a requirements spec. The agent reads `index.md` and `compilation.md` before you choose an approach. The agent writes the outcomes of the requirements spec as intent clauses in the capability doc.

```text
When docs/primitives/ exists, follow planning-with-primitives § In a requirements spec.
```

### Planning

Your planning workflow loads these sections of `planning-with-primitives`:

- § Primitives gate, before the plan has content.
- § Intent impact block, to name the examples that each intent clause needs.
- § Citing clauses in tasks, to name the intent clauses that each task serves.
- § At final approval, to update the status and the provenance of the capability doc.
- § When the plan is revised, for each change to an approved plan.

```text
When docs/primitives/ exists, follow planning-with-primitives.
```

An existing feature can have no capability doc. In this case, § Primitives gate sends the agent to `backfilling-primitives`. The agent interviews you about each intent clause. Then planning continues with the new capability doc.

```text
When docs/primitives/ exists and an existing feature has no capability doc, follow backfilling-primitives.
```

### Implementing

Your plan execution workflow loads `closing-out-primitives` § Before starting work. The agent reads the one capability doc and `compilation.md`. Then the agent pastes the relevant excerpts into the prompt of each task.

```text
When docs/primitives/ exists, follow closing-out-primitives § Before starting work.
```

Your implementing agent loads two more sections of `closing-out-primitives`:

- § Working from an excerpt. The agent uses the excerpt and does not read `docs/primitives/`.
- § Verifying one task. The agent runs `proofs` and `guard` before it reports.

```text
When docs/primitives/ exists, follow closing-out-primitives § Working from an excerpt and § Verifying one task.
```

### Closing out

Your plan execution workflow loads these sections of `closing-out-primitives` after the last task:

- § Close-out pass, to write the evaluations, the status and the provenance.
- § What to report, to tell you what changed in the primitives tree.
- § When finished work is revised, when you ask for a change to finished work. The agent decides if the change is a bug fix or a change of intent.

```text
When docs/primitives/ exists, follow closing-out-primitives § Close-out pass, § What to report and § When finished work is revised.
```

### Reviewing

Your review workflow loads these sections of `reviewing-primitives`:

- § Inputs, to read the capability doc and the command output.
- § Checks, to check traceability, the Intent impact block, evaluations and provenance.
- § Report section, to write the primitives section of the review.

```text
When docs/primitives/ exists, follow reviewing-primitives.
```

The agent that sends work to a reviewer loads `running-primitives-checks` § Handing the output to a reviewer. This agent runs the commands and pastes their output into the review prompt. The reviewer can then work without a shell.

```text
Before you send work to a reviewer, when docs/primitives/ exists, follow running-primitives-checks § Handing the output to a reviewer.
```

### Writing or refactoring specs

Your spec-writing workflow loads `tagging-intent`. The agent tags each example that proves an intent clause. The agent also decides if the tagged examples prove the full intent clause.

```text
When docs/primitives/ exists, follow tagging-intent.
```

Your spec-refactoring workflow also loads `reviewing-primitives` § Auditing tagged examples in a spec refactor. The agent keeps each tag on its example when examples move, merge or change.

```text
When docs/primitives/ exists, follow reviewing-primitives § Auditing tagged examples in a spec refactor.
```

## License

MIT. See `LICENSE`.
