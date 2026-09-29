require "test_helper"

class ItemTest < ActiveSupport::TestCase
  test "valid item can be created with default status" do
    item = Item.create!(name: "Test item", item_type: "Sheet", origin: "manufactured")
    assert item.persisted?
    assert_equal "new", item.reload.status
  end

  test "name is required" do
    item = Item.new(name: " ", item_type: "Sheet", origin: "purchased")
    assert_not item.save
    assert_includes item.errors[:name], "can't be blank"
  end

  test "item type is required" do
    [ nil, "", " " ].each do |value|
      item = Item.new(name: "Test item", item_type: value, origin: "purchased")
      assert_not item.save
      assert_includes item.errors[:item_type], "can't be blank"
    end
  end

  test "origin is required" do
    item = Item.new(name: "Test item", item_type: "Sheet", origin: nil)
    assert_not item.save
    assert_includes item.errors[:origin], "can't be blank"
  end

  test "invalid origin is rejected" do
    item = Item.new(name: "Test item", item_type: "Sheet", origin: "borrowed")
    assert_not item.save
    assert_includes item.errors[:origin], "is not included in the list"
  end

  test "both origins are allowed" do
    %w[manufactured purchased].each do |origin|
      assert Item.create!(name: "Test item", item_type: "Sheet", origin: origin).persisted?
    end
  end

  test "status is required when explicitly blank" do
    [ nil, "", " " ].each do |value|
      item = Item.new(name: "Test item", item_type: "Sheet", origin: "purchased", status: value)
      assert_not item.save
      assert_includes item.errors[:status], "can't be blank"
    end
  end

  test "invalid status is rejected" do
    item = Item.new(name: "Test item", item_type: "Sheet", origin: "purchased", status: "available")
    assert_not item.save
    assert_includes item.errors[:status], "is not included in the list"
  end

  test "all specified statuses are allowed" do
    %w[new consumed damaged defective].each do |status|
      assert Item.create!(name: "Test item", item_type: "Sheet", origin: "purchased", status: status).persisted?
    end
  end

  test "variant may be blank" do
    [ nil, "", " " ].each do |variant|
      assert Item.create!(name: "Test item", item_type: "Sheet", origin: "purchased", variant: variant).persisted?
    end
  end

  test "variant may be populated" do
    item = Item.create!(name: "Test item", item_type: "Sheet", origin: "purchased", variant: "Blue")
    assert_equal "Blue", item.reload.variant
  end

  test "database enforces required columns without model validations" do
    %i[name item_type origin status].each do |attribute|
      assert_raises ActiveRecord::NotNullViolation do
        Item.transaction(requires_new: true) do
          item = Item.new(name: "Test item", item_type: "Sheet", origin: "purchased")
          item[attribute] = nil
          item.save!(validate: false)
        end
      end
    end
  end

  test "database supplies status default when omitted" do
    result = Item.insert_all!([ { name: "Test item", item_type: "Sheet", origin: "purchased" } ], returning: %w[id status])
    assert_equal "new", result.first["status"]
  end

  test "schema contains only the new domain attributes and normal record fields" do
    assert_equal %w[created_at id item_type name origin status updated_at variant], Item.column_names.sort
  end
end