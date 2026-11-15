# frozen_string_literal: true

require "fileutils"
require "tmpdir"
require "json"
require "yaml"

require_relative "../lib/agent_primitives"
require_relative "../lib/agent_primitives/cli"

module ProjectHelpers
  def project = @project
end

RSpec.configure do |config|
  config.expect_with(:rspec) { |c| c.syntax = :expect }
  config.disable_monkey_patching!
  config.order = :random
  config.include ProjectHelpers

  # Every example gets an empty project directory to build a tree in.
  config.around do |example|
    Dir.mktmpdir("primitives-spec") do |dir|
      @project = dir
      example.run
    end
  end
end
