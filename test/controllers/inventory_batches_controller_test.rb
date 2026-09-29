require "test_helper"

class InventoryBatchesControllerTest < ActionDispatch::IntegrationTest
  test "four primary screens load and dashboard is default" do
    { root_path => "Dashboard", creation_path => "Creation", inward_path => "Inward", outward_path => "Outward" }.each do |path, heading|
      get path
      assert_response :success
      assert_select "h1", heading
      assert_select "nav a", count: 4
    end
  end

  test "inward offers catalogue and outward requires taken by" do
    get inward_path
    assert_select "select[name='batch[item_id]'] option[value=?]", items(:one).id.to_s
    get outward_path
    assert_select "input[name='batch[taken_by]'][required]"
    assert_select "input[name='batch[client_code]']:not([required])"
  end

  test "scan checks never write stock" do
    assert_no_difference("InventoryUnit.count") do
      get check_inventory_batch_path, params: { direction: "in", barcode: "ABC", item_id: items(:one).id }
    end
    assert_response :success
    assert response.parsed_body["accepted"]
    get check_inventory_batch_path, params: { direction: "out", barcode: "ABC" }
    assert_not response.parsed_body["accepted"]
  end

  test "receive issue return and display batch detail and dashboard counts" do
    key = SecureRandom.uuid
    post inward_path, params: { batch: { item_id: items(:one).id, barcodes_text: "001\n002", request_key: key } }
    assert_response :see_other
    follow_redirect!
    assert_select "td", text: "001"
    get root_path
    assert_select ".inventory-summary section", text: /Units IN\s*2/
    post outward_path, params: { batch: { taken_by: "Ramesh", barcodes_text: "001", request_key: SecureRandom.uuid } }
    assert_response :see_other
    get root_path
    assert_select ".inventory-summary section", text: /Units OUT\s*1/
    post inward_path, params: { batch: { item_id: items(:one).id, barcodes_text: "001", request_key: SecureRandom.uuid } }
    assert_response :see_other
    assert_equal 2, InventoryUnit.inside.count
    assert_equal 4, Movement.count
  end

  test "save rechecks invalid state and retains entered data" do
    request = { item_id: items(:one).id, barcodes_text: "ABC", request_key: SecureRandom.uuid }
    post inward_path, params: { batch: request }
    request[:request_key] = SecureRandom.uuid
    assert_no_difference("Movement.count") { post inward_path, params: { batch: request } }
    assert_response :unprocessable_entity
    assert_select "[role=alert]", text: /already IN/
    assert_select "textarea", text: "ABC"
  end

  test "request cannot override the direction determined by the page" do
    post outward_path, params: { batch: { direction: "in", item_id: items(:one).id, taken_by: "Ramesh", barcodes_text: "UNKNOWN", request_key: SecureRandom.uuid } }
    assert_response :unprocessable_entity
    assert_equal 0, InventoryUnit.count
  end

  test "item deletion with stock shows an error without losing history" do
    PostInventoryBatch.new(direction: "in", item_id: items(:one).id, barcodes_text: "ABC", request_key: SecureRandom.uuid).save
    delete item_path(items(:one))
    assert_redirected_to item_path(items(:one))
    follow_redirect!
    assert_select "[role=alert]", text: /cannot be deleted/
    assert_equal 1, Movement.count
  end
end