class InventoryUnit < ApplicationRecord
  belongs_to :item
  has_many :movements, dependent: :restrict_with_error

  validates :barcode, presence: true, uniqueness: true
  validates :state, inclusion: { in: %w[in out] }

  scope :inside, -> { where(state: "in") }
  scope :outside, -> { where(state: "out") }
end