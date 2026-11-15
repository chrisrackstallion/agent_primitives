# frozen_string_literal: true

require "spec_helper"
require "agent_primitives/evals"

# The skills' authoring contract. Malformed frontmatter does not fail anywhere
# else — the skill silently never loads, inside an agent, long after the edit.
RSpec.describe "skill authoring" do
  # An editor truncates a longer description, and it is the only text loaded
  # before a skill fires.
  let(:description_budget) { 1024 }

  # Names from the harness these skills were extracted from. A skill that still
  # leans on one cannot be followed in an app that has only this gem.
  let(:foreign) do
    %w[agent_harness_rails .mdc rails-reviewer rails-implementor rails-primitives-maintainer
       writing-rails-plans executing-rails-plan reviewing-rails-work implementing-rails-task
       refactoring-rails-specs brainstorming-rails-omakase rails-omakase-compass writing-tests
       AgentHarnessRails]
  end

  def skill_files = Dir.glob(File.join(AgentPrimitives.skills, "*/SKILL.md")).sort

  def frontmatter(path)
    YAML.safe_load(File.read(path, encoding: "UTF-8")[/\A---\n(.*?)\n---\n/m, 1].to_s) || {}
  end

  it "ships the ten skills an app imports and the one that develops this gem" do
    names = skill_files.map { |path| File.basename(File.dirname(path)) }

    expect(names).to contain_exactly(
      "primitives-format", "tagging-intent", "running-primitives-checks",
      "planning-with-primitives", "closing-out-primitives", "reviewing-primitives",
      "bootstrapping-primitives", "maintaining-primitives", "backfilling-primitives",
      "integrating-primitives", "maintaining-agent-primitives"
    )
  end

  # The format block is where an agent learns which statuses exist. A status
  # the tool accepts and the format never mentions is one no planner sets.
  it "documents exactly the statuses evals accepts" do
    format = File.read(File.join(AgentPrimitives.skills, "primitives-format/SKILL.md"), encoding: "UTF-8")

    expect(format).to include("status: #{AgentPrimitives::Evals::Capability::STATUSES.join(' | ')}")
  end

  it "gives every skill directory a SKILL.md, and puts SKILL.md nowhere deeper" do
    directories = Dir.glob(File.join(AgentPrimitives.skills, "*")).select { |path| File.directory?(path) }

    expect(directories).not_to be_empty
    expect(directories.reject { |path| File.file?(File.join(path, "SKILL.md")) }).to be_empty
    expect(Dir.glob(File.join(AgentPrimitives.skills, "*/*/**/SKILL.md"))).to be_empty
  end

  it "names each skill for its directory and describes it within the budget" do
    skill_files.each do |path|
      skill = frontmatter(path)

      expect(skill["name"]).to eq(File.basename(File.dirname(path))), path
      expect(skill["description"].to_s).not_to be_empty, path
      expect(skill["description"].length).to be <= description_budget, path
    end
  end

  it "stands alone, citing nothing from the harness it was extracted from" do
    Dir.glob(File.join(AgentPrimitives.skills, "**/*.md")).each do |path|
      body = File.read(path, encoding: "UTF-8")

      expect(foreign.select { |name| body.include?(name) }).to be_empty, path
    end
  end

  it "cites a reference file only where one exists" do
    skill_files.each do |path|
      File.read(path, encoding: "UTF-8").scan(%r{references/[\w.-]+\.md}).uniq.each do |reference|
        owners = Dir.glob(File.join(AgentPrimitives.skills, "*", reference))

        expect(owners).not_to be_empty, "#{path} cites #{reference}"
      end
    end
  end

  # `skill` § Heading is how one skill sends an agent into another. Rename the
  # heading and the citation points at nothing, with every spec still green.
  # Matched as a prefix, because prose runs on after the heading. Headings
  # inside code fences are examples, not sections, and are left out: a fenced
  # `## Intent` would otherwise vouch for every citation that starts "Intent".
  it "cites only sections that exist in the skill it names" do
    headings = skill_files.to_h do |path|
      body = File.read(path, encoding: "UTF-8").gsub(/^(`{3,}|~{3,}).*?^\1\s*$/m, "")
      [ File.basename(File.dirname(path)), body.scan(/^#+\s+(.+?)\s*$/).flatten.map { |h| section(h) } ]
    end

    Dir.glob(File.join(AgentPrimitives.skills, "**/*.md")).each do |path|
      prose = File.read(path, encoding: "UTF-8").gsub(/\s*\n\s*/, " ")

      # A lookahead, so a run of citations (`a` § X, `b` § Y) checks each one
      # rather than swallowing the second into the first's capture.
      prose.scan(/`([a-z-]+)`\**(?: skill)?\s+§\s+(?=([^§|]+))/).each do |name, cited|
        next unless headings.key?(name)

        expect(headings[name].any? { |heading| section(cited).start_with?(heading) })
          .to be(true), "#{path} cites #{name} § #{cited[0, 60]}"
      end
    end
  end

  def section(text) = text.delete("`*").sub(/\A\d+\.\s*/, "").strip
end
