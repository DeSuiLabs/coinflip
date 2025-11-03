module coin_flip::house;
// === Imports ===

use sui::{
    coin::Coin,
    balance::{Self, Balance}
};

use coin_flip::{
    events,
    constants,
    admin::assert_is_authorized,
    access_control::{AccessControl, Admin}
};

// === Errors ===

#[error] 
const FeeRateIsTooHigh: vector<u8> = b"The max fee rate is 10_000";
#[error] 
const HouseMustHaveNoBalance: vector<u8> = b"Please remove all the balance from the house";
#[error] 
const AmountIsTooHigh: vector<u8> = b"The amount exceeds the balance";

// === Structs ===

public struct House<phantom T> has key {
    id: UID,
    fee_rate: u128,
    min_amount: u64,
    max_amount: u64,
    pool: Balance<T>,
    treasury: Balance<T>
}

// === Public-Mutative Functions ===

#[allow(lint(share_owned))]
public fun share<T>(self: House<T>) {
    transfer::share_object(self);
}

public fun add<T>(
    self: &mut House<T>,
    coin_in: Coin<T>
): u64 { 
    self.pool.join(coin_in.into_balance())
}  

// === Public-View Functions ===

// === Public-Package View Functions ===

public(package) fun fee_rate<T>(self: &House<T>): u128 {
    self.fee_rate
}

public(package) fun max_amount<T>(self: &House<T>): u64 {
    self.max_amount
}

public(package) fun min_amount<T>(self: &House<T>): u64 {
    self.min_amount
}

public(package) fun pool_value<T>(self: &House<T>): u64 {
    self.pool.value()
}

public(package) fun pool_mut<T>(self: &mut House<T>): &mut Balance<T> {
    &mut self.pool
}

public(package) fun treasury_mut<T>(self: &mut House<T>): &mut Balance<T> {
    &mut self.treasury
}

// === Admin Functions ===

public fun new<T>(
    access_control: &AccessControl,
    admin: &Admin,
    coin_in: Coin<T>,
    fee_rate: u128,
    min_amount: u64,
    max_amount: u64,
    ctx: &mut TxContext
): House<T> { 
    assert_is_authorized(access_control, admin);
    assert!(constants::max_fee_rate() >= fee_rate, FeeRateIsTooHigh);

    House {
        id: object::new(ctx),
        fee_rate,
        min_amount,
        max_amount,
        pool: coin_in.into_balance(),
        treasury: balance::zero()
    }
}   

public fun update_fee<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin,
    fee_rate: u128,
) { 
    assert_is_authorized(access_control, admin);
    assert!(constants::max_fee_rate() >= fee_rate, FeeRateIsTooHigh);

    self.fee_rate = fee_rate;

    events::emit_update_house<T>(
        self.min_amount, 
        self.max_amount, 
        self.fee_rate
    );
} 

public fun update_max_amount<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin,
    max_amount: u64,
) { 
    assert_is_authorized(access_control, admin);

    self.max_amount = max_amount;

    events::emit_update_house<T>(
        self.min_amount, 
        self.max_amount, 
        self.fee_rate
    );
} 

public fun update_min_amount<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin,
    min_amount: u64,
) { 
    assert_is_authorized(access_control, admin);

    self.min_amount = min_amount;

    events::emit_update_house<T>(
        self.min_amount, 
        self.max_amount, 
        self.fee_rate
    );
} 

public fun destroy<T>(
    self: House<T>,
    access_control: &AccessControl,
    admin: &Admin,
) {
    assert_is_authorized(access_control, admin);

    let House { id, pool, treasury, .. } = self;

    id.delete();
    assert!(pool.value() == 0 && treasury.value() == 0, HouseMustHaveNoBalance);

    pool.destroy_zero();
    treasury.destroy_zero();
}

public fun pool_withdraw<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin, 
    amount: u64,
    ctx: &mut TxContext
): Coin<T> {
    assert_is_authorized(access_control, admin);
    assert!(self.pool.value() >= amount, AmountIsTooHigh);
    
    events::emit_pool_withdraw<T>(
        amount
    );

    self.pool.split(amount).into_coin(ctx)
}

public fun treasury_withdraw<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin, 
    amount: u64,
    ctx: &mut TxContext
): Coin<T> {
    assert_is_authorized(access_control, admin);
    assert!(self.treasury.value() >= amount, AmountIsTooHigh);

    events::emit_treasury_withdraw<T>(
        amount
    );

    self.treasury.split(amount).into_coin(ctx)
}

public fun pool_withdraw_and_transfer<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin, 
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    transfer::public_transfer(pool_withdraw(self, access_control, admin, amount, ctx), recipient);
}

public fun treasury_withdraw_and_transfer<T>(
    self: &mut House<T>,
    access_control: &AccessControl,
    admin: &Admin, 
    amount: u64,
    recipient: address,
    ctx: &mut TxContext
) {
    transfer::public_transfer(treasury_withdraw(self, access_control, admin, amount, ctx), recipient);
}