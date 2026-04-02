module Api
  module V1
    class ContactsController < BaseController
      before_action :set_client

      def create
        @contact = @client.contacts.build(contact_params.merge(company: current_company))
        if @contact.save
          render json: {
            success: true,
            data: contact_payload(@contact)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @contact.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        @contact = @client.contacts.find(params[:id])
        if @contact.update(contact_params)
          render json: {
            success: true,
            data: contact_payload(@contact)
          }
        else
          render json: {
            success: false,
            errors: @contact.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @contact = @client.contacts.find(params[:id])
        @contact.destroy
        render json: { success: true, message: 'Contact deleted' }
      end

      private

      def set_client
        @client = current_company.clients.find(params[:client_id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Client not found'
        }, status: :not_found
      end

      def contact_params
        params.require(:contact).permit(
          :first_name,
          :last_name,
          :email,
          :phone,
          :role,
          :is_primary
        )
      end

      def contact_payload(contact)
        {
          id:         contact.id,
          full_name:  contact.full_name,
          first_name: contact.first_name,
          last_name:  contact.last_name,
          email:      contact.email,
          phone:      contact.phone,
          role:       contact.role,
          is_primary: contact.is_primary
        }
      end
    end
  end
end