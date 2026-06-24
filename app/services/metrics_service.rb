module Dashboard
  class MetricsService < ApplicationService
    def initialize(company:, user:)
      @company = company
      @user    = user
    end

    def call
      success({
        metrics:          company_metrics,
        pipeline_summary: pipeline_summary,
        revenue_chart:    revenue_chart,   # company-wide won deals
        active_projects:  active_projects,
        upcoming_events:  upcoming_events,
        kanban_overview:  kanban_overview
      })
    end

    private

    def company_metrics
      today = Date.today
      {
        active_projects:       @company.projects.active.count,
        overdue_projects:      @company.projects.active.where('end_date < ?', today).count,
        active_clients:        @company.clients.active.count,
        new_clients_this_month:@company.clients.where(created_at: today.beginning_of_month..).count,
        upcoming_deadlines:    @company.projects.active.where(end_date: today..(today + 14.days)).count
      }
    end

    def pipeline_summary
      Deal::STAGE_LABELS.map do |status, label|
        stage_deals = @company.deals.where(status: status)
        {
          status:     status,
          label:      label,
          color:      Deal::STAGE_COLORS[status],
          count:      stage_deals.count,
          value:      stage_deals.sum(:value).to_f,
        }
      end
    end

    def revenue_chart
      6.downto(0).map do |i|
        month     = i.months.ago.beginning_of_month
        month_end = i.months.ago.end_of_month
        won      = @company.deals.where(status: 'closed_won')
                     .where(updated_at: month..month_end).sum(:value).to_f
        pipeline = @company.deals.active
                     .where(created_at: ..month_end).sum(:value).to_f
        { month: month.strftime('%b'), year: month.year, won: won, pipeline: pipeline }
      end.reverse
    end

    def active_projects
      @company.projects.active.includes(:tasks).order(end_date: :asc).limit(5).map do |p|
        {
          id:                    p.id,
          title:                 p.title,
          color:                 p.color,
          end_date:              p.end_date,
          completion_percentage: p.completion_percentage,
          overdue:               p.end_date.present? && p.end_date < Date.today
        }
      end
    end

    def upcoming_events
      @company.events
        .where('start_time >= ?', Time.current)
        .where('start_time <= ?', 7.days.from_now)
        .order(start_time: :asc).limit(5)
        .map { |e| { id: e.id, title: e.title, start: e.start_time, event_type: e.event_type } }
    end

    def kanban_overview
      all_tasks = @company.tasks
        .joins(:project)
        .where.not(projects: { status: %w[cancelled completed] })
        .includes(:project)

      grouped = all_tasks.group_by(&:status)
      counts  = all_tasks.group(:status).count

      tasks = %w[backlog in_progress review completed].each_with_object({}) do |status, h|
        h[status] = (grouped[status] || []).sort_by(&:due_date).first(4).map do |t|
          {
            id:         t.id,
            title:      t.title,
            priority:   t.priority,
            due_date:   t.due_date,
            project_id: t.project_id,
            overdue:    t.due_date.present? && t.due_date < Date.today && status != 'completed'
          }
        end
      end

      { tasks: tasks, counts: counts }
    end
  end
end