class Project < ApplicationRecord
  before_validation :assign_default_client, on: :create

  belongs_to :user
  belongs_to :client
  belongs_to :company
  has_many :tasks, dependent: :destroy
  has_one  :deadline_event,
    -> { where(source: 'project') },
    class_name: 'Event',
    foreign_key: :source_id,
    dependent: :destroy

  STATUSES = %w[active on_hold completed cancelled].freeze
  COLORS = %w[
    #8B2A2A #B34A30 #4A8C6A #A87830
    #7A8A96 #6B4A8A #4A6A8A #8A6A4A
  ].freeze

  validates :title, presence: true
  validates :client_id, presence: true
  validates :status, inclusion: { in: STATUSES }

  scope :active,    -> { where(status: 'active') }
  scope :search,    ->(q) { where('title ILIKE ?', "%#{q}%") }

  # Sync deadline to calendar after save
  after_save  :sync_deadline_event
  after_destroy :cleanup_deadline_event

  def task_counts
    tasks.group(:status).count
  end

  def completion_percentage
    total = tasks.count
    return 0 if total.zero?
    completed = tasks.where(status: 'completed').count
    ((completed.to_f / total) * 100).round
  end

  private

  def sync_deadline_event
    return unless end_date.present?

    event_data = {
      title: "#{title} — Deadline",
      description: description,
      start_time: end_date.to_datetime.beginning_of_day,
      end_time: end_date.to_datetime.end_of_day,
      all_day: true,
      event_type: 'deadline',
      source: 'project',
      source_id: id,
      user: user,
      company: company
    }

    if deadline_event.present?
      deadline_event.update!(event_data)
    else
      Event.create!(event_data)
    end
  end

  def cleanup_deadline_event
    deadline_event&.destroy
  end

  def assign_default_client
    self.client_id ||= default_client_id
  end


  def default_client_id
    Client.find_by(internal: true, user: user)&.id
  end
end
