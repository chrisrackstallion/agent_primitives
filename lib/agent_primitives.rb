# frozen_string_literal: true

require_relative "agent_primitives/version"

# Tooling and skills for a docs/primitives/ tree: capability docs whose intent
# clauses are proven by tagged RSpec examples.
module AgentPrimitives
  SKILLS_DIR = "skills"

  # Skills that develop this repo rather than a consuming app. Dropped from
  # `import` and from the gem; the gemspec repeats the list literally.
  DEV_ONLY = %w[maintaining-agent-primitives].freeze

  class Error < StandardError; end

  class << self
    def root = File.expand_path("..", __dir__)

    def skills = File.join(root, SKILLS_DIR)

    # True for a skills-relative path that exists only to develop this repo.
    def dev_only?(relative)
      DEV_ONLY.any? { |name| relative == name || relative.start_with?("#{name}/") }
    end
  end
end
