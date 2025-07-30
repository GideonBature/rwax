use rwax::structs::asset::AssetData;

// Test basic get_asset_data functionality without contract deployment
#[test]
fn test_get_asset_data_struct_operations() {
    // Test that we can create and manipulate AssetData structures
    let asset_data = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "Luxury Villa",
        description: "Beautiful villa with ocean view",
        value_usd: 1500000,
        legal_doc_uri: "ipfs://villa-legal-docs",
        image_uri: "ipfs://villa-image",
        location: "Miami Beach",
        created_at: 1640995200,
    };

    // Verify all fields are set correctly
    assert(asset_data.asset_type == 'REAL_ESTATE', 'Asset type should match');
    assert(asset_data.name == "Luxury Villa", 'Name should match');
    assert(asset_data.description == "Beautiful villa with ocean view", 'Description should match');
    assert(asset_data.value_usd == 1500000, 'Value should match');
    assert(asset_data.legal_doc_uri == "ipfs://villa-legal-docs", 'Legal doc URI should match');
    assert(asset_data.image_uri == "ipfs://villa-image", 'Image URI should match');
    assert(asset_data.location == "Miami Beach", 'Location should match');
    assert(asset_data.created_at == 1640995200, 'Created at should match');
}

#[test]
fn test_get_asset_data_multiple_asset_types() {
    let real_estate = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "Luxury Villa",
        description: "Villa with ocean view",
        value_usd: 1500000,
        legal_doc_uri: "ipfs://villa-legal",
        image_uri: "ipfs://villa-image",
        location: "Miami Beach",
        created_at: 1640995200,
    };

    let art = AssetData {
        asset_type: 'ART',
        name: "Mona Lisa Replica",
        description: "High quality replica",
        value_usd: 50000,
        legal_doc_uri: "ipfs://art-legal",
        image_uri: "ipfs://art-image",
        location: "Museum",
        created_at: 1640995300,
    };

    let precious_metal = AssetData {
        asset_type: 'PRECIOUS_METAL',
        name: "Gold Bar 1kg",
        description: "999.9 pure gold bar",
        value_usd: 65000,
        legal_doc_uri: "ipfs://gold-legal",
        image_uri: "ipfs://gold-image",
        location: "Bank Vault",
        created_at: 1640995400,
    };

    // Verify all asset types are different
    assert(real_estate.asset_type != art.asset_type, 'Types should be different');
    assert(art.asset_type != precious_metal.asset_type, 'Types should be different');
    assert(real_estate.asset_type != precious_metal.asset_type, 'Types should be different');

    // Verify each has correct properties
    assert(real_estate.asset_type == 'REAL_ESTATE', 'Real estate type match');
    assert(art.asset_type == 'ART', 'Art type should match');
    assert(precious_metal.asset_type == 'PRECIOUS_METAL', 'Precious metal type match');

    // Verify values are different
    assert(real_estate.value_usd == 1500000, 'Real estate value match');
    assert(art.value_usd == 50000, 'Art value should match');
    assert(precious_metal.value_usd == 65000, 'Precious metal value match');
}
