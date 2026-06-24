module Deals
  class ReorderService < ApplicationService
    def initialize(company:, deals_data:)
      @company    = company
      @deals_data = deals_data
    end

    def call
      ActiveRecord::Base.transaction do
        @deals_data.each_with_index do |deal_data, index|
          # Always scope to company — never to user
          deal = @company.deals.find(deal_data[:id])
          deal.update!(
            status:   deal_data[:status],
            position: index
          )
        end
      end
      success(true)
    rescue ActiveRecord::RecordNotFound
      failure(['One or more deals not found or do not belong to your company'])
    rescue ActiveRecord::RecordInvalid => e
      failure(e.record.errors.full_messages)
    end
  end
end