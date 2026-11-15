# frozen_string_literal: true

require "spec_helper"
require "stringio"
require "open3"

RSpec.describe AgentPrimitives::CLI do
  def run(*argv)
    out = StringIO.new
    err = StringIO.new
    status = described_class.new(argv, out: out, err: err).run
    [ status, out.string, err.string ]
  end

  [ "-h", "--help", "help" ].each do |invocation|
    it "prints usage to stdout and exits 0 for #{invocation}" do
      status, out, err = run(invocation)

      expect(status).to eq(0)
      expect(out).to include("usage: agent_primitives")
      expect(err).to be_empty
    end
  end

  it "prints usage to stderr and exits 1 with no command" do
    status, out, err = run

    expect(status).to eq(1)
    expect(out).to be_empty
    expect(err).to include("usage: agent_primitives")
  end

  it "names an unknown command before the usage" do
    status, _, err = run("evls")

    expect(status).to eq(1)
    expect(err).to include("unknown command: evls")
    expect(err).to include("usage: agent_primitives")
  end

  it "reports an unknown option without a backtrace" do
    status, _, err = run("version", "--frobnicate")

    expect(status).to eq(1)
    expect(err).to include("error: invalid option: --frobnicate")
  end

  it "rejects a stray argument instead of ignoring it" do
    status, _, err = run("version", "extra")

    expect(status).to eq(1)
    expect(err).to include("unexpected argument: extra")
  end

  it "prints the version" do
    status, out, = run("version")

    expect(status).to eq(0)
    expect(out.strip).to eq(AgentPrimitives::VERSION)
  end

  # Guard is advisory by construction: a non-zero exit would make every notice a
  # gate, and the checks in it each have an innocent cause as well as a
  # suspicious one.
  describe "guard" do
    def primitives_repo
      Open3.capture3("git", "-C", project, "init", "--quiet")
      Open3.capture3("git", "-C", project, "config", "user.email", "spec@example.test")
      Open3.capture3("git", "-C", project, "config", "user.name", "Spec")
      FileUtils.mkdir_p(File.join(project, "docs/primitives/capabilities"))
      File.write(File.join(project, "docs/primitives/capabilities/comment_threads.md"), <<~DOC)
        ---
        status: built
        intent:
          - id: I1
            clause: A reader can reply to any comment.
        ---
        # Comment threads
      DOC
      Open3.capture3("git", "-C", project, "add", "-A")
      Open3.capture3("git", "-C", project, "-c", "commit.gpgsign=false", "commit", "--quiet", "-m", "base")
    end

    it "exits 0 and prints the notices when the record changed" do
      primitives_repo
      File.write(File.join(project, "docs/primitives/capabilities/comment_threads.md"), <<~DOC)
        ---
        status: built
        intent:
          - id: I1
            clause: A signed-in reader can reply to any comment.
        ---
        # Comment threads
      DOC

      status, out, err = run("guard", "--path", project)

      expect(status).to eq(0)
      expect(out).to include("[intent/rewritten]").and include("1 notice for review")
        .and include("was:  A reader can reply to any comment.")
        .and include("now:  A signed-in reader can reply to any comment.")
      expect(err).to be_empty
    end

    it "exits 0 and says so when nothing moved" do
      primitives_repo

      status, out, = run("guard", "--path", project)

      expect(status).to eq(0)
      expect(out).to include("no change to intent or the specs that prove it")
    end

    it "reports as JSON for a hook to read" do
      primitives_repo

      status, out, = run("guard", "--path", project, "--format", "json")

      expect(status).to eq(0)
      expect(JSON.parse(out)).to include("notices" => 0, "capabilities" => 1)
    end

    # The one case that is a failure rather than a notice: the comparison could
    # not be made at all.
    it "exits 1 when there is no revision to compare against" do
      FileUtils.mkdir_p(File.join(project, "docs/primitives/capabilities"))
      File.write(File.join(project, "docs/primitives/capabilities/comment_threads.md"), "---\nstatus: built\nintent:\n  - id: I1\n    clause: A reader can reply.\n---\n")

      status, _, err = run("guard", "--path", project)

      expect(status).to eq(1)
      expect(err).to include("not a git repository")
    end

    it "rejects a format it cannot print" do
      status, _, err = run("guard", "--path", project, "--format", "xml")

      expect(status).to eq(1)
      expect(err).to include("format must be text or json")
    end
  end

  # Proofs is a lookup, not a check: the exit code is 0 whatever it finds, because
  # most examples in a spec file carry no tag by design and a tagged count is a
  # number to compare with the plan, not a verdict.
  describe "proofs" do
    def stages
      FileUtils.mkdir_p(File.join(project, "docs/primitives/capabilities"))
      File.write(File.join(project, "docs/primitives/capabilities/project_stages.md"), <<~DOC)
        ---
        status: built
        intent:
          - id: I3
            clause: Only a published stage accepts entries.
            evaluations:
              - spec/policies/long_list_policy_spec.rb
        ---
        # Project stages
      DOC
      FileUtils.mkdir_p(File.join(project, "spec/policies"))
      File.write(File.join(project, "spec/policies/long_list_policy_spec.rb"), <<~SPEC)
        RSpec.describe LongListPolicy do
          it "denies entry to a draft stage" do
            expect(policy).not_to permit_action(:accept_entry)
          end

          it "denies entry to an archived stage", intent: "project_stages#I3" do
            expect(policy).not_to permit_action(:accept_entry)
          end
        end
      SPEC
    end

    it "prints one line per clause under its capability and exits 0" do
      stages

      status, out, err = run("proofs", "--path", project)

      expect(status).to eq(0)
      expect(out).to include("project_stages (built)")
        .and include("I3  Only a published stage accepts entries.")
        .and include("1 tagged example")
      expect(err).to be_empty
    end

    it "shows each evaluation file with its tagged examples" do
      stages

      _, out, = run("proofs", "project_stages", "--path", project)

      expect(out).to include("spec/policies/long_list_policy_spec.rb — 1 tagged example")
        .and include("denies entry to an archived stage")
        .and include("1 assertion")
    end

    # The output that made a group tag look like a real, weak proof: the
    # `describe` line printed among the examples with no description and no
    # assertions, and nothing in the footer about it.
    it "names a tag sitting on a group instead of printing it as a proof" do
      stages
      File.write(File.join(project, "spec/policies/long_list_policy_spec.rb"), <<~SPEC)
        RSpec.describe LongListPolicy do
          describe "denials", intent: "project_stages#I3" do
            it "denies entry to a draft stage" do
              expect(policy).not_to permit_action(:accept_entry)
            end
          end
        end
      SPEC

      status, out, = run("proofs", "project_stages#I3", "--path", project)

      expect(status).to eq(0)
      expect(out).to include("spec/policies/long_list_policy_spec.rb — 0 tagged examples")
        .and include("tag proving nothing: spec/policies/long_list_policy_spec.rb:2 sits on `describe` — no example under it")
        .and include("1 tag in the suite is on a group rather than an example")
      expect(out).not_to include("(no description)")
    end

    it "counts each kind of unusable tag in one footer line" do
      stages
      FileUtils.mkdir_p(File.join(project, "spec/requests"))
      File.write(File.join(project, "spec/requests/stages_spec.rb"), <<~SPEC)
        RSpec.describe "Stages", type: :request do
          it "names no clause", intent: "project_stages#I9" do
            expect(response).to be_forbidden
          end

          it "carries half a tag", intent: "project_stages" do
            expect(response).to be_forbidden
          end
        end
      SPEC

      _, out, = run("proofs", "--path", project)

      expect(out).to include("2 tags in the suite are not usable proof — 1 naming no active clause, " \
                             "1 not in `<capability>#I<n>` form; `agent_primitives evals` reports each")
    end

    # A reader holding the plan already knows which example is missing from the
    # tagged list, so the text stays tagged-only at every scope — printed,
    # untagged examples drowned the report in any real spec file. JSON keeps
    # them for close-out steps and reviewers.
    it "keeps untagged examples out of the text and in the JSON" do
      stages

      _, one_clause, = run("proofs", "project_stages#I3", "--path", project)
      _, json, = run("proofs", "project_stages#I3", "--format", "json", "--path", project)

      expect(one_clause).not_to include("denies entry to a draft stage")
      untagged = JSON.parse(json).dig("proofs", 0, "files", 0, "untagged")
      expect(untagged.map { |example| example["description"] }).to include("denies entry to a draft stage")
    end

    it "reports as JSON for a reviewer or close-out step to read" do
      stages

      status, out, = run("proofs", "project_stages#I3", "--format", "json", "--path", project)

      expect(status).to eq(0)
      expect(JSON.parse(out))
        .to include("clauses" => 1, "tagged_examples" => 1, "detail" => "detail",
                    "unresolved_tags" => 0, "misplaced_tags" => 0, "malformed_tags" => 0)
    end

    it "names what a scope it cannot parse should look like" do
      stages

      status, _, err = run("proofs", "Project Stages", "--path", project)

      expect(status).to eq(1)
      expect(err).to include("reads `<capability>` or `<capability>#I<n>`")
    end

    it "still rejects a second positional argument" do
      status, _, err = run("proofs", "project_stages", "extra", "--path", project)

      expect(status).to eq(1)
      expect(err).to include("unexpected argument: extra")
    end
  end

  describe "import" do
    it "writes the gem's skills and lists them as new" do
      status, out, = run("import", project)

      expect(status).to eq(0)
      expect(out).to include("new:", "tagging-intent/SKILL.md")
      expect(File).to exist(File.join(project, "tagging-intent/SKILL.md"))
    end

    it "says so when everything is already current" do
      run("import", project)
      status, out, = run("import", project)

      expect(status).to eq(0)
      expect(out).to include("already current")
    end

    it "requires a destination" do
      status, _, err = run("import")

      expect(status).to eq(1)
      expect(err).to include("import needs a directory")
    end
  end
end
