class PagesController < ApplicationController
  def dashboard
    @catalogue_count = Item.count
    @inside_count = InventoryUnit.inside.count
    @outside_count = InventoryUnit.outside.count
    @items = Item.order(:name, :id)
    @stock = InventoryUnit.group(:item_id, :state).count
    @batches = MovementBatch.order(created_at: :desc, id: :desc).limit(15)
    @batch_counts = Movement.where(movement_batch_id: @batches.map(&:id)).group(:movement_batch_id).count
  end
end