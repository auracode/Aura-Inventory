require "test_helper"

class PostInventoryBatchTest < ActiveSupport::TestCase
  def entry(direction, codes, **attributes)
    PostInventoryBatch.new({
      direction: direction, item_id: direction == "in" ? items(:one).id : nil,
      taken_by: direction == "out" ? "Ramesh" : nil,
      barcodes_text: codes, request_key: SecureRandom.uuid
    }.merge(attributes))
  end

  test "catalogue creation does not add stock" do
    assert_no_difference("InventoryUnit.count") do
      Item.create!(name: "Bottle", item_type: "250 ml", origin: "manufactured")
    end
  end

  test "inward creates individual units and a shared batch with scan timestamps" do
    scan_time = 2.minutes.ago.iso8601
    request = entry("in", "00001\n00002", scan_times: { "00001" => scan_time })
    assert_difference("InventoryUnit.count", 2) { assert request.save }
    assert_equal 2, request.batch.movements.count
    assert_equal [ "in" ], request.batch.inventory_units.distinct.pluck(:state)
    assert_equal Time.iso8601(scan_time), request.batch.movements.joins(:inventory_unit).find_by(inventory_units: { barcode: "00001" }).scanned_at
  end

  test "outward and return keep unit identity and preserve every event" do
    assert entry("in", "00001").save
    unit = InventoryUnit.find_by!(barcode: "00001")
    assert entry("out", "00001", client_code: "").save
    assert_equal "out", unit.reload.state
    assert entry("in", "00001").save
    assert_equal "in", unit.reload.state
    assert_equal 3, unit.movements.count
    assert_equal 1, InventoryUnit.where(barcode: "00001").count
  end

  test "new units cannot go outward" do
    request = entry("out", "UNKNOWN")
    assert_no_difference("MovementBatch.count") { assert_not request.save }
    assert_match(/before/, request.errors.full_messages.join)
  end

  test "duplicate scans in a batch are rejected" do
    request = entry("in", "ABC\nABC")
    assert_no_difference("InventoryUnit.count") { assert_not request.save }
  end

  test "blank batch is rejected" do
    assert_not entry("in", " \n ").save
  end

  test "already in and already out scans are rejected" do
    assert entry("in", "ABC").save
    assert_not entry("in", "ABC").save
    assert entry("out", "ABC").save
    assert_not entry("out", "ABC").save
    assert_equal 2, Movement.count
  end

  test "batch rejection never partially changes stock" do
    assert entry("in", "OLD").save
    assert_no_difference("InventoryUnit.count") do
      assert_no_difference("Movement.count") { assert_not entry("in", "NEW\nOLD").save }
    end
    assert_not InventoryUnit.exists?(barcode: "NEW")
    assert_equal "in", InventoryUnit.find_by!(barcode: "OLD").state
  end

  test "outward requires taken by but not client code" do
    assert entry("in", "ABC").save
    assert_not entry("out", "ABC", taken_by: " ").save
    assert entry("out", "ABC", client_code: nil).save
  end

  test "return cannot reassign an existing barcode to another catalogue item" do
    assert entry("in", "ABC").save
    assert entry("out", "ABC").save
    assert_not entry("in", "ABC", item_id: items(:two).id).save
    assert_equal items(:one).id, InventoryUnit.find_by!(barcode: "ABC").item_id
  end

  test "repeat submission returns the same saved batch without duplicate movements" do
    request = entry("in", "ABC")
    assert request.save
    saved_id = request.batch.id
    replay = entry("in", "ABC", request_key: request.request_key)
    assert_no_difference("Movement.count") { assert replay.save }
    assert_equal saved_id, replay.batch.id
    assert_not entry("in", "DIFFERENT", request_key: request.request_key).save
  end

  test "items with physical units cannot be deleted" do
    assert entry("in", "ABC").save
    assert_not items(:one).destroy
    assert Item.exists?(items(:one).id)
    assert_equal 1, Movement.count
  end

  test "database prevents duplicate unit barcodes" do
    assert entry("in", "ABC").save
    assert_raises ActiveRecord::RecordNotUnique do
      InventoryUnit.transaction(requires_new: true) do
        InventoryUnit.new(item: items(:one), barcode: "ABC", state: "in").save!(validate: false)
      end
    end
  end

  test "a nonexistent selected item cannot be saved" do
    assert_not entry("in", "ABC", item_id: 0).save
  end
end