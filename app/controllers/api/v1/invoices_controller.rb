module Api
  module V1
    class InvoicesController < BaseController
      before_action :set_invoice, only: [:show, :update, :destroy]

      def index
        @invoices = policy_scope(Invoice)
                      .includes(:client)
                      .order(created_at: :desc)

        @invoices = @invoices.where(status: params[:status])    if params[:status].present?
        @invoices = @invoices.where(client_id: params[:client_id]) if params[:client_id].present?

        render json: {
          success: true,
          data:    @invoices.map { |i| invoice_payload(i) },
          summary: invoice_summary
        }
      end

      def show
        authorize @invoice
        render json: {
          success: true,
          data:    invoice_payload(@invoice)
        }
      end

      def create
        @invoice = current_company.invoices.build(invoice_params.merge(user: current_user))

        if @invoice.client_id.present?
          unless current_company.clients.exists?(id: @invoice.client_id)
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        authorize @invoice

        if @invoice.save
          render json: {
            success: true,
            data:    invoice_payload(@invoice)
          }, status: :created
        else
          render json: {
            success: false,
            errors:  @invoice.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        authorize @invoice

        if invoice_params[:client_id].present?
          unless current_company.clients.exists?(id: invoice_params[:client_id])
            return render json: {
              success: false,
              errors:  ['Client not found in your organization']
            }, status: :unprocessable_content
          end
        end

        if invoice_params[:status] == 'paid'
          unless current_user.admin?
            return render json: {
              success: false,
              error:   'Only admins can mark invoices as paid'
            }, status: :forbidden
          end

          # Server-sets paid_date — ignore any client-supplied value
          @invoice.paid_date = Date.today if @invoice.status != 'paid'
        end

        safe_params = invoice_params.except(:paid_date)

        if @invoice.update(safe_params)
          render json: { success: true, data: invoice_payload(@invoice) }
        else
          render json: {
            success: false,
            errors:  @invoice.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        authorize @invoice
        @invoice.destroy
        render json: { success: true, message: 'Invoice deleted' }
      end

      private

      def set_invoice
        @invoice = policy_scope(Invoice).find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Invoice not found' }, status: :not_found
      end

      def invoice_params
        params.require(:invoice).permit(
          :title, :amount, :tax_rate, :status,
          :issued_date, :due_date, :paid_date,
          :notes, :client_id
        ).tap do |p|
          p[:client_id] = nil if p[:client_id].blank?
        end
      end

      def invoice_payload(invoice)
        {
          id:             invoice.id,
          invoice_number: invoice.invoice_number,
          title:          invoice.title,
          amount:         invoice.amount.to_f,
          tax_rate:       invoice.tax_rate.to_f,
          tax_amount:     invoice.tax_amount.to_f,
          total_amount:   invoice.total_amount.to_f,
          status:         invoice.status,
          issued_date:    invoice.issued_date,
          due_date:       invoice.due_date,
          paid_date:      invoice.paid_date,
          days_until_due: invoice.days_until_due,
          overdue:        invoice.overdue?,
          notes:          invoice.notes,
          client_id:      invoice.client_id,
          client_name:    invoice.client&.company_name,
          created_at:     invoice.created_at
        }
      end

      def invoice_summary
        invoices = current_company.invoices
        {
          total_invoiced: invoices.sum(:total_amount).to_f,
          total_paid:     invoices.paid.sum(:total_amount).to_f,
          total_pending:  invoices.pending.sum(:total_amount).to_f,
          overdue_count:  invoices.overdue.count,
          draft_count:    invoices.where(status: 'draft').count
        }
      end
    end
  end
end