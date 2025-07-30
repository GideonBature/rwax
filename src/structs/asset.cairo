#[derive(Drop, Serde, starknet::Store, Clone)]
pub struct AssetData {
    pub asset_type: felt252, // "REAL_ESTATE", "PRECIOUS_METAL", "ART", etc.
    pub name: ByteArray,
    pub description: ByteArray,
    pub value_usd: u256,
    pub legal_doc_uri: ByteArray, // IPFS hash for legal documents
    pub image_uri: ByteArray,
    pub location: ByteArray,
    pub created_at: u64,
}
