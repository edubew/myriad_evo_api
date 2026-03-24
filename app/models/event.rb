class Event < ApplicationRecord
  belongs_to :user

  EVENT_TYPES = %w[meeting deadline follow_up task].freeze

  COLORS = {
    'meeting'   => '#6C63FF',
    'deadline'  => '#F87171',
    'follow_up' => '#FBBF24',
    'task'      => '#34D399'
}.freeze

validates :title, presence:true
validates :start_time, presence: true
validates :end_time, presence: true
validates :event_type, inclusion: {in: EVENT_TYPES}

validate :end_time_after_start_time

before_save :set_color

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
