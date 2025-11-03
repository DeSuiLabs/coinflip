#[test_only]
module coin_flip::partnership_tests {

    use sui::{
        sui::SUI,
        test_utils::{destroy, assert_eq},
        test_scenario::{Self as ts, Scenario},
    };
    use coin_flip::{
        admin,
        partnership::{Self, Partnership},
        set_up_tests::set_up_admins,
        access_control::{Self, Admin, AccessControl}
    };

    const OWNER: address = @0xBABE;
    const FEE_RATE: u128 = 5_000;

    public struct World {
        admin: Admin,
        access_control: AccessControl,
        scenario: Scenario,
    }

    #[test]
    fun test_end_to_end() {
        let mut world = start();

        let mut partnership = new_partnership(&mut world, false);

        assert_eq(partnership.fee_rate(), FEE_RATE);
        assert_eq(partnership.requires_kiosk(), false);

        let admin = &world.admin;
        let access_control = &world.access_control;

        partnership.update(access_control, admin, FEE_RATE + 100);        

        assert_eq(partnership.fee_rate(), FEE_RATE + 100);
        assert_eq(partnership.requires_kiosk(), false);
        
        partnership.destroy(access_control, admin);

        let partnership = new_partnership(&mut world, true);

        assert_eq(partnership.requires_kiosk(), true);

        let admin = &world.admin;
        let access_control = &world.access_control;

        partnership.destroy(access_control, admin);
        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_new_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        destroy(        partnership::new<SUI>(
            &access_control,
            &admin,
            5_000,
            false,
            world.scenario.ctx()
        ));

        destroy(admin);
        destroy(access_control);

        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_update_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let mut partnership = new_partnership(&mut world, false);

        partnership.update(&access_control, &admin, FEE_RATE + 100);    

        destroy(admin);
        destroy(partnership);
        destroy(access_control);

        world.end();
    }

    #[test]
    #[expected_failure(abort_code = admin::EUnauthorizedAdmin)]
    fun test_destroy_error_unauthorized_admin() {
        let mut world = start();

        let (access_control, admin) = access_control::new(world.scenario.ctx());

        let partnership = new_partnership(&mut world, false);

        partnership.destroy(&access_control, &admin);    

        destroy(admin);
        destroy(access_control);

        world.end();
    }

    fun new_partnership(world: &mut World, requires_kiosk: bool): Partnership<SUI> {
        partnership::new(
            &world.access_control,
            &world.admin,
            5_000,
            requires_kiosk,
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