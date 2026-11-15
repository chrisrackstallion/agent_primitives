# frozen_string_literal: true

require "spec_helper"

RSpec.describe "gem packaging" do
  let(:root) { File.expand_path("..", __dir__) }
  let(:spec) { Gem::Specification.load(File.join(root, "agent_primitives.gemspec")) }

  it "matches its require and its executable to its name" do
    expect(spec.name).to eq("agent_primitives")
    expect(spec.files).to include("lib/agent_primitives.rb", "exe/agent_primitives")
    expect(spec.executables).to contain_exactly("agent_primitives")
  end

  it "ships every library file" do
    expect(spec.files).to include(*Dir.glob("lib/**/*.rb", base: root))
  end

  it "ships neither specs nor fixtures" do
    expect(spec.files.grep(%r{\A(spec|fixtures)/})).to be_empty
  end

  it "lints against the Ruby floor the gemspec declares" do
    floor = spec.required_ruby_version.requirements.first.last
    target = YAML.safe_load_file(File.join(root, ".rubocop.yml")).dig("AllCops", "TargetRubyVersion")

    expect(target.to_s).to eq(floor.segments.first(2).join("."))
  end

  it "ships every skill but the one that develops this gem" do
    expect(spec.files).to include("skills/tagging-intent/SKILL.md")

    AgentPrimitives::DEV_ONLY.each do |name|
      expect(File.read(File.join(root, "agent_primitives.gemspec"))).to include(%("skills/#{name}/"))
      expect(spec.files.grep(%r{\Askills/#{name}/})).to be_empty
    end
  end
end
