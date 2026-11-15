# Changelog

## [0.1.0] - 2026-11-15

- `evals` no longer reads provenance. It used to infer mid-amendment state from the newest provenance date, and a same-day `backfilled` line hid the `planned` line after it. A `built` doc mid-amendment now fails `clause/unproven` on its new clauses until you set `status: amending`, `plan:`, and its index line.
- `guard` ranks `amending` with `built`, so `built` → `amending` is not a downgrade. It reports `amending` → `built` as `status/closed-out`.
- Update the status line in your `docs/primitives/index.md` (and `SCHEMA.md`, if it has one) by hand: `import` does not touch the tree.
- New skill `integrating-primitives`: adds hooks for the primitives skills to an app's own planning, implementing and reviewing skills, agents and rules. It surveys first and confirms each file and each edit with you before writing. Run `agent_primitives import` again to get it.
