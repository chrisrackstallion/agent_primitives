# Changelog

## [Unreleased]

- Extracted from `agent_harness_rails` 0.2.0. `evals`, `guard`, and `proofs` behave as they did there. New: `agent_primitives import <dir>`, which adds the ten skills (`backfilling-primitives` among them, new in this gem) to a skills directory and never deletes a file.
- New status `amending`, with a `plan:` frontmatter key: a shipped capability that an approved plan is changing. Planning sets `built` → `amending` and `plan:` at final approval, and close-out sets `built` and removes `plan:`. Its clauses with no row yet, and tags pointing at them, warn (`clause/in-flight`, `tag/in-flight`). Rows it already has stay enforced. Tags on a `planned` doc's rowless clauses warn too. `status/plan-unnamed` (amending without `plan:`) and `status/plan-stale` (`plan:` on any other status) fail; `status/plan-missing` (the plan file is gone) warns.
- `evals` no longer reads provenance. It used to infer mid-amendment state from the newest provenance date, and a same-day `backfilled` line hid the `planned` line after it. A `built` doc mid-amendment now fails `clause/unproven` on its new clauses until you set `status: amending`, `plan:`, and its index line.
- `guard` ranks `amending` with `built`, so `built` → `amending` is not a downgrade. It reports `amending` → `built` as `status/closed-out`.
- Update the status line in your `docs/primitives/index.md` (and `SCHEMA.md`, if it has one) by hand: `import` does not touch the tree.
- New skill `integrating-primitives`: adds hooks for the primitives skills to an app's own planning, implementing and reviewing skills, agents and rules. It surveys first and confirms each file and each edit with you before writing. Run `agent_primitives import` again to get it.
