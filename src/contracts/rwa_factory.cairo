use rwax::events::factory::{
    AssetMetadataUpdated, AssetTokenized, TokenizerRoleGranted, TokenizerRoleRevoked,
};
use rwax::interfaces::irwa_factory::IRWAFactory;
use rwax::structs::asset::AssetData;
use starknet::ContractAddress;

const TOKENIZER_ROLE: felt252 = selector!("TOKENIZER_ROLE");

#[starknet::contract]
mod RWAFactory {
    // === Component Mixins ===
    component!(path: ERC721Component, storage: erc721, event: ERC721Event);
    component!(path: SRC5Component, storage: src5, event: SRC5Event);
    component!(path: AccessControlComponent, storage: accesscontrol, event: AccessControlEvent);

    #[abi(embed_v0)]
    impl ERC721MixinImpl = ERC721Component::ERC721MixinImpl<ContractState>;
    impl ERC721InternalImpl = ERC721Component::InternalImpl<ContractState>;

    #[abi(embed_v0)]
    impl AccessControlImpl =
        AccessControlComponent::AccessControlImpl<ContractState>;
    impl AccessControlInternalImpl = AccessControlComponent::InternalImpl<ContractState>;

    // === Storage ===
    #[storage]
    struct Storage {
        #[substorage(v0)]
        erc721: ERC721Component::Storage,
        #[substorage(v0)]
        src5: SRC5Component::Storage,
        #[substorage(v0)]
        accesscontrol: AccessControlComponent::Storage,
        token_counter: u256,
        asset_data: Map<u256, AssetData>,
        fractionalization_module: ContractAddress,
    }

    // === Events ===
    #[event]
    #[derive(Drop, starknet::Event)]
    enum Event {
        #[flat]
        ERC721Event: ERC721Component::Event,
        #[flat]
        SRC5Event: SRC5Component::Event,
        #[flat]
        AccessControlEvent: AccessControlComponent::Event,
        AssetTokenized: AssetTokenized,
        AssetMetadataUpdated: AssetMetadataUpdated,
        TokenizerRoleGranted: TokenizerRoleGranted,
        TokenizerRoleRevoked: TokenizerRoleRevoked,
    }

    // === Constructor Skeleton ===
    #[constructor]
    fn constructor(
        ref self: ContractState,
        name: ByteArray,
        symbol: ByteArray,
        base_uri: ByteArray,
        admin: ContractAddress,
        fractionalization_module: ContractAddress,
    ) {
        // Initialize ERC721
        self.erc721.initializer(name, symbol, base_uri);

        // Initialize SRC5
        self.src5.initializer();

        // Initialize AccessControl with admin
        self.accesscontrol.initializer(admin);

        // Initialize token counter
        self.token_counter.write(0);

        // Store the fractionalization module address
        self.fractionalization_module.write(fractionalization_module);
    }

    // === IRWAFactory Interface Implementation ===
    #[abi(embed_v0)]
    impl RWAFactoryImpl of IRWAFactory<ContractState> {
        fn tokenize_asset(
            ref self: ContractState, owner: ContractAddress, asset_data: AssetData,
        ) -> u256 {
            // Check that caller has TOKENIZER_ROLE
            self.accesscontrol.assert_only_role(TOKENIZER_ROLE);

            // Read and increment token_counter
            let token_id = self.token_counter.read();
            self.token_counter.write(token_id + 1);

            // Store asset_data in the map
            self.asset_data.write(token_id, asset_data);

            // Mint NFT via ERC721
            self.erc721.mint(owner, token_id);

            // Emit AssetTokenized event
            self
                .emit(
                    AssetTokenized {
                        token_id, owner, asset_type: asset_data.asset_type, asset_data,
                    },
                );

            token_id
        }

        fn update_asset_metadata(ref self: ContractState, token_id: u256, new_data: AssetData) {
            // TODO
            unimplemented!();
        }

        fn grant_tokenizer_role(ref self: ContractState, account: ContractAddress) {
            // TODO
            unimplemented!();
        }

        fn revoke_tokenizer_role(ref self: ContractState, account: ContractAddress) {
            // TODO
            unimplemented!();
        }

        fn get_asset_data(self: @ContractState, token_id: u256) -> AssetData {
            self.asset_data.read(token_id)
        }

        fn has_tokenizer_role(self: @ContractState, account: ContractAddress) -> bool {
            self.accesscontrol.has_role(TOKENIZER_ROLE, account)
        }

        fn get_total_assets(self: @ContractState) -> u256 {
            // TODO
            unimplemented!();
        }

        fn get_fractionalization_module(self: @ContractState) -> ContractAddress {
            self.fractionalization_module.read()
        }
    }
}
