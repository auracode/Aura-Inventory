class MovementBatch < ApplicationRecord
  has_many :movements, dependent: :restrict_with_error
  has_many :inventory_units, through: :movements

  validates :direction, inclusion: { in: %w[in out] }
  validates :taken_by, presence: true, if: -> { direction == "out" }
  validates :request_key, :payload_digest, presence: true

  def reference
    "#{direction.upcase}-#{id.to_s.rjust(6, '0')}"
  end
end