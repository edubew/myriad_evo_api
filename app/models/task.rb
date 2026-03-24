class Task < ApplicationRecord
  belongs_to :user
  belongs_to :project
  belongs_to :assignee, class_name: 'User', optional: true

  STATUSES = %w[backlog in_progress review completed].freeze
  PRIORITIES = %w[low medium high urgent].freeze

  PRIORITY_COLORS = {
    'low'    => '#34D399',
    'medium' => '#60A5FA',
    'high'   => '#FBBF24',
    'urgent' => '#F87171'
  }.freeze

  validates :title,    presence: true
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :for_status, ->(s) { where(status: s).order(:position) }

  def priority_color
    PRIORITY_COLORS[priority]
  end
end
