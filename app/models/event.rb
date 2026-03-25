class Event < ApplicationRecord
  belongs_to :user

  EVENT_TYPES = %w[meeting deadline follow_up task].freeze
  SOURCES = %w[manual project task].freeze

  COLORS = {
    'meeting'   => '#8B2A2A',
    'deadline'  => '#B34A30',
    'follow_up' => '#A87830',
    'task'      => '#4A8C6A'
  }.freeze

  validates :title, presence:true
  validates :start_time, presence: true
  validates :end_time, presence: true
  validates :event_type, inclusion: {in: EVENT_TYPES}
  validates :source, inclusion: { in: SOURCES }

  validate :end_time_after_start_time

  before_save :set_color

  scope :from_project, ->(id) {
    where(source: 'project', source_id: id)
  }

  def manual?
    source == 'manual'
  end

  private

  def end_time_after_start_time
    return unless start_time && end_time
    if end_time < start_time
      errors.add(:end_time, 'must be after start time')
    end
  end

  def set_color
    self.color = COLORS[event_type] if color.blank?
  end

end
