module Api
  module V1
    class ClientsController < BaseController
      before_action :set_client, only: [:show, :update, :destroy]

      def index
        @clients = current_company.clients

        @clients = @clients.search(params[:q])    if params[:q].present?
        @clients = @clients.where(status: params[:status]) if params[:status].present?
        @clients = @clients.order(created_at: :desc)

        render json: {
          success: true,
          data: @clients.map { |c| client_payload(c) }
        }
      end

      def show
        render json: {
          success: true,
          data: client_detail_payload(@client)
        }
      end

      def create
        @client = current_company.clients.build(client_params.merge(user: current_user))
        if @client.save
          render json: {
            success: true,
            data: client_payload(@client)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @client.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        if @client.update(client_params)
          render json: {
            success: true,
            data: client_payload(@client)
          }
        else
          render json: {
            success: false,
            errors: @client.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @client.destroy
        render json: { success: true, message: 'Client deleted' }
      end

      private

      def set_client
        @client = current_company.clients.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Client not found'
        }, status: :not_found
      end

      def client_params
        params.require(:client).permit(
          :company_name,
          :industry,
          :website,
          :email,
          :phone,
          :status,
          :notes
        )
      end

      def client_payload(client)
        {
          id:              client.id,
          company_name:    client.company_name,
          industry:        client.industry,
          website:         client.website,
          email:           client.email,
          phone:           client.phone,
          status:          client.status,
          initials:        client.initials,
          contact_count:   client.contacts.count,
          primary_contact: contact_payload(client.primary_contact),
          created_at:      client.created_at
        }
      end

      def client_detail_payload(client)
        client_payload(client).merge(
          notes:    client.notes,
          contacts: client.contacts.map { |c| contact_payload(c) }
        )
      end

      def contact_payload(contact)
        return nil unless contact
        {
          id:         contact.id,
          full_name:  contact.full_name,
          email:      contact.email,
          phone:      contact.phone,
          role:       contact.role,
          is_primary: contact.is_primary
        }
      end
    end
  end
end