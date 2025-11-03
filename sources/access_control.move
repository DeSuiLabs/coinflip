/*
 * @title Access Control
 *
 * @description from Suitears💧 https://github.com/interest-protocol/suitears/blob/main/contracts/sources/capabilities/access_control.move
 */
module coin_flip::access_control;
// === Imports ===

use sui::{  
    vec_map::{Self, VecMap},
    vec_set::{Self, VecSet}
};

use coin_flip::constants;

// === Errors ===

#[error]
const EInvalidAccessControlAddress: vector<u8> = b"The Admin does not belong to the Access Control";
#[error]
const EMustBeASuperAdmin: vector<u8> = b"The Admin does not have the SUPER_ADMIN_ROLE";
#[error]
const ERoleDoesNotExist: vector<u8> = b"The Admin does not have this role";

// === Structs ===

public struct AccessControl has key, store {
    id: UID,
    /// Map to store a role => set of addresses with said role.
    roles: VecMap<vector<u8>, VecSet<address>>
}

public struct Admin has key, store {
    id: UID,
    /// Address of the {AccessControl} this capability belongs to.
    access_control: address
}

// === Public-Mutative Functions ===

public fun new_admin(self: &AccessControl, ctx: &mut TxContext): Admin {
    Admin {id: object::new(ctx), access_control: self.id.to_address()}
}

public fun add(admin: &Admin, self: &mut AccessControl, role: vector<u8>) {
    assert_super_admin(admin, self);

    if (!self.contains(role)) {
        new_role_impl(self, role);
    }
}

public fun remove(admin: &Admin, self: &mut AccessControl, role: vector<u8>) {
    assert_super_admin(admin, self);

    if (self.contains(role)) {
        self.roles.remove(&role);
    }
}

public fun grant(
    admin: &Admin,
    self: &mut AccessControl,
    role: vector<u8>,
    new_admin: address,
) {
    assert_super_admin(admin, self);

    if (self.contains(role)) {
        (&mut self.roles[&role]).insert(new_admin)
    } else {
        new_role_singleton_impl(self, role, new_admin);
    }
}

public fun revoke(
    admin: &Admin,
    self: &mut AccessControl,
    role: vector<u8>,
    old_admin: address,
) {
    assert_super_admin(admin, self);
    assert!(self.contains(role), ERoleDoesNotExist);

    if (has_role_(old_admin, self, role)) {
        (&mut self.roles[&role]).remove(&old_admin);
    }
}

public fun renounce(admin: &Admin, self: &mut AccessControl, role: vector<u8>) {
    assert!(self.id.to_address() == admin.access_control, EInvalidAccessControlAddress);

    let old_admin = admin.id.to_address();

    if (has_role_(old_admin, self, role)) {
        (&mut self.roles[&role]).remove(&old_admin);
    }
}

public fun destroy(admin: &Admin, self: AccessControl) {
    assert_super_admin(admin, &self);

    let AccessControl { id, roles: _ } = self;

    id.delete()
}


public fun destroy_empty(self: AccessControl) {
    let AccessControl { id, roles } = self;

    roles.destroy_empty();
    id.delete()
}

public fun destroy_account(admin: Admin) {
    let Admin { id, access_control: _ } = admin;
    id.delete()
}

// === Public-Package Functions ===

public(package) fun new(ctx: &mut TxContext): (AccessControl, Admin) {
    let mut access_control = AccessControl {id: object::new(ctx), roles: vec_map::empty()};

    let super_admin = new_admin(&access_control, ctx);

    new_role_singleton_impl(&mut access_control, constants::super_admin_role(), super_admin.id.to_address());

    (access_control, super_admin)
}

// === Public-View Functions ===

public fun addy(admin: &Admin): address {
    admin.id.uid_to_address()
}

public fun access_control(admin: &Admin): address {
    admin.access_control
}

public fun contains(self: &AccessControl, role: vector<u8>): bool {
    self.roles.contains(&role)
}

public fun admin_has_role(admin: &Admin, self: &AccessControl, role: vector<u8>): bool {
    self.roles.contains(&role) && self.roles[&role].contains(&admin.id.uid_to_address())
}

public fun has_role_(admin_address: address, self: &AccessControl, role: vector<u8>): bool {
    self.roles.contains(&role) && self.roles[&role].contains(&admin_address)
}

public fun has_role(admin: &Admin, self: &AccessControl, role: vector<u8>): bool {
    assert!(self.id.to_address() == admin.access_control, EInvalidAccessControlAddress);

    has_role_(admin.id.to_address(), self, role)
}

// === Private Functions ===

fun assert_super_admin(admin: &Admin, self: &AccessControl) {
    assert!(has_role(admin, self, constants::super_admin_role()), EMustBeASuperAdmin);
}

fun new_role_impl(self: &mut AccessControl, role: vector<u8>) {
    self.roles.insert(role, vec_set::empty());
}

fun new_role_singleton_impl(self: &mut AccessControl, role: vector<u8>, recipient: address) {
    self.roles.insert(role, vec_set::singleton(recipient));
}
