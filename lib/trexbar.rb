# frozen_string_literal: true

require_relative "trexbar/core/config"
require_relative "trexbar/core/format"
require_relative "trexbar/core/process"
require_relative "trexbar/core/trex_backend"
require_relative "trexbar/runtime/state"
require_relative "trexbar/runtime/presenter"
require_relative "trexbar/runtime/daemon"
require_relative "trexbar/runtime/quickshell"
require_relative "trexbar/runtime/waybar"
require_relative "trexbar/runtime/omarchy"
require_relative "trexbar/cli"

module Trexbar
  VERSION = "0.2.0"
end
