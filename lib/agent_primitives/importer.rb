# frozen_string_literal: true

require "fileutils"
require_relative "../agent_primitives"

module AgentPrimitives
  # Copies this gem's skills into a directory an editor reads skills from.
  #
  # Additive by design: it writes its own files and nothing else. It never
  # deletes, so a skill the app keeps beside these is safe, and a file this gem
  # stops shipping stays until someone removes it — the CHANGELOG names those.
  class Importer
    Result = Struct.new(:created, :updated, keyword_init: true) do
      def written = created + updated
    end

    def initialize(destination:, source: AgentPrimitives.skills)
      @destination = destination
      @source = source
    end

    def run
      raise Error, "no such directory: #{@destination}" unless Dir.exist?(@destination)

      result = Result.new(created: [], updated: [])
      files.each { |relative| copy(relative, result) }
      result
    end

    private

    def files
      Dir.glob("**/*", base: @source)
         .select { |relative| File.file?(File.join(@source, relative)) }
         .reject { |relative| AgentPrimitives.dev_only?(relative) }
         .sort
    end

    def copy(relative, result)
      target = File.join(@destination, relative)
      body = File.binread(File.join(@source, relative))
      existed = File.exist?(target)
      return if existed && File.binread(target) == body

      FileUtils.mkdir_p(File.dirname(target))
      File.binwrite(target, body)
      (existed ? result.updated : result.created) << relative
    end
  end
end
