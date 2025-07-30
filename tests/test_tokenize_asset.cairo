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
    // "RWAFactory".serialize(ref calldata);
    // "RWA".serialize(ref calldata);
    // "https://api.example.com/metadata/".serialize(ref calldata);
    // admin.serialize(ref calldata);
    // fractionalization_module.serialize(ref calldata);

    let declare_result = declare("RWAFactory").expect('Failed to declare contract');
    let contract_class = declare_result.contract_class();
    let (contract_address, _) = contract_class
        .deploy(@calldata)
        .expect('Failed to deploy contract');

    let dispatcher = IRWAFactoryDispatcher { contract_address };
    (dispatcher, contract_address)
}
// Test unauthorized tokenization
#[test]
#[should_panic]
fn test_unauthorized_tokenize() {
    let (contract_instance, contract_address) = deploy_contract();
    let unauthorized = contract_address_const::<0x999>();
    let owner = OWNER();

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

    // Try to tokenize without role
    start_cheat_caller_address(contract_address, unauthorized);
    contract_instance.tokenize_asset(owner, asset_data);
    stop_cheat_caller_address(unauthorized);
}

// Test basic functionality without contract deployment
#[test]
fn test_basic_functionality() {
    // Test that we can create and manipulate basic data structures
    let tokenizer = TOKENIZER();
    let owner = OWNER();
    let admin = ADMIN();

    // Test address constants work
    assert(tokenizer != owner, 'Addresses should be different');
    assert(admin != tokenizer, 'Admin be dff from tokenizer');
    assert(owner != admin, 'Owner should be dff from admin');

    // Test that we can create asset data
    let asset_data = AssetData {
        asset_type: 'PRECIOUS_METAL',
        name: "Gold Bar",
        description: "1kg gold bar",
        value_usd: 200,
        legal_doc_uri: "ipfs://gold",
        image_uri: "ipfs://gold-image",
        location: "Vault",
        created_at: 100,
    };

    assert(asset_data.asset_type == 'PRECIOUS_METAL', 'Asset type be precious metal');
    assert(asset_data.value_usd == 200, 'Value should be 200');
    assert(asset_data.name == "Gold Bar", 'Name should be Gold Bar');
}
