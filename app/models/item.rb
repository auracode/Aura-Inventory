class Item < ApplicationRecord
  ORIGINS = %w[manufactured purchased].freeze
  STATUSES = %w[new consumed damaged defective].freeze

  has_many :inventory_units, dependent: :restrict_with_error
  validates :name, :item_type, :origin, :status, presence: true
  validates :origin, inclusion: { in: ORIGINS }
  validates :status, inclusion: { in: STATUSES }
end