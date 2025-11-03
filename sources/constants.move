module coin_flip::constants;
    
// === Constants ===

const MAX_FEE_RATE: u128 = 100_000;
const FEE_PRECISION: u128 = 1_000_000;
const MAX_BETS: u64 = 1000;
const SUPER_ADMIN_ROLE: vector<u8> = b"SUPER_ADMIN_ROLE";

// === Public-Package Functions ===

public(package) fun super_admin_role(): vector<u8> {
    SUPER_ADMIN_ROLE
}

public(package) fun max_fee_rate(): u128 {
    MAX_FEE_RATE
}

public(package) fun fee_precision(): u128 {
    FEE_PRECISION
}

public(package) fun max_bets(): u64 {
    MAX_BETS
}