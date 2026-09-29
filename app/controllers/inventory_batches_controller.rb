class InventoryBatchesController < ApplicationController
  def inward
    prepare_form("in")
  end

  def outward
    prepare_form("out")
  end

  def create_inward
    save_batch("in")
  end

  def create_outward
    save_batch("out")
  end

  def show
    @batch = MovementBatch.find(params[:id])
    @movements = @batch.movements.includes(inventory_unit: :item).order(:id)
  end

  # Read-only scan feedback. All checks are repeated inside the save transaction.
  def check
    direction = params[:direction]
    barcode = params[:barcode].to_s.strip
    unit = InventoryUnit.includes(:item).find_by(barcode: barcode)
    selected = Item.find_by(id: params[:item_id]) if direction == "in"
    error = if !%w[in out].include?(direction)
      "Invalid movement direction."
    elsif barcode.blank?
      "Enter a barcode."
    elsif direction == "in" && !selected
      "Select an item first."
    elsif direction == "out" && !unit
      "Unknown barcode. Receive this unit inward first."
    elsif unit&.state == direction
      "This unit is already #{direction.upcase}."
    elsif direction == "in" && unit && unit.item_id != selected.id
      "This barcode belongs to #{unit.item.name}. Select that item first."
    end
    render json: { accepted: error.nil?, error: error, item_name: (unit&.item || selected)&.name }
  end

  private

  def prepare_form(direction)
    @direction = direction
    @entry ||= PostInventoryBatch.new(direction: direction, request_key: SecureRandom.uuid)
    @items = Item.order(:name, :item_type, :variant) if direction == "in"
  end

  def save_batch(direction)
    input = params.require(:batch).permit(:item_id, :taken_by, :client_code, :barcodes_text, :request_key, :scan_times_json)
    times = JSON.parse(input.delete(:scan_times_json).presence || "{}")
    times = {} unless times.is_a?(Hash)
    @entry = PostInventoryBatch.new(input.to_h.merge(direction: direction, scan_times: times))
    if @entry.save
      redirect_to inventory_batch_path(@entry.batch), notice: "#{@entry.batch.reference} saved successfully.", status: :see_other
    else
      prepare_form(direction)
      render direction == "in" ? :inward : :outward, status: :unprocessable_entity
    end
  rescue JSON::ParserError
    head :bad_request
  end
end