# frozen_string_literal: true

require "fileutils"
require "json"

module Trexbar
  module Core
    module Config
      module_function

      def default_config_path
        File.join(Dir.home, ".config", "trexbar", "config.json")
      end

      def default_config
        {
          version: 1,
          runtime: {
            stateDir: File.join(Dir.home, ".local", "state", "trexbar"),
            refreshSeconds: 5,
            waybarSignal: 11,
            trexCommand: default_trex_command,
            quickShellCommand: "quickshell",
            quickShellShell: File.join(Dir.home, ".local", "share", "trexbar", "frontend", "quickshell", "shell.qml")
          },
          display: {
            maxSessions: 8,
            staleAfterSeconds: 15
          }
        }
      end

      def init_config(path = default_config_path)
        config = normalize_config(default_config)
        save_config(config, path)
        config
      end

      def load_config(path = default_config_path)
        return normalize_config(default_config) unless File.file?(File.expand_path(path))

        normalize_config(JSON.parse(File.read(File.expand_path(path)), symbolize_names: true))
      rescue JSON::ParserError => e
        raise "Invalid trexbar config #{path}: #{e.message}"
      end

      def save_config(config, path = default_config_path)
        path = File.expand_path(path)
        FileUtils.mkdir_p(File.dirname(path))
        atomic_write_json(path, normalize_config(config))
      end

      def validate_config(config)
        issues = []
        runtime = config.fetch(:runtime, {})
        display = config.fetch(:display, {})

        issues << issue(:error, "runtime.stateDir", "must be set") if runtime[:stateDir].to_s.strip.empty?
        issues << issue(:error, "runtime.trexCommand", "must be set") if runtime[:trexCommand].to_s.strip.empty?
        issues << issue(:error, "runtime.quickShellCommand", "must be set") if runtime[:quickShellCommand].to_s.strip.empty?
        issues << issue(:error, "runtime.refreshSeconds", "must be at least 1") if runtime[:refreshSeconds].to_i < 1
        issues << issue(:error, "runtime.waybarSignal", "must be between 1 and 31") unless (1..31).cover?(runtime[:waybarSignal].to_i)
        issues << issue(:error, "display.maxSessions", "must be at least 1") if display[:maxSessions].to_i < 1
        issues << issue(:error, "display.staleAfterSeconds", "must be at least 1") if display[:staleAfterSeconds].to_i < 1

        issues
      end

      def normalize_config(config)
        merged = deep_merge(default_config, symbolize(config || {}))
        merged[:runtime][:refreshSeconds] = merged[:runtime][:refreshSeconds].to_i
        merged[:runtime][:waybarSignal] = merged[:runtime][:waybarSignal].to_i
        merged[:display][:maxSessions] = merged[:display][:maxSessions].to_i
        merged[:display][:staleAfterSeconds] = merged[:display][:staleAfterSeconds].to_i
        merged
      end

      def issue(severity, field, message)
        { severity: severity.to_s, field: field, message: message }
      end

      def default_trex_command
        cargo_trex = File.join(Dir.home, ".cargo", "bin", "trex")
        File.executable?(cargo_trex) ? cargo_trex : "trex"
      end

      def atomic_write_json(path, payload)
        temp_path = "#{path}.tmp.#{$$}"
        File.write(temp_path, "#{JSON.pretty_generate(payload)}\n")
        File.chmod(0o600, temp_path)
        File.rename(temp_path, path)
        File.chmod(0o600, path)
      ensure
        FileUtils.rm_f(temp_path) if temp_path && File.exist?(temp_path)
      end

      def symbolize(value)
        case value
        when Hash
          value.each_with_object({}) { |(key, inner), out| out[key.to_sym] = symbolize(inner) }
        when Array
          value.map { |inner| symbolize(inner) }
        else
          value
        end
      end

      def deep_merge(base, override)
        base.merge(override) do |_key, old_value, new_value|
          old_value.is_a?(Hash) && new_value.is_a?(Hash) ? deep_merge(old_value, new_value) : new_value
        end
      end
    end
  end
end
