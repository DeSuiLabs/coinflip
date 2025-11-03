#[test_only]
module coin_flip::coin_flip_tests {
    use sui::{
        sui::SUI,
        random::{Self, Random},
        kiosk::{Self, Kiosk, KioskOwnerCap},
        test_utils::{destroy, assert_eq},
        test_scenario::{Self as ts, Scenario},
        coin::{mint_for_testing, burn_for_testing, Coin},
    };
    use coin_flip::{
        dsl_coin_flip,
        house::{Self, House},
        set_up_tests::set_up_admins,
        partnership::{Self, Partnership},
        access_control::{Admin, AccessControl}
    };

    const OWNER: address = @0x0;
    const FEE_RATE: u128 = 10_000;
    const MIN_AMOUNT: u64 = 10;
    const MAX_AMOUNT: u64 = 1000;
    const POOL_VALUE: u64 = 10000;

    public struct NFT has key, store {
        id: UID
    }

    public struct World {
        admin: Admin,
        access_control: AccessControl,
        kiosk: Kiosk,
        random: Random,
        kiosk_owner_cap: KioskOwnerCap,
        scenario: Scenario,
        house: House<SUI>,
        partnership: Partnership<SUI>,
        nft_partnership: Partnership<NFT>,
        nft_id: ID
    }

    #[test]
    fun test_flip() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let house_mut = &mut world.house;

        // tests are deterministic so we win the first one
        dsl_coin_flip::flip(
            house_mut, 
            random, 
            mint_for_testing(50, world.scenario.ctx()), 
            true, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);
        
        let winnings = world.scenario.take_from_sender<Coin<SUI>>();

        // Pool lost 50
        assert_eq(world.house.pool_value(), POOL_VALUE - 50);
        // Fee is 1%
        assert_eq(world.house.treasury_mut().value(), 1);

        // user got 49 profit
        assert_eq(burn_for_testing(winnings), 99);

        let random = &world.random;
        let house_mut = &mut world.house;

        // tests are deterministic so we lose the second one
        dsl_coin_flip::flip(
            house_mut, 
            random, 
            mint_for_testing(50, world.scenario.ctx()), 
            false, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        // Pool recovered
        assert_eq(world.house.pool_value(), POOL_VALUE);
        // Treasury remains the same cuz the user lost
        assert_eq(world.house.treasury_mut().value(), 1);

        world.end();
    }

    #[test]
    fun test_flip_with_partnerhip() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let partnership = &world.partnership;
        let house_mut = &mut world.house;

        // tests are deterministic so we win the first one
        dsl_coin_flip::flip_with_partnership(
            house_mut, 
            partnership,
            random, 
            mint_for_testing(MAX_AMOUNT, world.scenario.ctx()), 
            true, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);
        
        let winnings = world.scenario.take_from_sender<Coin<SUI>>();

        // Pool lost 50
        assert_eq(world.house.pool_value(), POOL_VALUE - MAX_AMOUNT);
        // Used the partnership fee because it is lower so 0.5% * 2000
        assert_eq(world.house.treasury_mut().value(), 10);

        // user got 49 profit
        assert_eq(burn_for_testing(winnings), MAX_AMOUNT * 2 - 10);

         let random = &world.random;
       let house_mut = &mut world.house;

        // tests are deterministic so we lose the second one. World the same way
        dsl_coin_flip::flip(
            house_mut, 
            random, 
            mint_for_testing(MAX_AMOUNT / 2, world.scenario.ctx()), 
            false, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        // Pool recovered
        assert_eq(world.house.pool_value(), POOL_VALUE - MAX_AMOUNT / 2);
        // Treasury remains the same cuz the user lost
        assert_eq(world.house.treasury_mut().value(), 10);

        world.end();
    }

    #[test]
    fun test_flip_with_kiosk() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let partnership = &world.nft_partnership;
        let kiosk = &world.kiosk;
        let nft_id = world.nft_id;
        let house_mut = &mut world.house;

        // tests are deterministic so we win the first one
        dsl_coin_flip::flip_with_kiosk(
            house_mut, 
            partnership,
            random, 
            mint_for_testing(MAX_AMOUNT, world.scenario.ctx()), 
            kiosk,
            nft_id,
            true, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);
        
        let winnings = world.scenario.take_from_sender<Coin<SUI>>();

        // Pool lost 50
        assert_eq(world.house.pool_value(), POOL_VALUE - MAX_AMOUNT);
        // Used the partnership fee because it is lower so 0.5% * 2000
        assert_eq(world.house.treasury_mut().value(), 10);

        // user got 49 profit
        assert_eq(burn_for_testing(winnings), MAX_AMOUNT * 2 - 10);

         let random = &world.random;
       let house_mut = &mut world.house;

        // tests are deterministic so we lose the second one. World the same way
        dsl_coin_flip::flip(
            house_mut, 
            random, 
            mint_for_testing(MAX_AMOUNT / 2, world.scenario.ctx()), 
            false, 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        // Pool recovered
        assert_eq(world.house.pool_value(), POOL_VALUE - MAX_AMOUNT / 2);
        // Treasury remains the same cuz the user lost
        assert_eq(world.house.treasury_mut().value(), 10);

        world.end();
    }

    #[test]
    fun test_multi_flip() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let house_mut = &mut world.house;

        // tests are deterministic so we win the first one
        dsl_coin_flip::multi_flip(
            house_mut, 
            random, 
            mint_for_testing(50, world.scenario.ctx()), 
            vector[true, true, false, false, false],
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);


        // Pool won 10
        assert_eq(world.house.pool_value() + 10, POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        // user won 3 times
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 0);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 20);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 20);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 20);

        let old_pool_value = world.house.pool_value();

        let random = &world.random;
        let house_mut = &mut world.house;

      // tests are deterministic so we lose this one
        dsl_coin_flip::multi_flip(
            house_mut, 
            random, 
            mint_for_testing(1000, world.scenario.ctx()), 
            vector[true, false, true, false, true], 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        // User won 2x
        assert_eq(world.house.pool_value(), old_pool_value + 200);
        assert_eq(world.house.treasury_mut().value(), 8);

        world.end();
    }

    #[test]
    fun test_multi_flip_with_partnership() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let partnership = &world.partnership;
        let house_mut = &mut world.house;

        dsl_coin_flip::multi_flip_with_partnership(
            house_mut,
            partnership,
            random, 
            mint_for_testing(600, world.scenario.ctx()), 
            vector[true, false, true, true, true, false], 
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 3);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 0);
        // Won 3x
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);

        world.end();
    }

    #[test]
    fun test_multi_flip_tie_with_kiosk() {
        let mut world = start();

        assert_eq(world.house.pool_value(), POOL_VALUE);
        assert_eq(world.house.treasury_mut().value(), 0);

        let random = &world.random;
        let partnership = &world.nft_partnership;
        let kiosk = &world.kiosk;
        let nft_id = world.nft_id;
        let house_mut = &mut world.house;

        dsl_coin_flip::multi_flip_with_kiosk(
            house_mut,
            partnership,
            random, 
            mint_for_testing(600, world.scenario.ctx()), 
            kiosk,
            nft_id,
            vector[false, true, false, false, false, true],
            world.scenario.ctx()
        );

        world.scenario.next_tx(OWNER);

        assert_eq(world.house.pool_value(), POOL_VALUE - 200);
        assert_eq(world.house.treasury_mut().value(), 4);

        // Won 4x
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 0);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);
        assert_eq(burn_for_testing(world.scenario.take_from_sender<Coin<SUI>>()), 199);

        world.end();
    }

    fun start(): World {
        let mut scenario = ts::begin(OWNER);

        let (access_control, admin) = set_up_admins(&mut scenario);

        let (mut kiosk, kiosk_owner_cap) = kiosk::new(scenario.ctx());

        let house = house::new(
            &access_control, 
            &admin, 
            mint_for_testing(POOL_VALUE, scenario.ctx()),
            FEE_RATE,
            MIN_AMOUNT,
            MAX_AMOUNT,
            scenario.ctx()
        );

        let partnership = partnership::new(
            &access_control, 
            &admin, 
            FEE_RATE  / 2,
            false, 
            scenario.ctx()
        );

        let nft_partnership = partnership::new(
            &access_control, 
            &admin, 
            FEE_RATE  / 2,
            true, 
            scenario.ctx()
        );

        let nft = NFT {
            id: object::new(scenario.ctx())
        };

        let nft_id = nft.id.to_inner();

        kiosk.place(&kiosk_owner_cap, nft);

        random::create_for_testing(scenario.ctx());

        scenario.next_tx(OWNER);

        let random = scenario.take_shared<Random>();

        World {
            admin,
            access_control,
            random,
            kiosk,
            kiosk_owner_cap,
            scenario,
            house,
            partnership,
            nft_partnership,
            nft_id
        }
    }

    fun end(world: World) {
        destroy(world);
    }
}