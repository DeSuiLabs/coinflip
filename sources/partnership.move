module coin_flip::partnership;
// === Imports ===

use coin_flip::{
    events,
    constants,
    admin::assert_is_authorized,
    access_control::{AccessControl, Admin}
};

// === Errors ===    

#[error] 
const FeeRateIsTooHigh: vector<u8> = b"The max fee rate is 10_000";

// === Struct ===

public struct Partnership<phantom T> has key {
    id: UID,
    fee_rate: u128,
    requires_kiosk: bool
}

// === Public-Mutative Functions ===

#[allow(lint(share_owned))]
public fun share<T>(self: Partnership<T>) {
    transfer::share_object(self);
}

// === Public-Package View Functions ===

public(package) fun fee_rate<T>(self: &Partnership<T>): u128 {
    self.fee_rate
}

public(package) fun requires_kiosk<T>(self: &Partnership<T>): bool {
    self.requires_kiosk
}

// === Admin Functions ===

public fun new<T>(
    access_control: &AccessControl,
    admin: &Admin,
    fee_rate: u128,
    requires_kiosk: bool,
    ctx: &mut TxContext
): Partnership<T> { 
    assert_is_authorized(access_control, admin);
    assert!(constants::max_fee_rate() >= fee_rate, FeeRateIsTooHigh);

    Partnership {
        id: object::new(ctx),
        fee_rate,
        requires_kiosk
    }
} 

public fun update<T>(
    self: &mut Partnership<T>,
    access_control: &AccessControl,
    admin: &Admin,
    fee_rate: u128,
) { 
    assert_is_authorized(access_control, admin);
    assert!(constants::max_fee_rate() >= fee_rate, FeeRateIsTooHigh);

    self.fee_rate = fee_rate;

    events::emit_update_partnership<T>(
        self.requires_kiosk, 
        self.fee_rate
    );
} 

public fun destroy<T>(
    self: Partnership<T>,
    access_control: &AccessControl,
    admin: &Admin,
) {
    assert_is_authorized(access_control, admin);
    let Partnership { id, .. } = self;
    id.delete();
}