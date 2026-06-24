module Api
  module V1
    class ClientsController < BaseController
      before_action :set_client, only: [:show, :update, :destroy]

      def index
        # policy_scope automatically restricts to current_company
        clients = policy_scope(Client)
          .includes(:contacts)
          .then { |s| params[:q].present?      ? s.search(params[:q])           : s }
          .then { |s| params[:status].present? ? s.where(status: params[:status]) : s }
          .order(created_at: :desc)
          .page(params[:page]).per(params[:per_page] || 25)

        render_success(
          data: clients.map { |c| ClientBlueprint.render_as_hash(c) },
          meta: pagination_meta(clients)
        )
      end

      def show
        authorize @client
        render_success(data: ClientBlueprint.render_as_hash(@client, view: :detail))
      end

      def create
        client = current_company.clients.build(client_params.merge(user: current_user))
        authorize client

        if client.save
          render_success(data: ClientBlueprint.render_as_hash(client), status: :created)
        else
          render_error(message: 'Validation failed', errors: client.errors.full_messages)
        end
      end

      def update
        authorize @client
        if @client.update(client_params)
          render_success(data: ClientBlueprint.render_as_hash(@client))
        else
          render_error(message: 'Validation failed', errors: @client.errors.full_messages)
        end
      end

      def destroy
        authorize @client
        @client.destroy
        render_success(data: { id: @client.id })
      end

      private

      def set_client
        # Never use Client.find — always scope to company first
        @client = policy_scope(Client).find(params[:id])
      end

      def client_params
        params.require(:client).permit(
          :company_name, :industry, :website,
          :email, :phone, :status, :notes
        )
      end
    end
  end
end