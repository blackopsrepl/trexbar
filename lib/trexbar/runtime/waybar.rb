# frozen_string_literal: true

require "json"

module Trexbar
  module Runtime
    module Waybar
      module_function

      def render(config_path, out: $stdout)
        config = Core::Config.load_config(config_path)
        snapshot = State.read_snapshot(config)
        out.puts(JSON.generate(payload(config, snapshot)))
      end

      def refresh(config_path)
        Daemon.refresh(config_path)
      end

      def open_panel(config_path)
        QuickShell.open(config_path)
      end

      def payload(config, snapshot, now = Time.now)
        unless snapshot
          return {
            text: "TRX ...",
            tooltip: "trexbar is waiting for cached data.\nMiddle click: refresh",
            class: ["trexbar", "loading"]
          }
        end

        stale = State.stale?(snapshot, config, now)
        view = Presenter.build_snapshot_view(snapshot, stale: stale, max_sessions: config.dig(:display, :maxSessions))
        chip = view[:chip] || {}

        {
          text: chip[:text] || "TRX ...",
          tooltip: Array(chip[:tooltipLines]).join("\n"),
          class: Array(chip[:classes]).uniq
        }
      end
    end
  end
end
