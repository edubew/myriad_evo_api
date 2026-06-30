module Deals
  class ReorderService < ApplicationService
    def initialize(company:, deals_data:)
      @company    = company
      @deals_data = deals_data
    end

    def call
      return failure(['deals must be an array']) unless @deals_data.is_a?(Array)
      return failure(['deals cannot be empty'])  if @deals_data.empty?

      ActiveRecord::Base.transaction do
        @deals_data.each_with_index do |deal_data, index|
          deal = @company.deals.find(deal_data[:id])

          unless Deal::STATUSES.include?(deal_data[:status].to_s)
            raise ActiveRecord::Rollback,
                  "Invalid status '#{deal_data[:status]}' for deal #{deal_data[:id]}"
          end

          deal.update!(
            status:   deal_data[:status],
            position: index
          )
        end
      end

      success(true)

    rescue ActiveRecord::RecordNotFound => e
      failure(['One or more deals not found or do not belong to your organization'])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    rescue ActiveRecord::Rollback => e
      failure([e.message])
    end
  end
end
