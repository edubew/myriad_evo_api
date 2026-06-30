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
  validate  :assignee_must_belong_to_company
  validates :status,   inclusion: { in: STATUSES }
  validates :priority, inclusion: { in: PRIORITIES }

  scope :for_status, ->(s) { where(status: s).order(:position) }

  def priority_color
    PRIORITY_COLORS[priority]
  end

  private

  def assignee_must_belong_to_company
    return if assignee_id.blank?

    task_company_id = company_id || project&.company_id
    return if task_company_id.nil?

    unless User.exists?(id: assignee_id, company_id: task_company_id)
      errors.add(:assignee, 'must be a member of your organization')
    end
  end
end