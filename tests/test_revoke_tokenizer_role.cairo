use openzeppelin::access::accesscontrol::DEFAULT_ADMIN_ROLE;
use openzeppelin::access::accesscontrol::interface::{
    IAccessControlDispatcher, IAccessControlDispatcherTrait,
};
use rwax::contracts::rwa_factory::RWAFactory;
use rwax::events::factory::TokenizerRoleRevoked;
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
fn test_revoke_tokenizer_role_success() {
    let (contract_address, rwa_factory, access_control, admin) = setup();
    let tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Set up event spy
    let mut spy = spy_events();

    // First grant the role
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert!(rwa_factory.has_tokenizer_role(tokenizer), "Should have role before revoke");

    // Now revoke the role
    rwa_factory.revoke_tokenizer_role(tokenizer);
    stop_cheat_caller_address(contract_address);

    // Verify the role was revoked
    assert!(!access_control.has_role(TOKENIZER_ROLE, tokenizer), "Role not revoked");

    // Verify event was emitted
    spy
        .assert_emitted(
            @array![
                (
                    contract_address,
                    RWAFactory::Event::TokenizerRoleRevoked(
                        TokenizerRoleRevoked { account: tokenizer, revoker: admin },
                    ),
                ),
            ],
        );
}

#[test]
#[should_panic(expected: 'Caller is missing role')]
fn test_revoke_tokenizer_role_non_admin_fails() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let non_admin: ContractAddress = 0x999.try_into().unwrap();
    let tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Admin grants role first
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.grant_tokenizer_role(tokenizer);
    stop_cheat_caller_address(contract_address);

    // Non-admin tries to revoke role (should fail)
    start_cheat_caller_address(contract_address, non_admin);
    rwa_factory.revoke_tokenizer_role(tokenizer);
    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_revoke_role_from_account_without_role() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let non_tokenizer: ContractAddress = 0x789.try_into().unwrap();

    // Verify account doesn't have role initially
    assert!(!rwa_factory.has_tokenizer_role(non_tokenizer), "Shouldn't have role initially");

    // Admin tries to revoke role (should not fail)
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.revoke_tokenizer_role(non_tokenizer);
    stop_cheat_caller_address(contract_address);

    // Still shouldn't have role
    assert!(!rwa_factory.has_tokenizer_role(non_tokenizer), "Should still not have role");
}

#[test]
fn test_admin_can_revoke_own_tokenizer_role() {
    let (contract_address, rwa_factory, _, admin) = setup();

    // Admin has tokenizer role initially
    assert!(rwa_factory.has_tokenizer_role(admin), "Admin should have role initially");

    // Admin revokes their own tokenizer role
    start_cheat_caller_address(contract_address, admin);
    rwa_factory.revoke_tokenizer_role(admin);
    stop_cheat_caller_address(contract_address);

    // Admin should no longer have tokenizer role
    assert!(!rwa_factory.has_tokenizer_role(admin), "Admin should no longer have tokenizer role");

    // But should still have admin role
    let access_control = IAccessControlDispatcher { contract_address };
    assert!(access_control.has_role(DEFAULT_ADMIN_ROLE, admin), "Admin should retain admin role");
}

#[test]
fn test_revoke_then_grant_tokenizer_role() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let tokenizer: ContractAddress = 0x789.try_into().unwrap();

    start_cheat_caller_address(contract_address, admin);

    // Grant role
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert!(rwa_factory.has_tokenizer_role(tokenizer), "Should have role after grant");

    // Revoke role
    rwa_factory.revoke_tokenizer_role(tokenizer);
    assert!(!rwa_factory.has_tokenizer_role(tokenizer), "Should not have role after revoke");

    // Grant again
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert!(rwa_factory.has_tokenizer_role(tokenizer), "Should have role after re-grant");

    stop_cheat_caller_address(contract_address);
}

#[test]
fn test_multiple_revokes() {
    let (contract_address, rwa_factory, _, admin) = setup();
    let tokenizer: ContractAddress = 0x789.try_into().unwrap();

    start_cheat_caller_address(contract_address, admin);

    // Grant role
    rwa_factory.grant_tokenizer_role(tokenizer);
    assert!(rwa_factory.has_tokenizer_role(tokenizer), "Should have role after grant");

    // Revoke first time
    rwa_factory.revoke_tokenizer_role(tokenizer);
    assert!(!rwa_factory.has_tokenizer_role(tokenizer), "Should not have role after first revoke");

    // Revoke second time (should not fail)
    rwa_factory.revoke_tokenizer_role(tokenizer);
    assert!(
        !rwa_factory.has_tokenizer_role(tokenizer),
        "Should still not have role after second revoke",
    );

    stop_cheat_caller_address(contract_address);
}
