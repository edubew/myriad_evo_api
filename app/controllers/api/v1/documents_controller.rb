module Api
  module V1
    class DocumentsController < BaseController
      before_action :set_document, only: [:show, :update, :destroy]

      def index
        @documents = current_user.documents
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
        @document = current_user.documents.build(document_params)
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
        @document = current_user.documents.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: {
          success: false,
          error: 'Document not found'
        }, status: :not_found
      end

      def document_params
        params.require(:document).permit(
          :title, :description, :file_url, :file_name,
          :file_size, :file_type, :category, :project_id
        )
      end

      def document_payload(document)
        {
          id: document.id,
          title: document.title,
          description: document.description,
          file_url: document.file_url,
          file_name: document.file_name,
          file_size: document.file_size,
          file_type: document.file_type,
          formatted_size: document.formatted_size,
          icon: document.icon,
          category: document.category,
          project_id: document.project_id,
          created_at: document.created_at
        }
      end
    end
  end
end