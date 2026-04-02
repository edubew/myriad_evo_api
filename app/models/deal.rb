class Deal < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :client, optional: true

  STATUSES = %w[
    lead qualified proposal_sent
    negotiation closed_won closed_lost
  ].freeze

  STAGE_LABELS = {
    'lead'          => 'Lead',
    'qualified'     => 'Qualified',
    'proposal_sent' => 'Proposal Sent',
    'negotiation'   => 'Negotiation',
    'closed_won'    => 'Closed Won',
    'closed_lost'   => 'Closed Lost'
  }.freeze

  STAGE_COLORS = {
    'lead'          => '#9090A8',
    'qualified'     => '#60A5FA',
    'proposal_sent' => '#A78BFA',
    'negotiation'   => '#FBBF24',
    'closed_won'    => '#34D399',
    'closed_lost'   => '#F87171'
  }.freeze

  validates :title,       presence: true
  validates :probability, numericality: {
    greater_than_or_equal_to: 0,
    less_than_or_equal_to: 100
  }
  validates :status, inclusion: { in: STATUSES }

  scope :active, -> {
    where.not(status: %w[closed_won closed_lost])
  }

  def stage_label
    STAGE_LABELS[status]
  end

  def stage_color
    STAGE_COLORS[status]
  end

  def weighted_value
    (value * probability / 100.0).round(2)
  end
end
