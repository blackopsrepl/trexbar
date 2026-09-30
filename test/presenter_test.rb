# frozen_string_literal: true

require_relative "test_helper"

class PresenterTest < Minitest::Test
  include TrexbarTestHelpers

  def test_builds_chip_classes
    snapshot = Trexbar::Runtime::State.build_snapshot(Trexbar::Core::Config.default_config, backend_payload)
    view = Trexbar::Runtime::Presenter.build_snapshot_view(snapshot, stale: false)

    assert_includes view.dig(:chip, :classes), "trexbar"
    assert_includes view.dig(:chip, :classes), "warning"
    assert_includes view.dig(:chip, :classes), "has-agents"
    assert_includes view.dig(:chip, :classes), "has-attached"
    assert_includes view.dig(:chip, :classes), "high-cpu"
    assert_match(/TRX 2/, view.dig(:chip, :text))
  end

  def test_surfaces_detected_agents_including_hermes
    snapshot = Trexbar::Runtime::State.build_snapshot(Trexbar::Core::Config.default_config, backend_payload)
    view = Trexbar::Runtime::Presenter.build_snapshot_view(snapshot, stale: false)

    names = view[:agents].map { |agent| agent[:processName] }
    assert_includes names, "codex"
    assert_includes names, "gemini"
    assert_includes names, "hermes"
  end

  def test_loading_payload_has_stable_classes
    config = Trexbar::Core::Config.default_config
    payload = Trexbar::Runtime::Waybar.payload(config, nil)

    assert_equal ["trexbar", "loading"], payload[:class]
    assert_match(/TRX/, payload[:text])
  end
end
