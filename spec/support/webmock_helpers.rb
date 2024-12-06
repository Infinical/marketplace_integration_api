module Support
module WebmockHelpers
  def stub_marketplace_a_success
    stub_request(:post, "http://localhost:3001/api/products")
      .to_return(
        status: 201,
        body: { id: "12345", status: "success" }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )
  end

  def stub_marketplace_a_failure
    stub_request(:post, "http://localhost:3001/api/products")
      .to_return(status: 500)
  end

  def stub_marketplace_b_success
    # Step 1: Create inventory
    stub_request(:post, "http://localhost:3002/inventory")
      .to_return(
        status: 200,
        body: { inventory_id: "67890", status: "created" }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )

    # Step 2: Publish
    stub_request(:post, "http://localhost:3002/inventory/67890/publish")
      .to_return(
        status: 200,
        body: { listing_id: "L123", status: "published" }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )
  end

  def stub_marketplace_b_creation_failure
    stub_request(:post, "http://localhost:3002/inventory")
      .to_return(status: 500)
  end

  def stub_marketplace_b_publish_failure
    # Step 1: Successful creation
    stub_request(:post, "http://localhost:3002/inventory")
      .to_return(
        status: 200,
        body: { inventory_id: "67890", status: "created" }.to_json,
        headers: { 'Content-Type': 'application/json' }
      )

    # Step 2: Failed publish
    stub_request(:post, "http://localhost:3002/inventory/67890/publish")
      .to_return(status: 500)
  end
end
end
