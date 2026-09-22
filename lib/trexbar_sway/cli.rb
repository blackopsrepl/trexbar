# frozen_string_literal: true

require "json"

module TrexbarSway
  module CLI
    module_function

    def run(argv = ARGV)
      command = argv.first&.start_with?("-") ? "help" : (argv.shift || "help")
      args = parse_args(argv)
      config_path = args[:config] || Core::Config.default_config_path

      case command
      when "config"
        run_config_command(args, config_path)
      when "daemon"
        Runtime::Daemon.run(config_path, once: args[:once])
        0
      when "help"
        puts usage
        0
      when "panel"
        Runtime::QuickShell.open(config_path)
        0
      when "refresh"
        snapshot = Runtime::Daemon.refresh(config_path)
        print_json_if_requested(snapshot, args)
        0
      when "snapshot"
        snapshot = Runtime::Daemon.refresh(config_path)
        print_json(snapshot, args)
        0
      when "ui"
        run_ui_command(args, config_path)
      when "waybar"
        run_waybar_command(args, config_path)
      when "omarchy"
        run_omarchy_command(args, config_path)
      else
        raise ArgumentError, "Unknown command: #{command}"
      end
    rescue StandardError => e
      warn e.message
      1
    end

    def parse_args(argv)
      args = { format: "text", once: false, pretty: false, positionals: [] }
      index = 0

      while index < argv.length
        value = argv[index]
        case value
        when "--config"
          index += 1
          args[:config] = argv[index]
        when "--format"
          index += 1
          args[:format] = argv[index] == "json" ? "json" : "text"
        when "--pretty"
          args[:pretty] = true
        when "--once"
          args[:once] = true
        when "--after"
          index += 1
          args[:after] = argv[index]
        when "--section"
          index += 1
          args[:section] = argv[index]
        when "--index"
          index += 1
          args[:index] = argv[index]
        when "--interval"
          index += 1
          args[:interval] = argv[index]
        when "--exec"
          index += 1
          args[:exec] = argv[index]
        else
          args[:positionals] << value
        end
        index += 1
      end

      args
    end

    def run_config_command(args, config_path)
      subcommand = args[:positionals].first || "validate"
      if subcommand == "init"
        print_json(Core::Config.init_config(config_path), args)
        return 0
      end

      config = Core::Config.load_config(config_path)
      issues = Core::Config.validate_config(config)
      if args[:format] == "json"
        print_json(issues, args)
      elsif issues.empty?
        puts "Config valid."
      else
        issues.each { |issue| puts "#{issue[:severity].upcase}: #{issue[:field]} #{issue[:message]}" }
      end
      issues.any? { |issue| issue[:severity] == "error" } ? 1 : 0
    end

    def run_ui_command(args, config_path)
      subcommand = args[:positionals].first || "open"
      payload = case subcommand
                when "open"
                  Runtime::QuickShell.open(config_path)
                  Runtime::QuickShell.status(config_path)
                when "close"
                  Runtime::QuickShell.close(config_path)
                  Runtime::QuickShell.status(config_path)
                when "toggle"
                  Runtime::QuickShell.toggle(config_path)
                when "status"
                  Runtime::QuickShell.status(config_path)
                else
                  raise ArgumentError, "Unknown ui subcommand: #{subcommand}"
                end
      print_json_if_requested(payload, args)
      0
    end

    def run_waybar_command(args, config_path)
      subcommand = args[:positionals].first || "render"
      case subcommand
      when "render"
        Runtime::Waybar.render(config_path)
      when "refresh"
        Runtime::Waybar.refresh(config_path)
      when "panel", "open"
        Runtime::Waybar.open_panel(config_path)
      else
        raise ArgumentError, "Unknown waybar subcommand: #{subcommand}"
      end
      0
    end

    def run_omarchy_command(args, config_path)
      subcommand = args[:positionals].first || "status"
      result = case subcommand
               when "install"
                 Runtime::Omarchy.install(
                   config_path,
                   after: args[:after],
                   section: args[:section],
                   index: args[:index],
                   interval: args[:interval] || Runtime::Omarchy::DEFAULT_INTERVAL,
                   bin: args[:exec]
                 )
               when "remove"
                 Runtime::Omarchy.remove
               when "status"
                 Runtime::Omarchy.status
               else
                 raise ArgumentError, "Unknown omarchy subcommand: #{subcommand}"
               end
      print_json_if_requested(result, args)
      unless args[:format] == "json"
        puts describe_omarchy_result(subcommand, result)
      end
      0
    end

    def describe_omarchy_result(subcommand, result)
      case subcommand
      when "install"
        "Installed #{Runtime::Omarchy::MODULE_ID} module in #{result[:shellConfig]} " \
          "(#{result[:section]}[#{result[:index]}], seeded from #{result[:seededFrom]})"
      when "remove"
        result[:removed] ? "Removed #{Runtime::Omarchy::MODULE_ID} module from #{result[:shellConfig]}" : result[:reason]
      else
        if result[:installed]
          "#{Runtime::Omarchy::MODULE_ID} module installed at #{result[:shellConfig]} " \
            "(#{result[:section]}[#{result[:index]}])"
        else
          "#{Runtime::Omarchy::MODULE_ID} module not installed"
        end
      end
    end

    def print_json_if_requested(payload, args)
      print_json(payload, args) if args[:format] == "json"
    end

    def print_json(payload, args)
      puts(args[:pretty] ? JSON.pretty_generate(payload) : JSON.generate(payload))
    end

    def usage
      <<~TEXT
        trexbar-sway commands:
          config init|validate
          snapshot
          refresh
          daemon [--once]
          panel
          ui open|close|toggle|status
          waybar render|refresh|panel
          omarchy install|remove|status
      TEXT
    end
  end
end
