module Api
  module V1
    class DashboardController < BaseController
      def index
        skip_authorization

        @projects = current_company.projects
        @tasks    = current_company.tasks
                      .joins(:project)
                      .where.not(projects: { status: %w[cancelled completed] })
        @deals    = current_company.deals
        @clients  = current_company.clients
        @events   = current_company.events

        data = Rails.cache.fetch(cache_key, expires_in: 5.minutes) do
          {
            metrics:          metrics,
            alert:            alert_banner,
            todays_focus:     todays_focus,
            kanban_overview:  kanban_overview,
            upcoming_events:  upcoming_events,
            active_projects:  active_projects,
            pipeline_summary: pipeline_summary,
            revenue_chart:    revenue_chart
          }
        end

        render json: { success: true, data: data }
      end

      private

      def cache_key
        timestamps = [
          @projects.maximum(:updated_at),
          @tasks.maximum(:updated_at),
          @deals.maximum(:updated_at),
          @clients.maximum(:updated_at),
          @events.maximum(:updated_at)
        ].compact.max&.to_i || 0

        "dashboard/company/#{current_company.id}/#{timestamps}"
      end

      def metrics
        today = Date.today

        {
          overdue_projects:       overdue_projects_scope.count,
          active_projects:        @projects.active.count,
          upcoming_deadlines:     @projects.where(
                                    end_date: today..(today + 14.days),
                                    status:   'active'
                                  ).count,
          active_clients:         @clients.active.count,
          new_clients_this_month: @clients.where(
                                    created_at: today.beginning_of_month..
                                  ).count,
          projects_due_this_week: @projects.active
                                    .where(end_date: today..(today + 7.days))
                                    .count
        }
      end

      def alert_banner
        overdue_count = overdue_projects_scope.count
        overdue_task_count = overdue_tasks_scope.count
        return nil if overdue_count.zero? && overdue_task_count.zero?

        parts = []
        parts << "#{overdue_count} project#{'s' if overdue_count != 1} overdue" if overdue_count > 0
        parts << "#{overdue_task_count} task#{'s' if overdue_task_count != 1} overdue" if overdue_task_count > 0

        {
          message:          parts.join(' and '),
          overdue_projects: overdue_projects_scope.limit(3).map { |p|
            { id: p.id, title: p.title, end_date: p.end_date }
          },
          overdue_tasks:    overdue_tasks_scope.limit(3).map { |t|
            { id: t.id, title: t.title, due_date: t.due_date,
              project_id: t.project_id }
          }
        }
      end

      def todays_focus
        today = Date.today
        items = []

        overdue_tasks_scope.includes(:project).limit(3).each do |task|
          items << {
            id:         "task_#{task.id}",
            text:       task.title,
            source:     'project',
            source_id:  task.project_id,
            meta:       "#{task.project&.title} · overdue",
            done:       false,
            type:       'task',
            priority:   task.priority,
            overdue:    true
          }
        end

        @tasks
          .where(due_date: today, status: %w[backlog in_progress review])
          .includes(:project)
          .limit(4)
          .each do |task|
            items << {
              id:        "task_#{task.id}",
              text:      task.title,
              source:    'project',
              source_id: task.project_id,
              meta:      "#{task.project&.title} · due today",
              done:      false,
              type:      'task',
              priority:  task.priority,
              overdue:   false
            }
          end

        @events
          .where('DATE(start_time) = ?', today)
          .where(source: 'manual')
          .limit(2)
          .each do |e|
            items << {
              id:        "event_#{e.id}",
              text:      e.title,
              source:    'calendar',
              source_id: e.id,
              meta:      "Calendar · #{e.start_time.strftime('%I:%M %p')}",
              done:      false,
              type:      'event',
              priority:  nil,
              overdue:   false
            }
          end

        items.uniq { |i| i[:id] }.first(8)
      end

      def kanban_overview
        statuses = %w[backlog in_progress review completed]
        result   = {}

        statuses.each do |status|
          result[status] = @tasks
            .where(status: status)
            .includes(:project)
            .order(due_date: :asc)
            .limit(4)
            .map { |t|
              overdue = t.due_date.present? && t.due_date < Date.today &&
                        status != 'completed'
              {
                id:             t.id,
                title:          t.title,
                priority:       t.priority,
                priority_color: t.priority_color,
                due_date:       t.due_date,
                project_id:     t.project_id,
                project_title:  t.project&.title,
                overdue:        overdue
              }
            }
        end

        counts = @tasks.group(:status).count

        { tasks: result, counts: counts }
      end

      def upcoming_events
        @events
          .where('start_time >= ?', Time.current)
          .where('start_time <= ?', 7.days.from_now)
          .order(start_time: :asc)
          .limit(5)
          .map { |e|
            {
              id:         e.id,
              title:      e.title,
              start:      e.start_time,
              all_day:    e.all_day,
              event_type: e.event_type,
              color:      e.color,
              source:     e.source,
              source_id:  e.source_id
            }
          }
      end

      def active_projects
        @projects
          .active
          .includes(:tasks)
          .order(end_date: :asc)
          .limit(5)
          .map { |p|
            overdue = p.end_date.present? && p.end_date < Date.today
            {
              id:                    p.id,
              title:                 p.title,
              color:                 p.color,
              end_date:              p.end_date,
              completion_percentage: p.completion_percentage,
              overdue:               overdue
            }
          }
      end

      def pipeline_summary
        max_value = @deals.active.sum(:value).to_f
        max_value = 1 if max_value.zero?   # avoid division by zero

        Deal::STAGE_LABELS.map { |status, label|
          stage_deals = @deals.where(status: status)
          value       = stage_deals.sum(:value).to_f
          {
            status:     status,
            label:      label,
            color:      Deal::STAGE_COLORS[status],
            count:      stage_deals.count,
            value:      value,
            percentage: ((value / max_value) * 100).round
          }
        }
      end

      def revenue_chart
        6.downto(0).map { |i|
          month     = i.months.ago.beginning_of_month
          month_end = i.months.ago.end_of_month

          won = current_company.deals
                  .where(status: 'closed_won')
                  .where(updated_at: month..month_end)
                  .sum(:value).to_f

          pipeline = current_company.deals
                       .active
                       .where(created_at: ..month_end)
                       .sum(:value).to_f

          {
            month:    month.strftime('%b'),
            year:     month.year,
            won:      won,
            pipeline: pipeline,
            current:  i.zero?
          }
        }.reverse
      end

      def overdue_projects_scope
        @projects.active.where('end_date < ?', Date.today)
      end

      def overdue_tasks_scope
        @tasks
          .where('tasks.due_date < ?', Date.today)
          .where.not(tasks: { status: 'completed' })
      end
    end
  end
end