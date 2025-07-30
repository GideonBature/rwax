use rwax::structs::asset::AssetData;
use starknet::ContractAddress;

#[starknet::interface]
pub trait IRWAFactory<TContractState> {
    // ===== ASSET TOKENIZATION =====

    /// Creates a new RWA token (ERC721 NFT) representing a real-world asset
    /// Only callable by addresses with TOKENIZER_ROLE
    fn tokenize_asset(
        ref self: TContractState, owner: ContractAddress, asset_data: AssetData,
    ) -> u256;

    /// Updates metadata for an existing asset (only by owner or authorized operator)
    fn update_asset_metadata(ref self: TContractState, token_id: u256, new_data: AssetData);

    // ===== ACCESS CONTROL =====

    /// Grants TOKENIZER_ROLE to an address (only admin)
    fn grant_tokenizer_role(ref self: TContractState, account: ContractAddress);

    /// Revokes TOKENIZER_ROLE from an address (only admin)
    fn revoke_tokenizer_role(ref self: TContractState, account: ContractAddress);

    // ===== VIEW FUNCTIONS =====

    /// Returns asset metadata for a given token ID
    fn get_asset_data(self: @TContractState, token_id: u256) -> AssetData;

    /// Checks if an address has TOKENIZER_ROLE
    fn has_tokenizer_role(self: @TContractState, account: ContractAddress) -> bool;

    /// Returns total number of assets tokenized
    fn get_total_assets(self: @TContractState) -> u256;

    /// Returns the contract address of the fractionalization module
    fn get_fractionalization_module(self: @TContractState) -> ContractAddress;
}
