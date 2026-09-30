# frozen_string_literal: true

require_relative "test_helper"

class ConfigTest < Minitest::Test
  include TrexbarTestHelpers

  def test_default_config_is_valid
    with_temp_home do
      config = Trexbar::Core::Config.default_config
      assert_empty Trexbar::Core::Config.validate_config(config)
    end
  end

  def test_init_writes_config
    with_temp_home do |home|
      path = File.join(home, ".config", "trexbar", "config.json")
      config = Trexbar::Core::Config.init_config(path)

      assert File.file?(path)
      assert_equal 11, config.dig(:runtime, :waybarSignal)
      assert_equal config, Trexbar::Core::Config.load_config(path)
    end
  end

  def test_invalid_interval_is_reported
    config = Trexbar::Core::Config.normalize_config(runtime: { refreshSeconds: 0 })
    issues = Trexbar::Core::Config.validate_config(config)

    assert issues.any? { |issue| issue[:field] == "runtime.refreshSeconds" }
  end
end
