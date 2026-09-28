# frozen_string_literal: true

require "fileutils"
require "json"
require "minitest/autorun"
require "tmpdir"

$LOAD_PATH.unshift(File.expand_path("../lib", __dir__))
require "trexbar_sway"

module TrexbarSwayTestHelpers
  def with_temp_home
    Dir.mktmpdir do |dir|
      old_home = ENV["HOME"]
      ENV["HOME"] = dir
      yield dir
    ensure
      ENV["HOME"] = old_home
    end
  end

  def write_fake_trex(dir, payload:, exit_status: 0, stderr: "")
    path = File.join(dir, "fake-trex")
    File.write(path, <<~RUBY)
      #!/usr/bin/env ruby
      if ARGV == ["snapshot", "--json"]
        warn #{stderr.inspect} unless #{stderr.inspect}.empty?
        puts #{JSON.generate(payload).inspect}
        exit #{exit_status}
      end
      warn "unexpected args: \#{ARGV.inspect}"
      exit 2
    RUBY
    File.chmod(0o755, path)
    path
  end

  def backend_payload(overrides = {})
    {
      snapshotVersion: 1,
      generatedAt: 123,
      status: "healthy",
      summary: {
        sessionCount: 2,
        attachedCount: 1,
        agentCount: 3,
        activeCount: 1,
        idleCount: 0,
        dormantCount: 1,
        unknownActivityCount: 0,
        dirtyRepoCount: 1,
        highCpuCount: 1,
        highMemoryCount: 0,
        worstHealth: "warning"
      },
      sessions: [
        {
          name: "dev",
          attached: true,
          windows: 2,
          path: "/srv/dev",
          health: { score: 80, level: "healthy" },
          stats: { cpuPercent: 20.0, memMb: 256, memPercent: 1.0 },
          git: { isRepo: true, branch: "main", dirtyCount: 1, ahead: 0, behind: 0, badge: "main +1" },
          agents: []
        },
        {
          name: "build",
          attached: false,
          windows: 1,
          path: "/srv/build",
          health: { score: 60, level: "warning" },
          stats: { cpuPercent: 120.0, memMb: 512, memPercent: 2.0 },
          git: { isRepo: false },
          agents: []
        }
      ],
      agents: [
        { processName: "codex", projectName: "trex", tmuxSession: "dev", activityState: "running", pid: 42, childAiNames: [] },
        { processName: "gemini", projectName: "trex", tmuxSession: "dev", activityState: "waiting", pid: 43, childAiNames: ["agent-1", "agent-2"] },
        { processName: "hermes", projectName: "trex", tmuxSession: "dev", activityState: "waiting", pid: 44, childAiNames: [] }
      ],
      errors: []
    }.merge(overrides)
  end
end
