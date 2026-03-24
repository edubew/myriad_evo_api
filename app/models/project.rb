class Project < ApplicationRecord
  belongs_to :user
  belongs_to :client, optional: true
  has_many :tasks, dependent: :destroy

  STATUSES = %w[active on_hold completed cancelled].freeze
  COLORS   = %w[
    #6C63FF #F87171 #34D399 #FBBF24
    #60A5FA #F472B6 #A78BFA #FB923C
  ].freeze

  validates :title,  presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :active,    -> { where(status: 'active') }
  scope :search,    ->(q) { where('title ILIKE ?', "%#{q}%") }

  def task_counts
    tasks.group(:status).count
  end

  def completion_percentage
    total = tasks.count
    return 0 if total.zero?
    completed = tasks.where(status: 'completed').count
    ((completed.to_f / total) * 100).round
  end
end
