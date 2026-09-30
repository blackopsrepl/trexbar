# frozen_string_literal: true

module Trexbar
  module Runtime
    module Presenter
      module_function

      def build_snapshot_view(snapshot, stale:, max_sessions: 8)
        summary = snapshot[:summary] || {}
        sessions = Array(snapshot[:sessions])
        status = stale ? "stale" : snapshot[:status].to_s
        headline = headline_session(sessions)
        classes = chip_classes(summary, status, headline)

        {
          chip: {
            text: Core::Format.chip_text(summary, status),
            tooltipLines: Core::Format.tooltip_lines(snapshot, stale: stale, max_sessions: max_sessions),
            classes: classes
          },
          summary: summary,
          headlineSession: headline,
          sessions: sessions,
          agents: Array(snapshot[:agents]),
          errors: Array(snapshot[:errors])
        }
      end

      def chip_classes(summary, status, headline)
        classes = ["trexbar", status]
        classes << health_class(summary[:worstHealth])
        classes << "no-sessions" if summary[:sessionCount].to_i.zero?
        classes << "has-agents" if summary[:agentCount].to_i.positive?
        classes << "has-attached" if summary[:attachedCount].to_i.positive?
        classes << "high-cpu" if summary[:highCpuCount].to_i.positive?
        classes << "high-memory" if summary[:highMemoryCount].to_i.positive?
        classes << "dirty-repos" if summary[:dirtyRepoCount].to_i.positive?
        classes << "headline-attached" if headline && headline[:attached]
        classes.compact.uniq
      end

      def headline_session(sessions)
        sessions.max_by do |session|
          [
            health_rank(session.dig(:health, :level)),
            session.dig(:stats, :cpuPercent).to_f,
            session.dig(:stats, :memMb).to_i,
            session[:attached] ? 1 : 0
          ]
        end
      end

      def health_class(level)
        case level.to_s
        when "critical" then "critical"
        when "warning" then "warning"
        when "healthy" then "healthy"
        else nil
        end
      end

      def health_rank(level)
        case level.to_s
        when "critical" then 3
        when "warning" then 2
        when "healthy" then 1
        else 0
        end
      end
    end
  end
end
