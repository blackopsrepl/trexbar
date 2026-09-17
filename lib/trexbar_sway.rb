# frozen_string_literal: true

require_relative "trexbar_sway/core/config"
require_relative "trexbar_sway/core/format"
require_relative "trexbar_sway/core/process"
require_relative "trexbar_sway/core/trex_backend"
require_relative "trexbar_sway/runtime/state"
require_relative "trexbar_sway/runtime/presenter"
require_relative "trexbar_sway/runtime/daemon"
require_relative "trexbar_sway/runtime/quickshell"
require_relative "trexbar_sway/runtime/waybar"
require_relative "trexbar_sway/cli"

module TrexbarSway
  VERSION = "0.1.3"
end
