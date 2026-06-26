module Api
  module V1
    class DealsController < BaseController
      before_action :set_deal, only: [:show, :update, :destroy]

      def index
        @deals = policy_scope(Deal)
        @deals = @deals.where(status: params[:status]) if params[:status].present?
        @deals = @deals.order(:position)

        render json: {
          success: true,
          data:    @deals.map { |d| deal_payload(d) },
          summary: pipeline_summary
        }
      end

      def show
        authorize @deal
        render json: { success: true, data: deal_payload(@deal) }
      end

      def create
        @deal = current_company.deals.build(deal_params.merge(user: current_user))

        @deal.position = current_company.deals
                           .where(status: @deal.status).count

        if @deal.client_id.present?
          unless current_company.clients.exists?(id: @deal.client_id)
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        authorize @deal

        if @deal.save
          render json: {
            success: true,
            data:    deal_payload(@deal)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @deal.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @deal

        if deal_params[:client_id].present?
          unless current_company.clients.exists?(id: deal_params[:client_id])
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        if @deal.update(deal_params)
          render json: { success: true, data: deal_payload(@deal) }
        else
          render json: {
            success: false,
            errors:  @deal.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @deal
        @deal.destroy
        render json: { success: true, message: 'Deal deleted' }
      end

      def reorder
        authorize Deal, :reorder?

        deals_data = params[:deals]

        unless deals_data.is_a?(Array)
          return render json: {
            success: false,
            error:   'Expected an array of deals'
          }, status: :unprocessable_content
        end

        ActiveRecord::Base.transaction do
          deals_data.each_with_index do |deal_data, index|
            current_company.deals
              .find(deal_data[:id])
              .update!(
                status:   deal_data[:status],
                position: index
              )
          end
        end

        render json: { success: true }

      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error:   'One or more deals not found or do not belong to your organization'
        }, status: :not_found
      rescue ActiveRecord::RecordInvalid => e
        render json: {
          success: false,
          errors:  e.record.errors.full_messages
        }, status: :unprocessable_content
      end

      private

      def set_deal
        @deal = policy_scope(Deal).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Deal not found' }, status: :not_found
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
        deals = current_company.deals
        {
          total_value:    deals.active.sum(:value).to_f,
          weighted_value: deals.active.sum('value * probability / 100').to_f,
          deal_count:     deals.active.count,
          won_value:      deals.where(status: 'closed_won').sum(:value).to_f
        }
      end
    end
  end
end