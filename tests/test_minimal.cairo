use rwax::events::factory::{AssetTokenized, TokenizerRoleGranted};
use rwax::structs::asset::AssetData;
use starknet::{ContractAddress, contract_address_const};

// Test basic functionality without contract deployment
#[test]
fn test_asset_data_operations() {
    let asset_data = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "Test Property",
        description: "A test property",
        value_usd: 100,
        legal_doc_uri: "ipfs://test",
        image_uri: "ipfs://test",
        location: "Test Location",
        created_at: 100,
    };

    assert(asset_data.asset_type == 'REAL_ESTATE', 'Asset type should match');
    assert(asset_data.name == "Test Property", 'Name should match');
    assert(asset_data.value_usd == 100, 'Value should match');
    assert(asset_data.location == "Test Location", 'Location should match');
}

#[test]
fn test_asset_tokenized_event() {
    let owner = contract_address_const::<0x123>();
    let asset_data = AssetData {
        asset_type: 'ART',
        name: "Test Art",
        description: "Test art piece",
        value_usd: 50,
        legal_doc_uri: "ipfs://test",
        image_uri: "ipfs://test",
        location: "Gallery",
        created_at: 100,
    };

    let event = AssetTokenized {
        token_id: 0_u256, owner, asset_type: 'ART', asset_data: asset_data.clone(),
    };

    assert(event.token_id == 0_u256, 'Token ID should be 0');
    assert(event.owner == owner, 'Owner should match');
    assert(event.asset_type == 'ART', 'Asset type should match');
    assert(event.asset_data.name == asset_data.name, 'Asset data should match');
}

#[test]
fn test_tokenizer_role_granted_event() {
    let account = contract_address_const::<0x456>();
    let granter = contract_address_const::<0x789>();

    let event = TokenizerRoleGranted { account, granter };

    assert(event.account == account, 'Account should match');
    assert(event.granter == granter, 'Granter should match');
}

#[test]
fn test_multiple_asset_types() {
    let real_estate = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "House",
        description: "A house",
        value_usd: 200,
        legal_doc_uri: "ipfs://house",
        image_uri: "ipfs://house-image",
        location: "City",
        created_at: 100,
    };

    let art = AssetData {
        asset_type: 'ART',
        name: "Painting",
        description: "A painting",
        value_usd: 50,
        legal_doc_uri: "ipfs://painting",
        image_uri: "ipfs://painting-image",
        location: "Gallery",
        created_at: 100,
    };

    let precious_metal = AssetData {
        asset_type: 'PRECIOUS_METAL',
        name: "Gold Bar",
        description: "1kg gold bar",
        value_usd: 300,
        legal_doc_uri: "ipfs://gold",
        image_uri: "ipfs://gold-image",
        location: "Vault",
        created_at: 100,
    };

    assert(real_estate.asset_type == 'REAL_ESTATE', 'Real estate type should match');
    assert(art.asset_type == 'ART', 'Art type should match');
    assert(precious_metal.asset_type == 'PRECIOUS_METAL', 'Precious metal should match');
    assert(real_estate.value_usd == 200, 'Real estate value should be 200');
    assert(art.value_usd == 50, 'Art value should be 50');
    assert(precious_metal.value_usd == 300, 'Precious value should be 300');
}

#[test]
fn test_token_id_operations() {
    let token_id_1 = 0_u256;
    let token_id_2 = 1_u256;
    let token_id_3 = 2_u256;

    assert(token_id_1 == 0_u256, 'Token ID 1 should be 0');
    assert(token_id_2 == 1_u256, 'Token ID 2 should be 1');
    assert(token_id_3 == 2_u256, 'Token ID 3 should be 2');

    let next_token_id = token_id_1 + 1_u256;
    assert(next_token_id == 1_u256, 'Next token ID should be 1');

    let total_assets = token_id_3 + 1_u256;
    assert(total_assets == 3_u256, 'Total assets should be 3');
}
