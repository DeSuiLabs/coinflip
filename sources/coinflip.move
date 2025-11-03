module coin_flip::dsl_coin_flip;
// === Imports ===

use std::type_name::{Self, TypeName};

use sui::{
    hash,
    random::Random,
    coin::Coin,
    kiosk::Kiosk,
};
use coin_flip::{
    events,
    constants,
    house::House,
    partnership::Partnership
};

// === Errors ===

#[error]
const EInvalidStakeAmount: vector<u8> = b"The stake amount is not within the house range.";
#[error]
const EPoolBalanceIsLow: vector<u8> = b"The house pool does not have enough balance for this bet.";
#[error]
const ERequiresNoKiosk: vector<u8> = b"This partnership requires no Kiosk";
#[error]
const ERequiresKiosk: vector<u8> = b"This partnership requires a Kiosk";
#[error]
const EItemNotFound: vector<u8> = b"The user must have the partnership item";
#[error]
const EKioskUnauthorized: vector<u8> = b"This sender is not the owner of the kiosk";

// === Public-Mutative Functions ===

entry fun flip<T>(house: &mut House<T>, random: &Random, stake: Coin<T>, bet: bool, ctx: &mut TxContext) {
    let bet_amount = stake.value();
    let fee_rate = house.fee_rate();
    let (won, fee, stake_value) = flip_impl(house, random, stake, bet, fee_rate, ctx);
    events::emit_flip<T>(
        ctx.sender(), 
        won, 
        bet_amount,
        fee, 
        stake_value, 
        bet, 
        option::none()
    );
}

entry fun flip_with_partnership<T>(
    house: &mut House<T>, 
    partnership: &Partnership<T>,
    random: &Random, 
    stake: Coin<T>, 
    bet: bool, 
    ctx: &mut TxContext
) {
    assert!(!partnership.requires_kiosk(), ERequiresNoKiosk);

    let bet_amount = stake.value();
    let fee_rate = min(house.fee_rate(), partnership.fee_rate());
    let (won, fee, stake_value) = flip_impl(house, random, stake, bet, fee_rate, ctx);
    events::emit_flip<T>(
        ctx.sender(), 
        won, 
        bet_amount,
        fee, 
        stake_value, 
        bet, 
        option::some(type_name::get<T>())
    );
}

entry fun flip_with_kiosk<T, K: key + store>(
    house: &mut House<T>, 
    partnership: &Partnership<K>,
    random: &Random, 
    stake: Coin<T>, 
    kiosk: &Kiosk,
    item: ID,
    bet: bool, 
    ctx: &mut TxContext
) {
    assert!(partnership.requires_kiosk(), ERequiresKiosk);
    assert!(kiosk.owner() == ctx.sender(), EKioskUnauthorized);
    assert!(kiosk.has_item_with_type<K>(item), EItemNotFound);

    let bet_amount = stake.value();
    let fee_rate = min(house.fee_rate(), partnership.fee_rate());
    let (won, fee, stake_value) = flip_impl(house, random, stake, bet, fee_rate, ctx);
    events::emit_flip<T>(
        ctx.sender(), 
        won,
        bet_amount,
        fee, 
        stake_value, 
        bet, 
        option::some(type_name::get<K>())
    );
}

entry fun multi_flip<T>(
    house: &mut House<T>,
    random: &Random, 
    stake: Coin<T>, 
    bets: vector<bool>, 
    ctx: &mut TxContext
) {
    let fee_rate = house.fee_rate();
    multi_flip_impl(house, random, stake, bets, fee_rate, option::none(), ctx);
}

entry fun multi_flip_with_partnership<T>(
    house: &mut House<T>,
    partnership: &Partnership<T>,
    random: &Random, 
    stake: Coin<T>, 
    bets: vector<bool>, 
    ctx: &mut TxContext
) {
    assert!(!partnership.requires_kiosk(), ERequiresNoKiosk);

    let fee_rate = min(house.fee_rate(), partnership.fee_rate());
    multi_flip_impl(house, random, stake, bets, fee_rate, option::some(type_name::get<T>()), ctx);
}

entry fun multi_flip_with_kiosk<T, K: key + store>(
    house: &mut House<T>,
    partnership: &Partnership<K>,
    random: &Random, 
    stake: Coin<T>, 
    kiosk: &Kiosk,
    item: ID,
    bets: vector<bool>, 
    ctx: &mut TxContext
) {
    assert!(partnership.requires_kiosk(), ERequiresKiosk);
    assert!(kiosk.owner() == ctx.sender(), EKioskUnauthorized);
    assert!(kiosk.has_item_with_type<K>(item), EItemNotFound);

    let fee_rate = min(house.fee_rate(), partnership.fee_rate());
    multi_flip_impl(house, random, stake, bets, fee_rate, option::some(type_name::get<K>()), ctx);
}

// === Private Functions ===

#[allow(lint(self_transfer))]
fun flip_impl<T>(
    house: &mut House<T>, 
    random: &Random, 
    mut stake: Coin<T>, 
    bet: bool, 
    fee_rate: u128,
    ctx: &mut TxContext
): (bool, u64, u64) {
    validate_flip(house, &stake);

    let mut gen = random.new_generator(ctx);

    let result = gen.generate_bool();

    let won = result == bet;
    let mut stake_value = stake.value();

    stake.join(house.pool_mut().split(stake_value).into_coin(ctx));

    let mut stake_balance = stake.into_balance();

    // Happy path: 1 Resource created {stake_balance => Coin} + higher gas {burn_gas}
    // Unhappy path: No resources created or deleted.
    if (won) {
        // Higher gas
        burn_gas(ctx);

        let fee_amount = compute_fee(stake_balance.value(), fee_rate);

        // No resources created nor deleted (no UID)
        let fee = stake_balance.split(fee_amount);
        house.treasury_mut().join(fee);

        stake_value = stake_balance.value();

        // 1 Resource created {stake}
        transfer::public_transfer(stake_balance.into_coin(ctx), ctx.sender());

        (won, fee_amount, stake_value)
    } else {
        // No resource deleted.
        house.pool_mut().join(stake_balance);
        (won, 0, 0)
    }
}

#[allow(lint(self_transfer))]
fun multi_flip_impl<T>(
    house: &mut House<T>,
    random: &Random, 
    mut stake: Coin<T>, 
    bets: vector<bool>, 
    fee_rate: u128,
    partnership: Option<TypeName>,
    ctx: &mut TxContext
) {
    let num_of_bets = bets.length();
    let bet_amount = stake.value();
    let amount_per_bet = div_down(bet_amount, num_of_bets);

    let mut i = 0;
    let mut total_fees = 0;
    let mut total_payout = 0;
    let mut results = vector[];

    while (num_of_bets > i) {
        let (won, fee, stake_value) = flip_impl(
            house, 
            random, 
            stake.split(amount_per_bet, ctx), 
            bets[i], 
            fee_rate, 
            ctx
        );

        results.push_back(if (won) bets[i] else !bets[i]);
        total_fees = total_fees + fee;
        total_payout = total_payout + stake_value;

        i = i + 1;
    };

    transfer::public_transfer(stake,ctx.sender());

    events::emit_multi_flip<T>(
        ctx.sender(), 
        bet_amount,
        total_fees, 
        total_payout, 
        bets, 
        results,
        partnership
    );    
}

fun validate_flip<T>(house: &House<T>, stake: &Coin<T>) {
    assert!(house.max_amount() >= stake.value() && stake.value() >= house.min_amount(), EInvalidStakeAmount);
    assert!(house.pool_value() >= stake.value(), EPoolBalanceIsLow);
}

fun burn_gas(ctx: &TxContext) {
    hash::blake2b256(ctx.digest());
}

fun compute_fee(amount: u64, fee_rate: u128): u64 {
    (((amount as u128) * fee_rate / constants::fee_precision()) as u64)
}

fun div_down(x: u64, y: u64): u64 {
    x / y
}

fun min(x: u128, y: u128): u128 {
    if (x <= y) { x } else { y }
}