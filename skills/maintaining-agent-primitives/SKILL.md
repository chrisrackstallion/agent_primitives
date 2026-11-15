---
name: maintaining-agent-primitives
description: >-
  Change the agent_primitives gem itself — the evals, guard, and proofs tooling,
  the importer, the shipped skills, and packaging. Use when editing anything in
  this repository. Not for an app's primitives tree: maintaining-primitives
  covers that.
---

# Maintaining agent_primitives

**Announce:** "I'm using the maintaining-agent-primitives skill."

<objective>
Land a requested change to this repo so it has **exactly one home**, reaches a
consuming app through `import`, and is held by a **check** rather than by prose.
</objective>

Not shipped: `AgentPrimitives::DEV_ONLY` in `lib/agent_primitives.rb` drops
this skill from the gem and from `import`. A further dev-only path goes in that
list *and* in the gemspec's matching reject — `spec/gem_spec.rb` asserts the two
agree.

## Where the change goes

| Change | Home |
|---|---|
| What `evals`, `guard`, `proofs`, or `import` does | `lib/agent_primitives/` |
| How an agent uses the tree or the tools | `skills/*/SKILL.md` |
| A template, or an example too long to inline | `skills/*/references/*.md` |
| Consumer-facing behaviour | `README.md`, and `CHANGELOG.md` under `## [Unreleased]` |

`lib/agent_primitives/version.rb` moves at release time, not per change.

**One home, cited from everywhere else.** State a rule once, in the skill that
owns it; every other skill names that skill and section and keeps only its own
consequence. Two copies diverge, and an agent reads the stale one. Before adding
a paragraph, grep `skills/` for it — if it already exists, cite it.

## Authoring constraints

- **Skills stay flat.** Claude Code discovers exactly `skills/<name>/SKILL.md`
  and does not recurse, so a skill one level deeper is silently invisible.
  Depth is what `references/` is for.
- **Frontmatter is the discovery surface.** `name` must equal the directory,
  because a name that does not match is a name that cannot be invoked. A
  `description` carries both *what* and *when*; it is the only text loaded
  before the skill fires.
- **Cross-reference by skill name, never by path** — `primitives-format`
  § Reading contract, not a file path. An app imports these skills into
  whatever directory its editor reads, so only the name resolves everywhere.
- **Name a removed file in the CHANGELOG.** `import` only adds and overwrites
  its own files; it never deletes. A skill or reference dropped here stays in
  every app that imported it until someone removes it by hand, so the entry
  must say which path to delete.

## Prefer a check to prose

A rule a spec can settle belongs in a spec, not in a paragraph an agent may
skim. `.rubocop.yml` excludes `skills/**/*`, so the skills have no linter and
the specs below are their only mechanical gate — widen the matching spec rather
than adding a second one.

| Concern | Gate |
|---|---|
| Skill frontmatter, naming, layout, or a name from outside this gem | `spec/skills_spec.rb` |
| A new file must ship, or must not | `spec/gem_spec.rb` |
| What `import` copies, keeps, and leaves behind | `spec/importer_spec.rb` |
| A packaged install actually works | the build-and-install step in CI |

Judgment stays prose: whether a rule is right, whether a paragraph duplicates
another. Name the judgment in the change instead of inventing a check that will
be noisy and then routed around.

## Verify

```bash
bundle exec rake
```

`rake` runs the specs then RuboCop; both clean, no exceptions. Then read the
diff back: every cited skill and section exists, every rule has one home, and
the `## [Unreleased]` entry says what a consumer gets.

## Related

- **An app's primitives tree, not this repo:** `maintaining-primitives`
- **The tree's format:** `primitives-format`
