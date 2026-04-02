module Api
  module V1
    class LeadsController < BaseController
      before_action :set_lead, only: [:show, :update, :destroy]

      def index
        @leads = current_company.leads
        @leads = @leads.search(params[:q])          if params[:q].present?
        @leads = @leads.where(status: params[:status]) if params[:status].present?
        @leads = @leads.order(created_at: :desc)

        render json: {
          success: true,
          data: @leads.map { |l| lead_payload(l) }
        }
      end

      def create
        @lead = current_company.leads.build(lead_params.merge(user: current_user))
        if @lead.save
          render json: {
            success: true,
            data: lead_payload(@lead)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @lead.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def show
        render json: { success: true, data: lead_payload(@lead) }
      end

      def update
        if @lead.update(lead_params)
          render json: { success: true, data: lead_payload(@lead) }
        else
          render json: {
            success: false,
            errors: @lead.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @lead.destroy
        render json: { success: true, message: 'Lead deleted' }
      end

      private

      def set_lead
        @lead = current_company.leads.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Lead not found'
        }, status: :not_found
      end

      def lead_params
        params.require(:lead).permit(
          :company_name, :contact_name, :email,
          :phone, :source, :status, :notes
        )
      end

      def lead_payload(lead)
        {
          id:           lead.id,
          company_name: lead.company_name,
          contact_name: lead.contact_name,
          email:        lead.email,
          phone:        lead.phone,
          source:       lead.source,
          status:       lead.status,
          notes:        lead.notes,
          created_at:   lead.created_at
        }
      end
    end
  end
end