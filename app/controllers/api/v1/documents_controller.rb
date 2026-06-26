module Api
  module V1
    class DocumentsController < BaseController
      include Rails.application.routes.url_helpers

      before_action :set_document, only: [:show, :update, :destroy]

      def index
        @documents = policy_scope(Document)
        @documents = @documents.search(params[:q])              if params[:q].present?
        @documents = @documents.by_category(params[:category])  if params[:category].present?

        if params[:project_id].present?
          project = current_company.projects.find_by(id: params[:project_id])
          if project
            @documents = @documents.where(project_id: project.id)
          else
            return render json: { success: false, error: 'Project not found' },
                          status: :not_found
          end
        end

        @documents = @documents.order(created_at: :desc)

        render json: {
          success: true,
          data:    @documents.map { |d| document_payload(d) }
        }
      end

      def show
        authorize @document
        render json: { success: true, data: document_payload(@document) }
      end

      def create
        if params.dig(:document, :project_id).present?
          project = current_company.projects.find_by(
            id: params.dig(:document, :project_id)
          )
          unless project
            return render json: {
              success: false,
              errors:  ['Project not found in your organization']
            }, status: :unprocessable_content
          end
        end

        @document = current_company.documents.build(
          document_params.merge(user: current_user)
        )

        authorize @document

        if @document.save
          render json: {
            success: true,
            data:    document_payload(@document)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @document.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @document

        if document_params[:project_id].present?
          unless current_company.projects.exists?(id: document_params[:project_id])
            return render json: {
              success: false,
              errors:  ['Project not found in your organization']
            }, status: :unprocessable_content
          end
        end

        if @document.update(document_params)
          render json: {
            success: true,
            data:    document_payload(@document)
          }
        else
          render json: {
            success: false,
            errors:  @document.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @document
        @document.destroy
        render json: { success: true, message: 'Document deleted' }
      end

      private

      def set_document
        @document = policy_scope(Document).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Document not found' }, status: :not_found
      end

      def document_params
        params.require(:document).permit(
          :title, :description, :category, :project_id, :file
        )
      end

      def document_payload(document)
        file_attached = document.file.attached?
        {
          id:          document.id,
          title:       document.title,
          description: document.description,
          category:    document.category,
          project_id:  document.project_id,
          file_url:    file_attached ? url_for(document.file) : nil,
          file_name:   file_attached ? document.file.filename.to_s : nil,
          file_type:   file_attached ? document.file.content_type : nil,
          file_size:   file_attached ? document.file.byte_size : nil,
          created_at:  document.created_at
        }
      end
    end
  end
end