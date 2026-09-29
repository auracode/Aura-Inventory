class Movement < ApplicationRecord
  belongs_to :movement_batch
  belongs_to :inventory_unit
  validates :scanned_at, presence: true
end