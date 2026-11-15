# frozen_string_literal: true

require "spec_helper"
require "agent_primitives/importer"

RSpec.describe AgentPrimitives::Importer do
  # A stand-in for the gem's skills/, so these examples do not move when a
  # skill is added or renamed.
  let(:source) { File.join(project, "gem-skills") }
  let(:destination) { File.join(project, "app-skills") }

  def write(root, relative, body)
    path = File.join(root, relative)
    FileUtils.mkdir_p(File.dirname(path))
    File.write(path, body)
  end

  def import = described_class.new(destination: destination, source: source).run

  before do
    write source, "tagging-intent/SKILL.md", "# tagging\n"
    write source, "maintaining-primitives/references/templates.md", "# templates\n"
    write source, "maintaining-agent-primitives/SKILL.md", "# dev only\n"
    FileUtils.mkdir_p(destination)
  end

  it "copies every shipped skill file, nested references included" do
    result = import

    expect(result.created).to contain_exactly("tagging-intent/SKILL.md",
                                              "maintaining-primitives/references/templates.md")
    expect(File.read(File.join(destination, "tagging-intent/SKILL.md"))).to eq("# tagging\n")
  end

  it "leaves the skill that only develops this gem behind" do
    import

    expect(Dir).not_to exist(File.join(destination, "maintaining-agent-primitives"))
  end

  it "adds to a directory without touching what is already there" do
    write destination, "writing-models/SKILL.md", "# the app's own\n"
    write destination, "tagging-intent/notes.md", "# kept\n"

    import

    expect(File.read(File.join(destination, "writing-models/SKILL.md"))).to eq("# the app's own\n")
    expect(File.read(File.join(destination, "tagging-intent/notes.md"))).to eq("# kept\n")
  end

  it "overwrites its own file when the gem's copy has changed" do
    write destination, "tagging-intent/SKILL.md", "# stale\n"

    result = import

    expect(result.updated).to eq([ "tagging-intent/SKILL.md" ])
    expect(File.read(File.join(destination, "tagging-intent/SKILL.md"))).to eq("# tagging\n")
  end

  it "reports nothing written on a second run" do
    import
    result = import

    expect(result.created).to be_empty
    expect(result.updated).to be_empty
  end

  it "refuses a destination that does not exist" do
    FileUtils.rm_rf(destination)

    expect { import }.to raise_error(AgentPrimitives::Error, /no such directory/)
  end
end
