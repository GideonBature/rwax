use core::serde::Serde;
use rwax::interfaces::irwa_factory::{IRWAFactoryDispatcher, IRWAFactoryDispatcherTrait};
use snforge_std::{ContractClassTrait, DeclareResultTrait, declare};
use starknet::ContractAddress;

/// Deploy the RWAFactory contract for testing
fn deploy_rwa_factory() -> IRWAFactoryDispatcher {
    let contract = declare("RWAFactory").unwrap().contract_class();

    // Constructor parameters
    let name: ByteArray = "RWA Token";
    let symbol: ByteArray = "RWA";
    let base_uri: ByteArray = "https://api.rwax.com/metadata/";
    let admin: ContractAddress = 0x123.try_into().unwrap();
    let fractionalization_module: ContractAddress = 0x456.try_into().unwrap();

    let mut constructor_calldata = array![];
    name.serialize(ref constructor_calldata);
    symbol.serialize(ref constructor_calldata);
    base_uri.serialize(ref constructor_calldata);
    admin.serialize(ref constructor_calldata);
    fractionalization_module.serialize(ref constructor_calldata);

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();
    IRWAFactoryDispatcher { contract_address }
}

#[test]
fn test_get_total_assets_initial_state() {
    // Test that get_total_assets returns 0 when no assets have been tokenized
    let rwa_factory = deploy_rwa_factory();

    let total_assets = rwa_factory.get_total_assets();

    assert_eq!(total_assets, 0_u256, "Initial total assets should be 0");
}

#[test]
fn test_get_total_assets_function_signature() {
    // Test that the function has the correct signature and return type
    let rwa_factory = deploy_rwa_factory();

    let result: u256 = rwa_factory.get_total_assets();

    assert_eq!(result, 0_u256, "Function should return u256 type with initial value 0");
}
