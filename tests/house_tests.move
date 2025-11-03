#[test_only]
module coin_flip::house_tests {

    use sui::{
        sui::SUI,
        test_utils::{destroy, assert_eq},
        test_scenario::{Self as ts, Scenario},
        coin::{mint_for_testing, burn_for_testing, Coin},
    };
    use coin_flip::{
        admin,
        house::{Self, House},
        set_up_tests::set_up_admins,
        access_control::{Self, Admin, AccessControl}
    };

    const OWNER: address = @0xBABE;
    const FEE_RATE: u128 = 5_000;
    const MIN_AMOUNT: u64 = 10;
    const MAX_AMOUNT: u64 = 100;
    const POOL_VALUE: u64 = 1000;

    public struct World {
        admin: Admin,
        access_control: AccessControl,
        scenario: Scenario,
    }

    #[test]
    fun test_end_to_end() {
        let mut world = start();

        let mut house = new_house(&mut world);

        assert_eq(house.fee_rate(), FEE_RATE);
        assert_eq(house.min_amount(), MIN_AMOUNT);
        assert_eq(house.max_amount(), MAX_AMOUNT);
        assert_eq(house.pool_value(), POOL_VALUE);
        assert_eq(house.treasury_mut().value(), 0);

        let admin = &world.admin;
        let access_control = &world.access_control;

        let additional_pool_value = 333;
        let additional_treasury_value = 444;

        house.update_fee(access_control, admin, 3333);
        house.update_min_amount(access_control, admin, 0);
        house.update_max_amount(access_control, admin, 7777);
        house.pool_mut().join(mint_for_testing(additional_pool_value, world.scenario.ctx()).into_balance());
        house.treasury_mut().join(mint_for_testing(additional_treasury_value, world.scenario.ctx()).into_balance());

        assert_eq(house.fee_rate(), 3333);
        assert_eq(house.min_amount(), 0);
        assert_eq(house.max_amount(), 7777);
        assert_eq(house.pool_value(), POOL_VALUE + additional_pool_value);
        assert_eq(house.treasury_mut().value(), additional_treasury_value);

        assert_eq(
            burn_for_testing(
                house.treasury_withdraw(access_control, admin, 33, world.scenario.ctx())),
            33
        );

        assert_eq(
            burn_for_testing(
                house.pool_withdraw(access_control, admin, 44, world.scenario.ctx())),
            44
        );

        assert_eq(house.pool_value(), POOL_VALUE + additional_pool_value - 44);
        assert_eq(house.treasury_mut().value(), additional_treasury_value - 33);

        house.pool_withdraw_and_transfer(access_control, admin, POOL_VALUE + additional_pool_value - 44, OWNER, world.scenario.ctx());

        house.treasury_withdraw_and_transfer(access_control, admin, additional_treasury_value - 33, OWNER, world.scenario.ctx());

        world.scenario.next_tx(OWNER);

        let pool_coin = world.scenario.take_from_sender<Coin<SUI>>();
        let treasury_coin = world.scenario.take_from_sender<Coin<SUI>>();

        assert_eq(burn_for_testing(treasury_coin), POOL_VALUE + additional_pool_value - 44);
        assert_eq(burn_for_testing(pool_coin), additional_treasury_value - 33);

        house.destroy(access_control, admin);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_new_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let house = house::new<SUI>(
            &access_control,
            &admin,
            mint_for_testing(1000, world.scenario.ctx()),
            FEE_RATE, // 0.5%
            MIN_AMOUNT,
            MAX_AMOUNT,
            world.scenario.ctx()
        );

        destroy(admin);
        destroy(house);
        destroy(access_control);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_update_fee_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        house.update_fee(&access_control, &admin, 1);

        destroy(admin);
        destroy(house);
        destroy(access_control);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_update_min_amount_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        house.update_min_amount(&access_control, &admin, 1);

        destroy(admin);
        destroy(house);
        destroy(access_control);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_update_max_amount_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        house.update_max_amount(&access_control, &admin, 1);

        destroy(admin);
        destroy(house);
        destroy(access_control);
        world.end();
    }

   #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_destroy_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let house = new_house(&mut world);

        house.destroy(&access_control, &admin);

        destroy(admin);
        destroy(access_control);
        world.end();
    }

   #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_pool_withdraw_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        destroy(house.pool_withdraw(&access_control, &admin, 11, world.scenario.ctx()));

        destroy(house);
        destroy(admin);
        destroy(access_control);
        world.end();
    }

   #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_treasury_withdraw_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        destroy(house.treasury_withdraw(&access_control, &admin, 11, world.scenario.ctx()));

        destroy(house);
        destroy(admin);
        destroy(access_control);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_pool_withdraw_and_transfer_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        house.pool_withdraw_and_transfer(&access_control, &admin, 11, @0x0, world.scenario.ctx());

        destroy(house);
        destroy(admin);
        destroy(access_control);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_treasury_withdraw_and_transfer_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut house = new_house(&mut world);

        house.treasury_withdraw_and_transfer(&access_control, &admin, 11, @0x0, world.scenario.ctx());

        destroy(house);
        destroy(admin);
        destroy(access_control);
        world.end();
    }

    fun new_house(world: &mut World): House<SUI> {
        house::new(
            &world.access_control,
            &world.admin,
            mint_for_testing(1000, world.scenario.ctx()),
            FEE_RATE, // 0.5%
            MIN_AMOUNT,
            MAX_AMOUNT,
            world.scenario.ctx()
        )
    }

    fun start(): World {
        let mut scenario = ts::begin(OWNER);

        let (access_control, admin) = set_up_admins(&mut scenario);

        World {
            admin,
            access_control,
            scenario
        }
    }

    fun end(world: World) {
        destroy(world);
    }
}