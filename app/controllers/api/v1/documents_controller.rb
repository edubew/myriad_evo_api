module Api
  module V1
    class DocumentsController < BaseController
      include Rails.application.routes.url_helpers
      before_action :set_document, only: [:show, :update, :destroy]

      def index
        @documents = current_company.documents
        @documents = @documents.search(params[:q])             if params[:q].present?
        @documents = @documents.by_category(params[:category]) if params[:category].present?
        @documents = @documents.where(project_id: params[:project_id]) if params[:project_id].present?
        @documents = @documents.order(created_at: :desc)

        render json: {
          success: true,
          data: @documents.map { |d| document_payload(d) }
        }
      end

      def show
        render json: { success: true, data: document_payload(@document) }
      end

      def create
        @document = current_company.documents.build(document_params.merge(user: current_user))
        if @document.save
          render json: {
            success: true,
            data: document_payload(@document)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @document.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        if @document.update(document_params)
          render json: {
            success: true,
            data: document_payload(@document)
          }
        else
          render json: {
            success: false,
            errors: @document.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @document.destroy
        render json: { success: true, message: 'Document deleted' }
      end

      private

      def set_document
        @document = current_company.documents.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Document not found'
        }, status: :not_found
      end

      def document_params
        params.require(:document).permit(
          :title, :description,:category, :project_id, :file
        )
      end

      def document_payload(document)
        {
          id: document.id,
          title: document.title,
          description: document.description,
          category: document.category,
          project_id: document.project_id,
          file_url: document.file.attached? ? url_for(document.file) : nil,
          file_name: document.file.filename.to_s,
          file_type: document.file.content_type,
          created_at: document.created_at
        }
      end
    end
  end
end