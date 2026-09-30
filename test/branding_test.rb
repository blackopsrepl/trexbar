# frozen_string_literal: true

require "minitest/autorun"
require "open3"
require "json"
require "tmpdir"

class BrandingTest < Minitest::Test
  BIN = File.expand_path("../bin/trexbar", __dir__)

  def test_public_command_uses_trexbar_identity
    assert File.executable?(BIN), "bin/trexbar must be executable"
    output, status = Open3.capture2(BIN, "help")

    assert status.success?
    assert_match(/^trexbar commands:/, output)
  end

  def test_default_config_uses_trexbar_directories
    assert File.executable?(BIN), "bin/trexbar must be executable"
    Dir.mktmpdir do |home|
      output, status = Open3.capture2({ "HOME" => home }, BIN, "config", "init")

      assert status.success?
      config = JSON.parse(output)
      assert File.file?(File.join(home, ".config", "trexbar", "config.json"))
      assert_equal File.join(home, ".local", "state", "trexbar"), config.dig("runtime", "stateDir")
      assert_equal File.join(home, ".local", "share", "trexbar", "frontend", "quickshell", "shell.qml"), config.dig("runtime", "quickShellShell")
    end
  end
end
