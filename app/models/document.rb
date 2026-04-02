class Document < ApplicationRecord
  belongs_to :user
  belongs_to :company
  belongs_to :project, optional: true
  has_one_attached :file

  CATEGORIES = %w[
    contract proposal template
    brief report policy general
  ].freeze

  validates :title, presence: true
  validates :category, inclusion: { in: CATEGORIES }

  scope :search,   ->(q) { where('title ILIKE ?', "%#{q}%") }
  scope :by_category, ->(c) { where(category: c) }

  def formatted_size
    return nil unless file_size
    if file_size < 1024
      "#{file_size} B"
    elsif file_size < 1024 * 1024
      "#{(file_size / 1024.0).round(1)} KB"
    else
      "#{(file_size / (1024.0 * 1024)).round(1)} MB"
    end
  end

  def icon
    case file_type&.downcase
    when 'pdf' then '📄'
    when 'doc', 'docx' then '📝'
    when 'xls', 'xlsx' then '📊'
    when 'ppt', 'pptx' then '📋'
    when 'jpg', 'jpeg',
         'png', 'gif'  then '🖼'
    when 'zip', 'rar'  then '📦'
    else '📎'
    end
  end
end
