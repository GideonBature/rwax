use core::byte_array::ByteArray;
use core::result::ResultTrait;
use rwax::interfaces::irwa_factory::{IRWAFactoryDispatcher, IRWAFactoryDispatcherTrait};
use rwax::structs::asset::AssetData;
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, declare, start_cheat_caller_address,
    stop_cheat_caller_address,
};
use starknet::{ContractAddress, contract_address_const};

// Test constants
fn ADMIN() -> ContractAddress {
    contract_address_const::<0x123>()
}

fn TOKENIZER() -> ContractAddress {
    contract_address_const::<0x456>()
}

fn OWNER() -> ContractAddress {
    contract_address_const::<0x789>()
}

// Deploy contract function
fn deploy_contract() -> (IRWAFactoryDispatcher, ContractAddress) {
    let admin = ADMIN();

    // Prepare constructor arguments
    let mut calldata = array![];
    let name: ByteArray = "RWAFactory";
    let symbol: ByteArray = "RWA";
    let base_uri: ByteArray = "https://api.example.com/metadata/";
    let fractionalization_module = contract_address_const::<0xabc>();
    name.serialize(ref calldata);
    symbol.serialize(ref calldata);
    base_uri.serialize(ref calldata);
    admin.serialize(ref calldata);
    fractionalization_module.serialize(ref calldata);

    let declare_result = declare("RWAFactory").expect('Failed to declare contract');
    let contract_class = declare_result.contract_class();
    let (contract_address, _) = contract_class
        .deploy(@calldata)
        .expect('Failed to deploy contract');

    let dispatcher = IRWAFactoryDispatcher { contract_address };
    (dispatcher, contract_address)
}

// Helper function to grant tokenizer role
fn grant_tokenizer_role_helper(contract_instance: IRWAFactoryDispatcher, contract_address: ContractAddress, account: ContractAddress) {
    let admin = ADMIN();
    start_cheat_caller_address(contract_address, admin);
    contract_instance.grant_tokenizer_role(account);
    stop_cheat_caller_address(contract_address);
}

// Test get_asset_data after successful tokenization
#[test]
fn test_get_asset_data_after_tokenization() {
    let (contract_instance, contract_address) = deploy_contract();
    let tokenizer = TOKENIZER();
    let owner = OWNER();

    // Grant tokenizer role
    grant_tokenizer_role_helper(contract_instance, contract_address, tokenizer);

    let asset_data = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "Test Villa",
        description: "Beautiful test villa",
        value_usd: 1000000,
        legal_doc_uri: "ipfs://test-villa-legal",
        image_uri: "ipfs://test-villa-image",
        location: "Test Beach",
        created_at: 1640995200,
    };

    // Tokenize the asset
    start_cheat_caller_address(contract_address, tokenizer);
    let token_id = contract_instance.tokenize_asset(owner, asset_data);
    stop_cheat_caller_address(contract_address);

    // Test get_asset_data returns the correct data
    let retrieved_data = contract_instance.get_asset_data(token_id);

    assert(retrieved_data.asset_type == 'REAL_ESTATE', 'Asset type should match');
    assert(retrieved_data.name == "Test Villa", 'Name should match');
    assert(retrieved_data.description == "Beautiful test villa", 'Description should match');
    assert(retrieved_data.value_usd == 1000000, 'Value should match');
    assert(retrieved_data.legal_doc_uri == "ipfs://test-villa-legal", 'Legal doc URI should match');
    assert(retrieved_data.image_uri == "ipfs://test-villa-image", 'Image URI should match');
    assert(retrieved_data.location == "Test Beach", 'Location should match');
    assert(retrieved_data.created_at == 1640995200, 'Created at should match');
}

// Test get_asset_data with multiple tokenized assets
#[test]
fn test_get_asset_data_multiple_tokens() {
    let (contract_instance, contract_address) = deploy_contract();
    let tokenizer = TOKENIZER();
    let owner = OWNER();

    // Grant tokenizer role
    grant_tokenizer_role_helper(contract_instance, contract_address, tokenizer);

    let real_estate_data = AssetData {
        asset_type: 'REAL_ESTATE',
        name: "Villa Alpha",
        description: "First villa",
        value_usd: 800000,
        legal_doc_uri: "ipfs://villa-alpha-legal",
        image_uri: "ipfs://villa-alpha-image",
        location: "Alpha Beach",
        created_at: 1640995100,
    };

    let art_data = AssetData {
        asset_type: 'ART',
        name: "Modern Sculpture",
        description: "Contemporary art piece",
        value_usd: 150000,
        legal_doc_uri: "ipfs://sculpture-legal",
        image_uri: "ipfs://sculpture-image",
        location: "Gallery",
        created_at: 1640995200,
    };

    // Tokenize both assets
    start_cheat_caller_address(contract_address, tokenizer);
    let token_id_1 = contract_instance.tokenize_asset(owner, real_estate_data);
    let token_id_2 = contract_instance.tokenize_asset(owner, art_data);
    stop_cheat_caller_address(contract_address);

    // Test get_asset_data for first token
    let retrieved_data_1 = contract_instance.get_asset_data(token_id_1);
    assert(retrieved_data_1.asset_type == 'REAL_ESTATE', 'First asset type match');
    assert(retrieved_data_1.name == "Villa Alpha", 'First asset name match');
    assert(retrieved_data_1.value_usd == 800000, 'First asset value match');

    // Test get_asset_data for second token
    let retrieved_data_2 = contract_instance.get_asset_data(token_id_2);
    assert(retrieved_data_2.asset_type == 'ART', 'Second asset type match');
    assert(retrieved_data_2.name == "Modern Sculpture", 'Second asset name match');
    assert(retrieved_data_2.value_usd == 150000, 'Second asset value match');

    // Verify tokens have different IDs and data
    assert(token_id_1 != token_id_2, 'Token IDs should be different');
    assert(retrieved_data_1.asset_type != retrieved_data_2.asset_type, 'Asset types different');
}

// Test get_asset_data with nonexistent token (should return default/empty AssetData)
#[test]
fn test_get_asset_data_nonexistent_token() {
    let (contract_instance, _) = deploy_contract();

    // Try to get data for a token that doesn't exist
    let nonexistent_token_id = 999_u256;
    let retrieved_data = contract_instance.get_asset_data(nonexistent_token_id);

    // Should return default/empty AssetData values since the token was never stored
    assert(retrieved_data.asset_type == 0, 'Non-existent token type 0');
    assert(retrieved_data.name == "", 'Non-existent name empty');
    assert(retrieved_data.description == "", 'Non-existent description empty');
    assert(retrieved_data.value_usd == 0, 'Non-existent value 0');
    assert(retrieved_data.legal_doc_uri == "", 'Non-existent legal doc empty');
    assert(retrieved_data.image_uri == "", 'Non-existent image uri empty');
    assert(retrieved_data.location == "", 'Non-existent location empty');
    assert(retrieved_data.created_at == 0, 'Non-existent created_at 0');
}
