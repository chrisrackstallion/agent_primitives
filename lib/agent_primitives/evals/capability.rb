# frozen_string_literal: true

require "yaml"
require "date"

module AgentPrimitives
  module Evals
    # One parsed capability doc from docs/primitives/capabilities/.
    #
    # Intent clauses and their evaluations live in YAML frontmatter, not in prose
    # sections, so this is a parse rather than a guess:
    #
    #   ---
    #   status: built
    #   intent:
    #     - id: I1
    #       clause: A reader can reply to any comment.
    #       evaluations:
    #         - spec/system/comment_threads_spec.rb
    #     - id: I4
    #       clause: Threads never nest deeper than 3 levels.
    #       superseded_by: [ I5, I6 ]
    #       superseded_on: 2026-09-18
    #   ---
    #
    # The key is `superseded_on`, not `on`: YAML 1.1 resolves a bare `on` to the
    # boolean `true`, so an `on:` key would parse as `true` and the date would be
    # unreachable. Psych does this silently — hence the longer name.
    #
    # Structural problems are returned as findings rather than raised, because a
    # single malformed doc must not stop the rest of the tree being checked.
    class Capability
      STATUSES = %w[shaping planned built amending deprecated].freeze
      CLAUSE_ID = /\AI[1-9]\d*\z/
      FRONTMATTER = /\A---\r?\n(.*?)\r?\n---(?:\r?\n|\z)/m

      # Retired prose sections. A doc still carrying them either predates the
      # frontmatter format or was half-migrated; either way its clauses are not
      # where this tool looks, so it must fail loudly instead of reporting zero
      # clauses and passing.
      LEGACY_HEADING = /^##\s+(Intent|Evaluations)\s*$/
      LEGACY_SPECS_KEY = /^specs:/

      # One intent clause. `line` is where its `id:` sits in the source file, so
      # an offence points at the clause rather than at the top of the document.
      Clause = Struct.new(:id, :text, :evaluations, :superseded_by, :retired_on, :line,
                          keyword_init: true) do
        def active? = superseded_by.empty? && retired_on.nil?
      end

      attr_reader :path, :relative_path, :name, :status, :plan, :clauses, :findings

      def self.load_all(dir, root:)
        Dir.glob(File.join(dir, "*.md")).sort.map { |path| new(path, root: root) }
      end

      def initialize(path, root:)
        @path = path
        @root = root
        @relative_path = path.delete_prefix("#{root}/")
        @name = File.basename(path, ".md")
        @clauses = []
        @findings = []
        @source = File.read(path, encoding: "UTF-8")

        parse
      end

      def built? = status == "built"

      # Shipped, and an approved plan is changing it. Set at plan approval and
      # cleared at close-out, never inferred: nothing in this tool reads
      # provenance, which is prose and append-only.
      def amending? = status == "amending"

      # An approved plan is running against this doc. Rows are filed at
      # close-out, so its clauses can legitimately have none yet.
      def in_flight? = %w[planned amending].include?(status)

      def active_clauses = clauses.select(&:active?)

      def clause(id) = clauses.find { |c| c.id == id }

      private

      def parse
        return finding(:error, 1, "no YAML frontmatter — the capability format is frontmatter, not prose sections", "doc/malformed") unless (match = FRONTMATTER.match(@source))

        return if legacy_format?

        data = load_frontmatter(match[1])
        return if data.nil?

        @status = data["status"]
        @plan = data["plan"].to_s.strip.then { |path| path unless path.empty? }
        validate_status
        check_plan
        build_clauses(data["intent"])
      end

      # Reported before anything else: a legacy doc's clauses are in prose this
      # parser does not read, so every downstream check would be measuring an
      # empty document.
      def legacy_format?
        heading = line_of(LEGACY_HEADING)
        specs_key = line_of(LEGACY_SPECS_KEY)
        return false unless heading || specs_key

        finding(:error, heading || specs_key,
                "uses the retired prose format — move intent clauses and evaluations into frontmatter",
                "doc/legacy-format")
        true
      end

      def load_frontmatter(yaml)
        YAML.safe_load(yaml, permitted_classes: [ Date ])
            .tap { |data| return type_error unless data.is_a?(Hash) }
      rescue Psych::Exception => e
        finding(:error, 1, "frontmatter is not valid YAML (#{e.message})", "doc/malformed")
        nil
      end

      def type_error
        finding(:error, 1, "frontmatter must be a mapping with `status:` and `intent:` keys", "doc/malformed")
        nil
      end

      def validate_status
        return if STATUSES.include?(@status)

        finding(:error, line_of(/^status:/) || 1,
                "status #{@status.inspect} is not one of #{STATUSES.join(', ')}", "doc/malformed")
      end

      # `plan:` is the amendment's pointer to the plan doing it, set with
      # `status: amending` and removed with it. Absent on an amending doc, no
      # reader can tell which plan to finish. Present on any other doc, close-out
      # stopped halfway.
      def check_plan
        if amending? && plan.nil?
          finding(:error, status_line,
                  "an amending doc names the plan changing it — add `plan: docs/plans/<plan>.md`",
                  "status/plan-unnamed")
        elsif amending? && !File.file?(File.join(@root, plan))
          finding(:warning, plan_line,
                  "plan #{plan} does not exist — point `plan:` at where it moved, or record why it " \
                  "stopped and return the doc to `built`",
                  "status/plan-missing")
        elsif !amending? && plan
          finding(:error, plan_line,
                  "`plan:` belongs only on an amending doc — close-out removes it when the doc returns to `built`",
                  "status/plan-stale")
        end
      end

      def status_line = line_of(/^status:/) || 1
      def plan_line = line_of(/^plan:/) || 1

      def build_clauses(intent)
        unless intent.is_a?(Array) && !intent.empty?
          return finding(:error, line_of(/^intent:/) || 1,
                         "frontmatter has no `intent:` list — every capability doc declares at least one clause",
                         "doc/malformed")
        end

        intent.each { |entry| build_clause(entry) }
        flag_duplicate_ids
        flag_dangling_supersessions
      end

      def build_clause(entry)
        return finding(:error, 1, "every `intent:` entry must be a mapping with `id:` and `clause:`", "doc/malformed") unless entry.is_a?(Hash)

        id = entry["id"].to_s
        line = line_of(/^\s*-?\s*id:\s*#{Regexp.escape(id)}\s*$/) || 1

        return finding(:error, line, "clause id #{entry['id'].inspect} must look like I1, I2, …", "doc/malformed") unless CLAUSE_ID.match?(id)
        return finding(:error, line, "clause #{id} has no `clause:` sentence", "doc/malformed") if entry["clause"].to_s.strip.empty?

        @clauses << Clause.new(
          id: id, text: entry["clause"], line: line,
          evaluations: Array(entry["evaluations"]).map(&:to_s),
          superseded_by: Array(entry["superseded_by"]).map(&:to_s),
          retired_on: entry["retired_on"]
        )
      end

      def flag_duplicate_ids
        @clauses.group_by(&:id).each_value do |group|
          next if group.one?

          finding(:error, group.last.line,
                  "clause id #{group.first.id} appears #{group.size} times — ids are assigned once and never reused",
                  "clause/duplicate-id")
        end
      end

      def flag_dangling_supersessions
        ids = @clauses.map(&:id)

        @clauses.each do |clause|
          (clause.superseded_by - ids).each do |missing|
            finding(:error, clause.line,
                    "#{clause.id} is superseded by #{missing}, which this doc does not define",
                    "clause/dangling-supersession")
          end
        end
      end

      def line_of(pattern)
        index = @source.lines.index { |line| pattern.match?(line) }
        index && index + 1
      end

      def finding(severity, line, message, code)
        @findings << Finding.new(severity: severity, path: relative_path, line: line, column: 1,
                                 message: message, code: code)
        nil
      end
    end
  end
end
