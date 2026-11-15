---
name: integrating-primitives
description: >-
  Wire the imported agent_primitives skills into an app's own workflow: its
  planning, implementing, reviewing, spec-writing and brainstorming skills, its
  agent definitions, and its always-loaded rules. Each gets a one-line hook
  that names the right primitives skill and section at the step where it
  applies. Surveys first, asks the human which files to touch, and shows every
  edit for approval before writing it. Use after `agent_primitives import`,
  after a re-import adds a skill, or when the user says integrate, wire up, or
  hook in the primitives skills.
---

# Integrating primitives (hooks into the app's own workflow)

**Announce:** "I'm using the integrating-primitives skill."

<objective>
Each of the app's workflow files gains a hook at the step where a primitives
skill applies. The hook names the skill and section, and nothing else. The
primitives rules keep one home, in the imported skills, and the app's files
keep theirs. No file changes until the human has seen the edit and said yes.
</objective>

## Hard rules

- **Ask, show, then write.** Nothing is written until the human has confirmed
  the file list (§ 2) and approved that file's edit (§ 4). "Looks fine
  overall" is not approval of a specific edit.
- **A hook names; it never restates.** One or two sentences: the condition,
  the skill by name in bold backticks, and, where § Hook map gives one, the
  `§` heading copied exactly from that skill. No primitives rule text, and no path to a skill file. The import
  directory is the app's choice, and a copied rule drifts from its source.
- **Every hook is conditional:** "When the app has a `docs/primitives/` tree,
  follow …". Without a tree, the workflow still reads correctly.
- **Never edit the imported skills.** `agent_primitives import` overwrites
  them, so a change made there is lost on the next import.
- **Idempotent.** A file that already names the skill at that step needs
  nothing. Say so and move on.
- **Do not commit.** The human reviews `git diff` and commits.

## 1. Preconditions

- Find `primitives-format/SKILL.md` in the app's skills directories (§ 2 lists
  the usual ones). If it isn't there, stop and ask the human to run
  `agent_primitives import <skills directory>` first. A hook naming a skill
  the editor cannot load is a dead link.
- A missing `docs/primitives/` tree is fine, because the hooks are
  conditional. Say that `bootstrapping-primitives` sets one up, and ask
  whether to continue.

## 2. Survey, then confirm the file list

Read only. Look in:

| Kind | Usual places |
|---|---|
| Skills | `.claude/skills/*/SKILL.md`, `.cursor/skills/*/SKILL.md`, `.agents/skills/*/SKILL.md`, and any directory the human names |
| Agent definitions | `.claude/agents/*.md`, `.cursor/agents/*.md` |
| Rules and always-loaded instructions | `CLAUDE.md`, `AGENTS.md`, `.github/copilot-instructions.md`, `.cursor/rules/` |

A skills tree exposed to two editors through symlinks is one set of files, so
dedupe by real path. Leave out the imported primitives skills themselves.

Classify each file by the workflow step it drives, judged from what it
instructs rather than from its name, using § Hook map. One file can drive
several steps. Leave out files that match no step.

Present one list: each file, the steps it drives, the hooks proposed, and
any existing primitives text found (§ 3). Then ask, with the structured
question tool where the editor has one:

- Is a file missing — a workflow you run that this list does not show?
- Is a file misclassified, or one you do not want touched?

Go on only with the list the human confirms.

## 3. Find what is already there

For each confirmed file, at each step it drives:

- **Hook present.** The file already names the skill at that step, so there
  is nothing to do.
- **Embedded primitives text.** The file carries the rules itself, for
  example `intent:` tag mechanics, `evaluations:` rows, status flips,
  provenance line formats, an Intent impact block, or `evals`/`guard`/`proofs`
  under an older executable name. That is a second home that will drift.
  Propose replacing it with the hook (§ 4).
- **Nothing.** Propose a hook.

If you can't tell whether a passage is primitives text or the app's own rule
in similar words, ask. Never guess at a deletion.

## 4. Propose and confirm, one file at a time

For each file, show:

- **Where:** the heading and the line the hook follows. Place it at the step
  where the work happens: the gate before drafting, the verify step after
  each task, the close-out at the end. Never in an appendix the agent reads
  after the fact.
- **What:** the exact text to insert.
- **Replacing:** the passage to remove, verbatim, next to the hook that
  replaces it.

Ask: apply, change the wording or placement, or skip this file. Write only
on "apply", and show the edit again after any change. A replacement and an
addition in the same file are approved separately, because the human may want
the hook without losing their own text.

## 5. Rules and always-loaded files

An editor that attaches rules by path, as Cursor does from `.cursor/rules/`,
loads a skill only when something names it. Offer one stub per path pattern.
Each stub names only the skill to load:

| Path pattern | Skill named |
|---|---|
| `docs/primitives/**` | `primitives-format` |
| `docs/primitives/**`, `spec/**/*.rb` | `running-primitives-checks` |
| `spec/**/*.rb`, `docs/primitives/**` | `tagging-intent` |

```markdown
---
description: >-
  Intent tags on RSpec examples — load the tagging-intent skill when specs
  interact with a docs/primitives/ tree.
globs: spec/**/*.rb, docs/primitives/**
alwaysApply: false
---

# Tagging intent

When the app has a `docs/primitives/` tree, follow the **`tagging-intent`**
skill before writing, moving, merging, or deleting a spec. No tree → nothing
here applies.
```

In `CLAUDE.md` or `AGENTS.md`, add one line to the section that lists skills
or workflow. Don't add a new section that restates the tree. The same
confirm-first flow as § 4 applies.

## 6. Verify and report

- Every hook names a skill that is in the import directory, and, where it
  cites one, a `§` heading that skill really has. Grep each one.
- `git status` shows changes only in the confirmed files and in stubs the
  human approved. No imported skill is modified.
- Report three lists: files changed (hook added or passage replaced), files
  skipped and why, and hook-map steps no file hosts. For example: "no review
  skill found, so `reviewing-primitives` is not wired." The third list is the
  gap the human still owns.

## Hook map

| Workflow step | Hook names | Place it |
|---|---|---|
| Shaping a feature or writing a requirements spec | `planning-with-primitives` § In a requirements spec | before approaches are proposed |
| The spec's intent block | `planning-with-primitives` § Intent (in the spec) | where the spec template lists outcomes |
| Writing a plan | `planning-with-primitives` § Primitives gate | before any task is drafted |
| The plan header | `planning-with-primitives` § Intent impact block | in the header template |
| Plan tasks | `planning-with-primitives` § Citing clauses in tasks | in the task template and the self-review |
| Plan approved | `planning-with-primitives` § At final approval | after the plan's last review approves |
| Plan revised | `planning-with-primitives` § When the plan is revised | in the revision procedure |
| Handing work to a reviewer | `running-primitives-checks` § Handing the output to a reviewer | where the reviewer's inputs are assembled |
| Starting to run a plan | `closing-out-primitives` § Before starting work | before the first task |
| Implementing one task from an excerpt | `closing-out-primitives` § Working from an excerpt | at task start |
| Finishing one task | `closing-out-primitives` § Verifying one task | before the task reports done |
| Fixing finished work after feedback | `closing-out-primitives` § When finished work is revised | in the fix loop |
| Finishing a plan | `closing-out-primitives` § Close-out pass, then `closing-out-primitives` § What to report | after the last task approves |
| Reviewing a plan or a change | `reviewing-primitives` § Inputs, `reviewing-primitives` § Checks, `reviewing-primitives` § Report section | in the review checklist and the report template |
| Refactoring specs | `reviewing-primitives` § Auditing tagged examples in a spec refactor | before any example moves or merges |
| Writing tests | `tagging-intent` | at the end of the spec checklist |
| Pre-handoff checks | `running-primitives-checks` | where the app's other checks are listed |

An agent definition that runs one of these steps itself gets the same hook
as the skill for that step. An agent that only delegates to a skill that is
already hooked needs nothing.

## Related

- **No tree yet:** `bootstrapping-primitives`
- **The tree's format:** `primitives-format`
- **The commands the hooks invoke:** `running-primitives-checks`
