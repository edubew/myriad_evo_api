module CompanyScoped
  extend ActiveSupport::Concern

  included do
    # Default scope: never return records without a company_id
    validates :company_id, presence: true

    scope :for_company, ->(company) { where(company: company) }
  end
end