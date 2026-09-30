# frozen_string_literal: true

require "json"

module Trexbar
  module Core
    module TrexBackend
      module_function

      def snapshot(config)
        command = config.dig(:runtime, :trexCommand).to_s
        result = Process.run_command(command, ["snapshot", "--json"], timeout: 15)

        unless result.success?
          message = result.stderr.to_s.strip
          message = "failed to run #{command} snapshot --json" if message.empty?
          raise message
        end

        JSON.parse(result.stdout, symbolize_names: true)
      rescue JSON::ParserError => e
        raise "invalid trex snapshot JSON: #{e.message}"
      end
    end
  end
end
