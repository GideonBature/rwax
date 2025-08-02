use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;
use openzeppelin::access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use rwax::contracts::rwa_factory::RWAFactory;
use rwax::events::factory::TokenizerRoleGranted;
use rwax::interfaces::irwa_factory::{IRWAFactoryDispatcher, IRWAFactoryDispatcherTrait};
use snforge_std::{
    ContractClassTrait, DeclareResultTrait, EventSpyAssertionsTrait, declare, spy_events,
    start_cheat_caller_address, stop_cheat_caller_address,
};
use starknet::ContractAddress;

const TOKENIZER_ROLE: felt252 = selector!("TOKENIZER_ROLE");

// Test helper functions
fn setup() -> (ContractAddress, IRWAFactoryDispatcher, IAccessControlDispatcher, ContractAddress) {
    let contract = declare("RWAFactory").unwrap().contract_class();

    let admin: ContractAddress = 0x123.try_into().unwrap();
    let fractionalization_module: ContractAddress = 0x456.try_into().unwrap();

    // Create ByteArray strings properly
    let name: ByteArray = "RWA Token";
    let symbol: ByteArray = "RWA";
    let base_uri: ByteArray = "https://api.example.com/";

    let mut constructor_calldata = array![];
    name.serialize(ref constructor_calldata);
    symbol.serialize(ref constructor_calldata);
    base_uri.serialize(ref constructor_calldata);
    constructor_calldata.append(admin.into());
    constructor_calldata.append(fractionalization_module.into());

    let (contract_address, _) = contract.deploy(@constructor_calldata).unwrap();

    let rwa_factory = IRWAFactoryDispatcher { contract_address };
    let access_control = IAccessControlDispatcher { contract_address };

    (contract_address, rwa_factory, access_control, admin)
}

#[test]
fn test_grant_tokenizer_role_success() {
    let (contract_address, rwa_factory, access_control, admin) = setup();
    let new_tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Set up event spy
    let mut spy = spy_events();

    // Admin grants tokenizer role
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.grant_tokenizer_role(new_tokenizer);
    stop_cheat_caller_address(contract_address);

    // Verify the role was granted
    assert(access_control.has_role(TOKENIZER_ROLE, new_tokenizer), 'Role not granted');

    // Verify event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    RWAFactory::Event::TokenizerRoleGranted(
                        TokenizerRoleGranted { account: new_tokenizer, granter: admin },
                    ),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: 'Caller is missing role')]
fn test_grant_tokenizer_role_non_admin_fails() {
    let (contract_address, rwa_factory, _, _admin) = setup();
    let non_admin: ContractAddress = 0x999.try_into().unwrap();
    let new_tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Non-admin tries to grant tokenizer role (should fail)
    start_cheat_caller_address(contract_address, non_admin);
    rwa_factory.grant_tokenizer_role(new_tokenizer);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_has_tokenizer_role_after_grant() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let new_tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Initially, new_tokenizer should not have the role
    assert(!rwa_factory.has_tokenizer_role(new_tokenizer), 'Should not have role initially');

    // Admin grants tokenizer role
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.grant_tokenizer_role(new_tokenizer);
    stop_cheat_caller_address(contract_address);

    // Now new_tokenizer should have the role
    assert(rwa_factory.has_tokenizer_role(new_tokenizer), 'Should have role after grant');
}

#[test]
fn test_multiple_tokenizer_roles() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let tokenizer1: ContractAddress = 0x111.try_into().unwrap();
    let tokenizer2: ContractAddress = 0x222.try_into().unwrap();

    start_cheat_caller_address(contract_address, admin);

    // Grant roles to multiple accounts
    rwa_factory.grant_tokenizer_role(tokenizer1);
    rwa_factory.grant_tokenizer_role(tokenizer2);

    stop_cheat_caller_address(contract_address);

    // Both should have the role
    assert(rwa_factory.has_tokenizer_role(tokenizer1), 'Tokenizer1 should have role');
    assert(rwa_factory.has_tokenizer_role(tokenizer2), 'Tokenizer2 should have role');

    // Admin should still have the role (granted in constructor)
    assert(rwa_factory.has_tokenizer_role(admin), 'Admin should still have role');
}


#[test]
fn test_admin_role_check() {
    let (_contract_address, _, access_control, admin) = setup();

    // Admin should have DEFAULT_ADMIN_ROLE
    assert(access_control.has_role(DEFAULT_ADMIN_ROLE, admin), 'Admin shudhv DEFAULT_ADMIN_ROLE');

    // Admin should also have TOKENIZER_ROLE (granted in constructor)
    assert(access_control.has_role(TOKENIZER_ROLE, admin), 'Admin shud have TOKENIZER_ROLE');
}

#[test]
fn test_grant_role_to_same_account_twice() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let tokenizer: ContractAddress = 0x789.try_into().unwrap();

    start_cheat_caller_address(contract_address, admin);

    // Grant role first time
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert(rwa_factory.has_tokenizer_role(tokenizer), 'Should hav role afte 1st grant');

    // Grant role second time (should not fail)
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert(rwa_factory.has_tokenizer_role(tokenizer), 'Shud hv role afte 2nd grant');

    stop_cheat_caller_address(contract_address);
}
