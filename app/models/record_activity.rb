class RecordActivity < ApplicationRecord
  belongs_to :actor, class_name: 'User'
  belongs_to :resource, polymorphic: true

  validates :resource, :actor, :activity_type, presence: true

  def self.activity_types
    %w(Created Published)
  end

end