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

fn UNAUTHORIZED() -> ContractAddress {
    contract_address_const::<0x999>()
}

fn APPROVED_OPERATOR() -> ContractAddress {
    contract_address_const::<0xaaa>()
}

fn FRACTIONALIZATION_MODULE() -> ContractAddress {
    contract_address_const::<0xabc>()
}

// Deploy contract function
fn deploy_contract() -> (IRWAFactoryDispatcher, ContractAddress) {
    let admin = ADMIN();
    let fractionalization_module = FRACTIONALIZATION_MODULE();

    // Prepare constructor arguments
    let mut calldata = array![];
    let name: ByteArray = "RWAFactory";
    let symbol: ByteArray = "RWA";
    let base_uri: ByteArray = "https://api.example.com/metadata/";
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

// Helper function to create asset data
fn create_asset_data(
    asset_type: felt252, name: ByteArray, description: ByteArray, value_usd: u256,
) -> AssetData {
    AssetData {
        asset_type,
        name,
        description,
        value_usd,
        legal_doc_uri: "ipfs://test",
        image_uri: "ipfs://test",
        location: "Test Location",
        created_at: 100,
    }
}

// Test successful metadata update by owner
#[test]
fn test_owner_can_update_metadata() {
    let (contract_instance, contract_address) = deploy_contract();
    let admin = ADMIN();
    let tokenizer = TOKENIZER();
    let owner = OWNER();

    // Create initial asset data
    let initial_asset_data = create_asset_data(
        'REAL_ESTATE', "Original Property", "Original description", 100_u256,
    );

    // Tokenize asset
    start_cheat_caller_address(contract_address, admin);
    let token_id = contract_instance.tokenize_asset(owner, initial_asset_data);
    stop_cheat_caller_address(contract_address);

    // Create updated asset data
    let updated_asset_data = create_asset_data(
        'REAL_ESTATE', "Updated Property", "Updated description with more details", 150_u256,
    );

    // Update metadata as owner
    start_cheat_caller_address(contract_address, owner);
    contract_instance.update_asset_metadata(token_id, updated_asset_data);
    stop_cheat_caller_address(contract_address);
    // // Verify the metadata was updated
// let retrieved_data = contract_instance.get_asset_data(token_id);
// assert(retrieved_data.name == "Updated Property", 'Name should be updated');
// assert(retrieved_data.description == "Updated description with more details", 'Description
// should be updated');
// assert(retrieved_data.value_usd == 150_u256, 'Value should be updated');
}

// Test unauthorized metadata update (should panic)
#[test]
#[should_panic(expected: 'Not authorized')]
fn test_unauthorized_update_metadata() {
    let (contract_instance, contract_address) = deploy_contract();
    let admin = ADMIN();
    let owner = OWNER();
    let unauthorized = UNAUTHORIZED();

    // Create initial asset data
    let initial_asset_data = create_asset_data(
        'ART', "Original Art", "Original art description", 50_u256,
    );

    // Tokenize asset
    start_cheat_caller_address(contract_address, admin);
    let token_id = contract_instance.tokenize_asset(owner, initial_asset_data);
    stop_cheat_caller_address(contract_address);

    // Create malicious asset data
    let malicious_asset_data = create_asset_data(
        'ART', "Malicious Update", "This should not be allowed", 999_u256,
    );

    // Try to update metadata as unauthorized user (should panic)
    start_cheat_caller_address(contract_address, unauthorized);
    contract_instance.update_asset_metadata(token_id, malicious_asset_data);
    stop_cheat_caller_address(unauthorized);
}
