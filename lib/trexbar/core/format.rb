# frozen_string_literal: true

module Trexbar
  module Core
    module Format
      module_function

      def chip_text(summary, status)
        sessions = summary[:sessionCount].to_i
        agents = summary[:agentCount].to_i
        attached = summary[:attachedCount].to_i

        return "TRX err" if status == "error"
        return "TRX idle" if sessions.zero?

        pieces = ["TRX #{sessions}"]
        pieces << "#{attached}a" if attached.positive?
        pieces << "#{agents}ai" if agents.positive?
        pieces.join(" ")
      end

      def tooltip_lines(snapshot, stale: false, max_sessions: 8)
        summary = snapshot[:summary] || {}
        lines = []
        lines << "trexbar#{stale ? ' (stale)' : ''}"
        lines << "Sessions: #{summary[:sessionCount].to_i} | Attached: #{summary[:attachedCount].to_i} | Agents: #{summary[:agentCount].to_i}"
        lines << "Activity: #{summary[:activeCount].to_i} active, #{summary[:idleCount].to_i} idle, #{summary[:dormantCount].to_i} dormant"

        Array(snapshot[:sessions]).first(max_sessions.to_i).each do |session|
          detail = [session[:name], session.dig(:health, :level), stat_text(session), git_text(session)].compact.join(" | ")
          lines << detail
        end

        Array(snapshot[:errors]).first(4).each do |error|
          lines << "Error: #{error[:context] ? "#{error[:context]}: " : ''}#{error[:message]}"
        end

        lines
      end

      def stat_text(session)
        stats = session[:stats]
        return nil unless stats

        "CPU #{format('%.0f', stats[:cpuPercent].to_f)}% RAM #{stats[:memMb].to_i}MB"
      end

      def git_text(session)
        git = session[:git]
        return nil unless git && git[:isRepo]

        git[:badge] || git[:branch]
      end
    end
  end
end
