module Api
  module V1
    class DashboardController < BaseController

      def index
        render json: {
          success: true,
          data: {
            metrics: metrics,
            alert: alert_banner,
            todays_focus: todays_focus,
            kanban_overview: kanban_overview,
            upcoming_events: upcoming_events,
            active_projects: active_projects,
            pipeline_summary: pipeline_summary,
            revenue_chart: revenue_chart
          }
        }
      end

      private

      # Metrics
      def metrics
        today = Date.today
        {
          overdue_projects: overdue_projects_scope.count,
          active_projects: current_user.projects.active.count,
          upcoming_deadlines: current_user.projects
            .where(end_date: today..(today + 14.days))
            .where(status: 'active')
            .count,
          active_clients:        current_user.clients.active.count,
          new_clients_this_month: current_user.clients
            .where(created_at: Date.today.beginning_of_month..)
            .count,
          projects_due_this_week: current_user.projects.active
            .where(end_date: today..(today + 7.days))
            .count
        }
      end

      # Alert banner
      def alert_banner
        overdue_count = overdue_projects_scope.count
        overdue_tasks = overdue_tasks_scope.count
        return nil if overdue_count.zero? && overdue_tasks.zero?

        parts = []
        parts << "#{overdue_count} project#{'s' if overdue_count != 1} overdue" if overdue_count > 0
        parts << "#{overdue_tasks} task#{'s' if overdue_tasks != 1} overdue" if overdue_tasks > 0

        {
          message: parts.join(' and '),
          overdue_projects: overdue_projects_scope.limit(3).map { |p|
            { id: p.id, title: p.title, end_date: p.end_date }
          },
          overdue_tasks: overdue_tasks_scope.limit(3).map { |t|
            { id: t.id, title: t.title, due_date: t.due_date,
              project_id: t.project_id }
          }
        }
      end

      def todays_focus
        today  = Date.today
        items  = []

        # Tasks due today from all projects
        overdue_tasks_scope.limit(3).each do |task|
          items << {
            id: "task_#{task.id}",
            text: task.title,
            source:  'project',
            source_id:  task.project_id,
            meta: "#{task.project&.title} · overdue",
            done: false,
            type: 'task',
            priority: task.priority,
            overdue: true
          }
        end

        current_user.projects
          .joins(:tasks)
          .where(tasks: { due_date: today, status: %w[backlog in_progress review] })
          .select('tasks.id, tasks.title, tasks.priority, tasks.project_id, projects.title as project_title')
          .limit(4)
          .each do |t|
            items << {
              id: "task_#{t.id}",
              text: t.title,
              source: 'project',
              source_id: t.project_id,
              meta: "#{t.project_title} · due today",
              done: false,
              type: 'task',
              priority: t.priority,
              overdue: false
            }
          end

        # Upcoming events today
        current_user.events
          .where('DATE(start_time) = ?', today)
          .where(source: 'manual')
          .limit(2)
          .each do |e|
            items << {
              id:  "event_#{e.id}",
              text: e.title,
              source: 'calendar',
              source_id: e.id,
              meta: "Calendar · #{e.start_time.strftime('%I:%M %p')}",
              done: false,
              type: 'event',
              priority: nil,
              overdue: false
            }
          end

        items.uniq { |i| i[:id] }.first(8)
      end

      def kanban_overview
        statuses = %w[backlog in_progress review completed]
        result   = {}

        statuses.each do |status|
          tasks = Task.joins(:project)
            .where(projects: { user_id: current_user.id })
            .where(status: status)
            .where.not(projects: { status: 'cancelled' })
            .includes(:project)
            .order(due_date: :asc)
            .limit(4)

          result[status] = tasks.map { |t|
            overdue = t.due_date.present? && t.due_date < Date.today &&
                      status != 'completed'
            {
              id: t.id,
              title: t.title,
              priority: t.priority,
              priority_color: t.priority_color,
              due_date: t.due_date,
              project_id: t.project_id,
              project_title: t.project&.title,
              overdue: overdue
            }
          }
        end

        counts = Task.joins(:project)
          .where(projects: { user_id: current_user.id })
          .where.not(projects: { status: 'cancelled' })
          .group(:status)
          .count

        { tasks: result, counts: counts }
      end

      def upcoming_events
        current_user.events
          .where('start_time >= ?', Time.current)
          .where('start_time <= ?', 7.days.from_now)
          .order(start_time: :asc)
          .limit(5)
          .map { |e|
            {
              id: e.id,
              title: e.title,
              start: e.start_time,
              all_day: e.all_day,
              event_type: e.event_type,
              color: e.color,
              source: e.source,
              source_id: e.source_id
            }
          }
      end

      def active_projects
        current_user.projects
          .active
          .order(end_date: :asc)
          .limit(5)
          .map { |p|
            overdue = p.end_date.present? && p.end_date < Date.today
            {
              id: p.id,
              title: p.title,
              color: p.color,
              end_date: p.end_date,
              completion_percentage: p.completion_percentage,
              overdue: overdue
            }
          }
      end

      def pipeline_summary
        max_value = current_user.deals.active.sum(:value).to_f
        max_value = 1 if max_value.zero?

        Deal::STAGE_LABELS.map { |status, label|
          stage_deals = current_user.deals.where(status: status)
          value       = stage_deals.sum(:value).to_f
          {
            status: status,
            label: label,
            color: Deal::STAGE_COLORS[status],
            count: stage_deals.count,
            value: value,
            percentage: ((value / max_value) * 100).round
          }
        }
      end

      def revenue_chart
        6.downto(0).map { |i|
          month       = i.months.ago.beginning_of_month
          month_end   = i.months.ago.end_of_month
          won         = current_user.deals
            .where(status: 'closed_won')
            .where(updated_at: month..month_end)
            .sum(:value).to_f
          pipeline    = current_user.deals
            .active
            .where(created_at: ..month_end)
            .sum(:value).to_f
          {
            month: month.strftime('%b'),
            year: month.year,
            won: won,
            pipeline: pipeline,
            current: i.zero?
          }
        }.reverse
      end

      def overdue_projects_scope
        current_user.projects
          .active
          .where('end_date < ?', Date.today)
      end

      def overdue_tasks_scope
        Task.joins(:project)
          .where(projects: { user_id: current_user.id })
          .where('tasks.due_date < ?', Date.today)
          .where.not(tasks: { status: 'completed' })
          .where.not(projects: { status: %w[cancelled completed] })
      end

    end
  end
end