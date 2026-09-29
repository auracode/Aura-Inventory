require "test_helper"

class ItemsControllerTest < ActionDispatch::IntegrationTest
  setup do
    @item = items(:one)
  end

  test "index lists items and actions" do
    [ items_path ].each do |path|
      get path
      assert_response :success
      assert_select "td", text: @item.item_type
      assert_select "a[href=?]", new_item_path, text: "Add Item"
      assert_select "a[href=?]", item_path(@item), text: "View"
      assert_select "a[href=?]", edit_item_path(@item), text: "Edit"
      assert_select "form[action=?] input[name='_method'][value='delete']", item_path(@item)
    end
  end

  test "empty index offers first item creation" do
    Item.delete_all
    get items_path
    assert_response :success
    assert_select "p", text: "No items yet. Add your first item to get started."
  end

  test "show displays current domain fields" do
    get item_path(@item)
    assert_response :success
    [ @item.item_type, @item.variant, @item.origin.humanize, @item.status.humanize ].each do |value|
      assert_select "dd", text: value
    end
  end

  test "new offers allowed origins and statuses and defaults to new" do
    get new_item_path
    assert_response :success
    assert_select "input[name='item[item_type]'][required]"
    assert_select "input[name='item[variant]']"
    assert_select "select[name='item[origin]'] option[value]", count: 3
    %w[manufactured purchased].each do |origin|
      assert_select "select[name='item[origin]'] option[value=?]", origin
    end
    %w[new consumed damaged defective].each do |status|
      assert_select "select[name='item[status]'] option[value=?]", status
    end
    assert_select "select[name='item[status]'] option[selected][value='new']"
  end

  test "edit populates saved fields" do
    get edit_item_path(@item)
    assert_response :success
    assert_select "input[name='item[item_type]'][value=?]", @item.item_type
    assert_select "select[name='item[origin]'] option[selected][value=?]", @item.origin
  end

  test "create permits domain fields and ignores id" do
    assert_difference("Item.count", 1) do
      post items_path, params: { item: { name: "Test item", item_type: "Panel", variant: "Large", origin: "purchased", status: "damaged", id: 999999 } }
    end
    item = Item.order(:id).last
    assert_equal [ "Panel", "Large", "purchased", "damaged" ], item.attributes.values_at("item_type", "variant", "origin", "status")
    assert_not_equal 999999, item.id
    assert_redirected_to item_path(item)
    follow_redirect!
    assert_select "[role=status]", text: "Item created successfully."
  end

  test "create allows blank variant and defaults omitted status" do
    assert_difference("Item.count", 1) do
      post items_path, params: { item: { name: "Test item", item_type: "Panel", variant: "", origin: "manufactured" } }
    end
    assert_equal "new", Item.order(:id).last.status
  end

  test "invalid create shows errors and retains entered values" do
    assert_no_difference("Item.count") do
      post items_path, params: { item: { name: "Test item", item_type: "", variant: "Large", origin: "invalid", status: "invalid" } }
    end
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /Item type can't be blank/
    assert_select "[role=alert]", text: /Origin is not included in the list/
    assert_select "[role=alert]", text: /Status is not included in the list/
    assert_select "input[name='item[variant]'][value='Large']"
  end

  test "update saves permitted fields" do
    patch item_path(@item), params: { item: { name: "Test item", item_type: "Updated", variant: "", origin: "purchased", status: "consumed" } }
    assert_redirected_to item_path(@item)
    assert_response :see_other
    assert_equal [ "Updated", "", "purchased", "consumed" ], @item.reload.attributes.values_at("item_type", "variant", "origin", "status")
  end

  test "invalid update does not change the saved item" do
    original = @item.attributes
    patch item_path(@item), params: { item: { name: "Test item", item_type: "", status: "invalid" } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]"
    assert_equal original, @item.reload.attributes
  end

  test "destroy removes item and returns to index" do
    assert_difference("Item.count", -1) { delete item_path(@item) }
    assert_response :see_other
    assert_redirected_to items_path
    follow_redirect!
    assert_select "[role=status]", text: "Item deleted successfully."
  end

  test "unknown item returns not found" do
    get item_path(id: 0)
    assert_response :not_found
  end
end