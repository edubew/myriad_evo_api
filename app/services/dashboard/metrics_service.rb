module Dashboard
  class MetricsService < ApplicationService
    def initialize(company:, user:)
      @company = company
      @user    = user
    end

    def call
      @projects = @company.projects
      @tasks    = @company.tasks
                    .joins(:project)
                    .where.not(projects: { status: %w[cancelled completed] })
      @deals    = @company.deals
      @clients  = @company.clients
      @events   = @company.events

      success({
        metrics:          metrics,
        alert:            alert_banner,
        todays_focus:     todays_focus,
        kanban_overview:  kanban_overview,
        upcoming_events:  upcoming_events,
        active_projects:  active_projects,
        pipeline_summary: pipeline_summary,
        revenue_chart:    revenue_chart
      })
    end

    private

    def metrics
      today = Date.today
      {
        active_projects:        @projects.active.count,
        overdue_projects:       overdue_projects_scope.count,
        upcoming_deadlines:     @projects.active
                                  .where(end_date: today..(today + 14.days)).count,
        active_clients:         @clients.active.count,
        new_clients_this_month: @clients.where(created_at: today.beginning_of_month..).count,
        projects_due_this_week: @projects.active
                                  .where(end_date: today..(today + 7.days)).count
      }
    end

    def alert_banner
      overdue_project_count = overdue_projects_scope.count
      overdue_task_count    = overdue_tasks_scope.count
      return nil if overdue_project_count.zero? && overdue_task_count.zero?

      parts = []
      parts << "#{overdue_project_count} project#{'s' if overdue_project_count != 1} overdue" if overdue_project_count > 0
      parts << "#{overdue_task_count} task#{'s' if overdue_task_count != 1} overdue"          if overdue_task_count > 0

      {
        message: parts.join(' and '),
        overdue_projects: overdue_projects_scope.limit(3).map { |p|
          { id: p.id, title: p.title, end_date: p.end_date }
        },
        overdue_tasks: overdue_tasks_scope.limit(3).map { |t|
          { id: t.id, title: t.title, due_date: t.due_date, project_id: t.project_id }
        }
      }
    end

    def todays_focus
      today = Date.today
      items = []

      overdue_tasks_scope.includes(:project).limit(3).each do |task|
        items << focus_item_from_task(task, meta: "#{task.project&.title} · overdue", overdue: true)
      end

      @tasks
        .where(due_date: today, status: %w[backlog in_progress review])
        .includes(:project)
        .limit(4)
        .each do |task|
          items << focus_item_from_task(task, meta: "#{task.project&.title} · due today", overdue: false)
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
      statuses    = %w[backlog in_progress review completed]
      all_tasks   = @tasks.includes(:project).to_a
      grouped     = all_tasks.group_by(&:status)
      counts      = all_tasks.group_by(&:status).transform_values(&:count)

      tasks = statuses.each_with_object({}) do |status, h|
        h[status] = (grouped[status] || [])
          .sort_by { |t| t.due_date || Date::Infinity.new }
          .first(4)
          .map { |t| kanban_task_payload(t, status) }
      end

      { tasks: tasks, counts: counts }
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
          tasks        = p.tasks.to_a
          total        = tasks.size
          completed    = tasks.count { |t| t.status == 'completed' }
          pct          = total.zero? ? 0 : ((completed.to_f / total) * 100).round
          {
            id:                    p.id,
            title:                 p.title,
            color:                 p.color,
            end_date:              p.end_date,
            completion_percentage: pct,
            overdue:               p.end_date.present? && p.end_date < Date.today
          }
        }
    end

    def pipeline_summary
      max_value = [@deals.active.sum(:value).to_f, 1].max

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

        won      = @company.deals
                     .where(status: 'closed_won')
                     .where(updated_at: month..month_end)
                     .sum(:value).to_f

        pipeline = @company.deals
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

    def focus_item_from_task(task, meta:, overdue:)
      {
        id:        "task_#{task.id}",
        text:      task.title,
        source:    'project',
        source_id: task.project_id,
        meta:      meta,
        done:      false,
        type:      'task',
        priority:  task.priority,
        overdue:   overdue
      }
    end

    def kanban_task_payload(task, status)
      overdue = task.due_date.present? &&
                task.due_date < Date.today &&
                status != 'completed'
      {
        id:             task.id,
        title:          task.title,
        priority:       task.priority,
        priority_color: task.priority_color,
        due_date:       task.due_date,
        project_id:     task.project_id,
        project_title:  task.project&.title,
        overdue:        overdue
      }
    end
  end
end
