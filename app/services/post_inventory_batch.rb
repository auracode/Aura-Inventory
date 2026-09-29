require "digest"

# The only write path for stock movements. A transaction makes the whole batch
# atomic; the PostgreSQL advisory lock also protects previously unseen barcodes.
class PostInventoryBatch
  include ActiveModel::Model

  attr_accessor :direction, :item_id, :taken_by, :client_code, :barcodes_text, :request_key, :scan_times
  attr_reader :batch

  validates :direction, inclusion: { in: %w[in out] }
  validates :request_key, format: { with: /\A[0-9a-f-]{36}\z/i }
  validates :taken_by, presence: true, if: -> { direction == "out" }
  validates :item_id, presence: true, if: -> { direction == "in" }
  validate :validate_barcodes

  def barcodes
    barcodes_text.to_s.lines.map(&:strip).reject(&:blank?)
  end

  def save
    self.taken_by = taken_by.to_s.strip.presence
    self.client_code = client_code.to_s.strip.presence
    return false unless valid?

    succeeded = false
    ApplicationRecord.transaction do
      ApplicationRecord.connection.execute("SELECT pg_advisory_xact_lock(41827, 1)")
      digest = Digest::SHA256.hexdigest([ direction, item_id.to_s, taken_by, client_code, barcodes.sort ].to_json)
      existing = MovementBatch.find_by(request_key: request_key)
      if existing
        if existing.payload_digest == digest
          @batch = existing
          succeeded = true
        else
          errors.add(:base, "This form has already saved a different batch. Open a fresh movement page.")
        end
        next
      end

      selected_item = Item.find_by(id: item_id) if direction == "in"
      if direction == "in" && !selected_item
        errors.add(:base, "Select an existing item.")
        next
      end

      units = InventoryUnit.where(barcode: barcodes).index_by(&:barcode)
      barcodes.each do |barcode|
        unit = units[barcode]
        if direction == "out" && !unit
          errors.add(:base, "#{barcode}: must be received inward before it can go outward.")
        elsif unit&.state == direction
          errors.add(:base, "#{barcode}: already #{direction.upcase}.")
        elsif direction == "in" && unit && unit.item_id != selected_item.id
          errors.add(:base, "#{barcode}: belongs to a different item. Select #{unit.item.name}.")
        end
      end
      next if errors.any?

      @batch = MovementBatch.create!(
        direction: direction, taken_by: direction == "out" ? taken_by : nil,
        client_code: direction == "out" ? client_code : nil,
        request_key: request_key, payload_digest: digest
      )
      barcodes.each do |barcode|
        unit = units[barcode] || InventoryUnit.new(item: selected_item, barcode: barcode)
        unit.update!(state: direction)
        @batch.movements.create!(inventory_unit: unit, scanned_at: scanned_time(barcode))
      end
      succeeded = true
    end
    succeeded
  rescue ActiveRecord::RecordInvalid, ActiveRecord::RecordNotUnique, ActiveRecord::InvalidForeignKey => error
    errors.add(:base, "The batch could not be saved. Reload the inventory state and try again.")
    Rails.logger.warn("Inventory batch rejected: #{error.class}")
    false
  end

  private

  def validate_barcodes
    errors.add(:base, "Scan or enter at least one barcode.") if barcodes.empty?
    duplicates = barcodes.tally.select { |_barcode, count| count > 1 }.keys
    errors.add(:base, "Duplicate barcodes: #{duplicates.join(', ')}.") if duplicates.any?
  end

  def scanned_time(barcode)
    value = scan_times.to_h[barcode]
    parsed = Time.iso8601(value.to_s) if value.present?
    # Browser times are informational. Reject future/unreasonably old timestamps.
    parsed && parsed.between?(24.hours.ago, Time.current + 1.minute) ? parsed : Time.current
  rescue ArgumentError
    Time.current
  end
end