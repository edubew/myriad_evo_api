module Api
  module V1
    class InvoicesController < BaseController
      before_action :set_invoice, only: [:show, :update, :destroy]

      def index
        @invoices = current_user.invoices
          .includes(:client)
          .order(created_at: :desc)

        @invoices = @invoices.where(status: params[:status]) if params[:status].present?
        @invoices = @invoices.where(client_id: params[:client_id]) if params[:client_id].present?

        render json: {
          success: true,
          data: @invoices.map { |i| invoice_payload(i) },
          summary: invoice_summary
        }
      end

      def show
        render json: {
          success: true,
          data: invoice_payload(@invoice)
        }
      end

      def create
        @invoice = current_user.invoices.build(invoice_params)
        if @invoice.save
          render json: {
            success: true,
            data: invoice_payload(@invoice)
          }, status: :created
        else
          render json: {
            success: false,
            errors: @invoice.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def update
        # Auto-set paid_date when marking as paid
        if params.dig(:invoice, :status) == 'paid' &&
           @invoice.status != 'paid'
          params[:invoice][:paid_date] = Date.today
        end

        if @invoice.update(invoice_params)
          render json: { success: true, data: invoice_payload(@invoice) }
        else
          render json: {
            success: false,
            errors: @invoice.errors.full_messages
          }, status: :unprocessable_content
        end
      end

      def destroy
        @invoice.destroy
        render json: { success: true, message: 'Invoice deleted' }
      end

      private

      def set_invoice
        @invoice = current_user.invoices.find(params[:id])
      rescue ActiveRecord::RecordNotFound
        render json: { success: false, error: 'Invoice not found' },
               status: :not_found
      end

      def invoice_params
        params.require(:invoice).permit(
          :title, :amount, :tax_rate, :status,
          :issued_date, :due_date, :paid_date,
          :notes, :client_id
        )
      end

      def invoice_payload(invoice)
        {
          id: invoice.id,
          invoice_number: invoice.invoice_number,
          title: invoice.title,
          amount: invoice.amount.to_f,
          tax_rate: invoice.tax_rate.to_f,
          tax_amount: invoice.tax_amount.to_f,
          total_amount: invoice.total_amount.to_f,
          status: invoice.status,
          issued_date: invoice.issued_date,
          due_date: invoice.due_date,
          paid_date: invoice.paid_date,
          days_until_due: invoice.days_until_due,
          overdue: invoice.overdue?,
          notes: invoice.notes,
          client_id: invoice.client_id,
          client_name: invoice.client&.company_name,
          created_at: invoice.created_at
        }
      end

      def invoice_summary
        invoices = current_user.invoices
        {
          total_invoiced: invoices.sum(:total_amount).to_f,
          total_paid: invoices.paid.sum(:total_amount).to_f,
          total_pending: invoices.pending.sum(:total_amount).to_f,
          overdue_count: invoices.overdue.count,
          draft_count: invoices.where(status: 'draft').count
        }
      end
    end
  end
end