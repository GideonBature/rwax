use starknet::ContractAddress;

#[derive(Drop, starknet::Event)]
pub struct ListingCreated {
    #[key]
    pub listing_id: u128,
    #[key]
    pub seller: ContractAddress,
    #[key]
    pub token_address: ContractAddress,
    pub amount: u256,
    pub price_per_unit: u256,
}

#[derive(Drop, starknet::Event)]
pub struct ListingCancelled {
    #[key]
    pub listing_id: u128,
    #[key]
    pub seller: ContractAddress,
}

#[derive(Drop, starknet::Event)]
pub struct ListingPriceUpdated {
    #[key]
    pub listing_id: u128,
    pub old_price: u256,
    pub new_price: u256,
}

#[derive(Drop, starknet::Event)]
pub struct TokensPurchased {
    #[key]
    pub listing_id: u128,
    #[key]
    pub buyer: ContractAddress,
    #[key]
    pub seller: ContractAddress,
    pub token_address: ContractAddress,
    pub amount: u256,
    pub total_price: u256,
    pub marketplace_fee: u256,
}

#[derive(Drop, starknet::Event)]
pub struct OfferMade {
    #[key]
    pub offer_id: u128,
    #[key]
    pub offerer: ContractAddress,
    #[key]
    pub token_address: ContractAddress,
    pub amount: u256,
    pub price_per_unit: u256,
    pub expiry: u64,
}
