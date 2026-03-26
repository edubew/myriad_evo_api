module Api
  module V1
    class DealsController < BaseController
      before_action :set_deal, only: [:show, :update, :destroy]

      def index
        @deals = current_user.deals
        @deals = @deals.where(status: params[:status]) if params[:status].present?
        @deals = @deals.order(:position)

        render json: {
          success: true,
          data: @deals.map { |d| deal_payload(d) },
          summary: pipeline_summary
        }
      end

      def show
        render json: { success: true, data: deal_payload(@deal) }
      end

      def create
        @deal = current_user.deals.build(deal_params)
        @deal.position = current_user.deals
          .where(status: @deal.status).count

        if @deal.save
          render json: {
            success: true,
            data: deal_payload(@deal)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @deal.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        if @deal.update(deal_params)
          render json: { success: true, data: deal_payload(@deal) }
        else
          render json: {
            success: false,
            errors: @deal.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @deal.destroy
        render json: { success: true, message: 'Deal deleted' }
      end

      def reorder
        deals_data = params[:deals]
        deals_data.each_with_index do |deal_data, index|
          current_user.deals
            .find(deal_data[:id])
            .update(status: deal_data[:status], position: index)
        end
        render json: { success: true }
      end

      private

      def set_deal
        @deal = current_user.deals.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Deal not found'
        }, status: :not_found
      end

      def deal_params
        params.require(:deal).permit(
          :title, :value, :probability,
          :expected_close, :status, :notes, :client_id
        )
      end

      def deal_payload(deal)
        {
          id:             deal.id,
          title:          deal.title,
          value:          deal.value,
          probability:    deal.probability,
          weighted_value: deal.weighted_value,
          expected_close: deal.expected_close,
          status:         deal.status,
          stage_label:    deal.stage_label,
          stage_color:    deal.stage_color,
          notes:          deal.notes,
          position:       deal.position,
          client_id:      deal.client_id,
          created_at:     deal.created_at
        }
      end

      def pipeline_summary
        deals = current_user.deals
        {
          total_value:    deals.active.sum(:value),
          weighted_value: deals.active.sum('value * probability / 100'),
          deal_count:     deals.active.count,
          won_value:      deals.where(status: 'closed_won').sum(:value)
        }
      end
    end
  end
end