# frozen_string_literal: true

require_relative "test_helper"

class TrexBackendTest < Minitest::Test
  include TrexbarTestHelpers

  def test_reads_trex_snapshot_json
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: backend_payload)
      config = Trexbar::Core::Config.normalize_config(runtime: { trexCommand: fake })

      snapshot = Trexbar::Core::TrexBackend.snapshot(config)

      assert_equal "healthy", snapshot[:status]
      assert_equal 2, snapshot.dig(:summary, :sessionCount)
    end
  end

  def test_raises_on_backend_failure
    Dir.mktmpdir do |dir|
      fake = write_fake_trex(dir, payload: {}, exit_status: 7, stderr: "broken")
      config = Trexbar::Core::Config.normalize_config(runtime: { trexCommand: fake })

      error = assert_raises(RuntimeError) { Trexbar::Core::TrexBackend.snapshot(config) }
      assert_match(/broken/, error.message)
    end
  end
end
