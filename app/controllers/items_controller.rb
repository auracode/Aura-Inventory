class ItemsController < ApplicationController
  before_action :set_item, only: %i[show edit update destroy]

  def index
    @items = Item.order(:item_type, :variant, :id)
  end

  def show
    @units = @item.inventory_units.includes(movements: :movement_batch).order(:barcode)
  end

  def new
    @item = Item.new
  end

  def edit
  end

  def create
    @item = Item.new(item_params)
    if @item.save
      redirect_to @item, notice: "Item created successfully.", status: :see_other
    else
      render :new, status: :unprocessable_entity
    end
  end

  def update
    if @item.update(item_params)
      redirect_to @item, notice: "Item updated successfully.", status: :see_other
    else
      render :edit, status: :unprocessable_entity
    end
  end

  def destroy
    unless @item.destroy
      redirect_to @item, alert: "This item has inventory units and cannot be deleted.", status: :see_other
      return
    end
    redirect_to items_path, notice: "Item deleted successfully.", status: :see_other
  end

  private

  def set_item
    @item = Item.find(params[:id])
  end

  def item_params
    params.require(:item).permit(:name, :item_type, :variant, :origin, :status)
  end
end