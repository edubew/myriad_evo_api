module Api
  module V1
    class RevenueEntriesController < BaseController
      before_action :set_entry, only: [:update, :destroy]

      def index
        @entries = policy_scope(RevenueEntry).order(date: :desc)

        if params[:month].present? && params[:year].present?
          date     = Date.new(params[:year].to_i, params[:month].to_i, 1)
          @entries = @entries.for_month(date)
        elsif params[:year].present?
          @entries = @entries.for_year(params[:year].to_i)
        end

        render json: {
          success: true,
          data:    @entries.map { |e| entry_payload(e) },
          summary: summary(params[:month], params[:year])
        }
      end

      def create
        defaults = current_company.allocation_setting
        @entry   = current_company.revenue_entries.build(
          entry_params.merge(user: current_user)
        )

        unless params.dig(:revenue_entry, :salary_pct).present?
          @entry.salary_pct = defaults&.salary_pct || 40.0
          @entry.ops_pct    = defaults&.ops_pct    || 25.0
          @entry.profit_pct = defaults&.profit_pct || 35.0
        end

        authorize @entry

        if @entry.save
          render json: {
            success: true,
            data:    entry_payload(@entry)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @entry.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @entry

        if @entry.update(entry_params)
          render json: { success: true, data: entry_payload(@entry) }
        else
          render json: {
            success: false,
            errors:  @entry.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @entry
        @entry.destroy
        render json: { success: true, message: 'Entry deleted' }
      end

      private

      def set_entry
        @entry = policy_scope(RevenueEntry).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Not found' }, status: :not_found
      end

      def entry_params
        params.require(:revenue_entry).permit(
          :title, :amount, :source, :status,
          :date, :notes, :salary_pct, :ops_pct,
          :profit_pct, :deal_id
        )
      end

      def entry_payload(entry)
        {
          id:             entry.id,
          title:          entry.title,
          amount:         entry.amount.to_f,
          source:         entry.source,
          source_id:      entry.source_id,
          status:         entry.status,
          date:           entry.date,
          notes:          entry.notes,
          salary_pct:     entry.salary_pct.to_f,
          ops_pct:        entry.ops_pct.to_f,
          profit_pct:     entry.profit_pct.to_f,
          salary_amount:  entry.salary_amount.to_f,
          ops_amount:     entry.ops_amount.to_f,
          profit_amount:  entry.profit_amount.to_f,
          created_at:     entry.created_at
        }
      end

      def summary(month, year)
        # policy_scope respects admin vs member visibility
        entries = policy_scope(RevenueEntry).paid

        if month.present? && year.present?
          date    = Date.new(year.to_i, month.to_i, 1)
          entries = entries.for_month(date)
        elsif year.present?
          entries = entries.for_year(year.to_i)
        end

        total_amount = entries.sum(:amount).to_f

        pending_count = policy_scope(RevenueEntry).where(status: 'pending').count
        pending_count = if year.present?
          policy_scope(RevenueEntry)
            .where(status: 'pending')
            .for_year(year.to_i)
            .count
        else
          policy_scope(RevenueEntry).where(status: 'pending').count
        end

        {
          total_received: total_amount,
          total_salary:   entries.sum(:salary_amount).to_f,
          total_ops:      entries.sum(:ops_amount).to_f,
          total_profit:   entries.sum(:profit_amount).to_f,
          paid_count:     entries.count,
          pending_count:  pending_count,
          monthly_trend:  monthly_trend
        }
      end

      def monthly_trend
        # Scope to same visibility as the rest of this controller
        base_scope = policy_scope(RevenueEntry).paid

        # One query: sum per month over the last 7 months
        start_date = 6.months.ago.beginning_of_month
        rows = base_scope
                 .where('date >= ?', start_date)
                 .group("DATE_TRUNC('month', date)")
                 .order("DATE_TRUNC('month', date)")
                 .sum(:amount)

        6.downto(0).map { |i|
          month     = i.months.ago.beginning_of_month.to_date
          month_key = rows.keys.find { |k| k.to_date == month }
          total     = month_key ? rows[month_key].to_f : 0.0
          {
            month:   month.strftime('%b'),
            year:    month.year,
            total:   total,
            current: i.zero?
          }
        }.reverse
      end
    end
  end
end