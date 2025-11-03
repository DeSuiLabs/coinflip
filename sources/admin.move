module coin_flip::admin;
// === Imports ===

use coin_flip::access_control::{Self, AccessControl, Admin};
    
// === Constants ===

const TREASURER_ROLE: vector<u8> = b"TREASURER_ROLE";

// === Errors ===
#[error]
const EUnauthorizedAdmin: vector<u8> = b"Admin does not have the TREASURER_ROLE";

// === Init ===

#[allow(lint(share_owned))]
fun init(ctx: &mut TxContext) {
    let (mut access_control, super_admin) = access_control::new(ctx);

    super_admin.add(&mut access_control, TREASURER_ROLE);

    super_admin.grant(&mut access_control, TREASURER_ROLE, super_admin.addy());

    transfer::public_share_object(access_control);
    transfer::public_transfer(super_admin,ctx.sender());
}

// === Public-Package Functions ===

public(package) fun assert_is_authorized(access_control: &AccessControl, admin: &Admin) {
    assert!(admin.has_role(access_control, TREASURER_ROLE), EUnauthorizedAdmin);
}

// === Test Only Functions ===

#[test_only]
public fun init_for_testing(ctx: &mut TxContext) {
    init(ctx);
}