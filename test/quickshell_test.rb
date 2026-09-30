# frozen_string_literal: true

require_relative "test_helper"

module Trexbar
  module Runtime
    class QuickShellTest < Minitest::Test
      include TrexbarTestHelpers

      def test_resolved_binary_prefers_explicit_environment
        with_temp_home do |home|
          bin = write_executable(home, "explicit-trexbar")

          ENV["TREXBAR_BIN"] = bin

          assert_equal bin, QuickShell.resolved_binary
        end
      ensure
        ENV.delete("TREXBAR_BIN")
      end

      def test_resolved_binary_falls_back_to_absolute_checkout_binary
        with_temp_home do
          ENV.delete("TREXBAR_BIN")

          resolved = QuickShell.resolved_binary

          assert File.absolute_path?(resolved)
          assert File.executable?(resolved)
        end
      end

      def test_resolved_binary_ignores_blank_environment
        with_temp_home do
          ENV["TREXBAR_BIN"] = ""

          resolved = QuickShell.resolved_binary

          assert File.absolute_path?(resolved)
          refute_equal "", resolved
        end
      ensure
        ENV.delete("TREXBAR_BIN")
      end

      private

      def write_executable(dir, name)
        path = File.join(dir, name)
        File.write(path, "#!/bin/sh\nexit 0\n")
        File.chmod(0o755, path)
        path
      end
    end
  end
end
