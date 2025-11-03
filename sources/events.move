module coin_flip::events;
// === Imports ===

use std::type_name::{Self, TypeName};
use sui::event::emit;

// === Structs ===

public struct Flip has copy, drop, store {
    coin: TypeName,
    player: address,
    player_won: bool,
    payout: u64,
    fee: u64,
    bet: bool,
    bet_amount: u64,
    partnership: Option<TypeName>
}

public struct MultiFlip has copy, drop, store {
    coin: TypeName,
    player: address,
    bet_amount: u64,
    total_fee: u64,
    total_payout: u64,
    player_bets: vector<bool>,
    results: vector<bool>,
    partnership: Option<TypeName>
}

public struct UpdateHouse has copy, drop, store {
    coin: TypeName,
    min_amount: u64,
    max_amount: u64,
    fee_rate: u128,
}

public struct UpdatePartnership has copy, drop, store {
    partnership: TypeName,
    requires_kiosk: bool,
    fee_rate: u128,
}

public struct PoolWithdraw has copy, drop, store {
    coin: TypeName,
    amount: u64,
}

public struct TreasuryWithdraw has copy, drop, store {
    coin: TypeName,
    amount: u64,
}

// === Public-Package Functions ===

public(package) fun emit_flip<T>(
    player: address,
    player_won: bool,
    bet_amount: u64,
    fee: u64,
    payout: u64,
    bet: bool,
    partnership: Option<TypeName>
) {
    emit(Flip {
        player,
        player_won,
        bet_amount,
        fee,
        payout,
        bet,
        coin: type_name::get<T>(),
        partnership
    });
}

public(package) fun emit_multi_flip<T>(
    player: address,
    bet_amount: u64,
    total_fee: u64,
    total_payout: u64,
    player_bets: vector<bool>,
    results: vector<bool>,
    partnership: Option<TypeName>
) {
    emit(MultiFlip {
        player,
        bet_amount,
        total_fee,
        total_payout,
        player_bets,
        results,
        coin: type_name::get<T>(),
        partnership
    });
}

public(package) fun emit_update_house<T>(
    min_amount: u64,
    max_amount: u64,
    fee_rate: u128,
) {
    emit(UpdateHouse {
        coin: type_name::get<T>(),
        min_amount,
        max_amount,
        fee_rate,
    });
}

public(package) fun emit_update_partnership<T>(
    requires_kiosk: bool,
    fee_rate: u128,
) {
    emit(UpdatePartnership {
        partnership: type_name::get<T>(),
        requires_kiosk,
        fee_rate,
    });
}

public(package) fun emit_pool_withdraw<T>(
    amount: u64,
) {
    emit(PoolWithdraw {
        coin: type_name::get<T>(),
        amount,
    });
}

public(package) fun emit_treasury_withdraw<T>(
    amount: u64,
) {
    emit(TreasuryWithdraw {
        coin: type_name::get<T>(),
        amount,
    });
}