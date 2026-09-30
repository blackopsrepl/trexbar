# frozen_string_literal: true

require_relative "test_helper"

class DaemonTest < Minitest::Test
  include TrexbarTestHelpers

  def test_refresh_writes_snapshot_from_fake_trex
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: backend_payload)
      config_path = File.join(dir, "config.json")
      config = Trexbar::Core::Config.normalize_config(
        runtime: {
          stateDir: File.join(dir, "state"),
          trexCommand: fake,
          waybarSignal: 0
        }
      )
      Trexbar::Core::Config.save_config(config, config_path)

      snapshot = Trexbar::Runtime::Daemon.refresh(config_path)

      assert_equal "healthy", snapshot[:status]
      assert File.file?(Trexbar::Runtime::State.snapshot_path(config))
    end
  end

  def test_refresh_writes_error_snapshot_on_backend_failure
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: {}, exit_status: 1, stderr: "no trex")
      config_path = File.join(dir, "config.json")
      config = Trexbar::Core::Config.normalize_config(
        runtime: {
          stateDir: File.join(dir, "state"),
          trexCommand: fake,
          waybarSignal: 0
        }
      )
      Trexbar::Core::Config.save_config(config, config_path)

      snapshot = Trexbar::Runtime::Daemon.refresh(config_path)

      assert_equal "error", snapshot[:status]
      assert_match(/no trex/, snapshot.dig(:errors, 0, :message))
    end
  end
end
