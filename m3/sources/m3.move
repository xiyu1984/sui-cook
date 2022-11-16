module cook_m3::m3 {
    use sui::object::{Self, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::dynamic_object_field;

    const COLOR_RED: u64 = 0;
    public fun red(): u64 {COLOR_RED}
    const COLOR_YELLOW: u64 = 1;
    public fun yellow(): u64 {COLOR_YELLOW}
    const COLOR_BLUE: u64 = 2;
    public fun blue(): u64 {COLOR_BLUE}

    const WATER_INIT: u256 = 100;

    /// Error Defination
    const WATER_Exhausted: u64 = 0;

    struct Ink has key, store {
        id: UID,
        color: u64,
    }

    struct Pallet has key, store {
        id: UID,
        water: u256,
    }


    struct Picture has key, store {
        id: UID,
        mix_size: u64,
        // hidden
        // dynamic object `Ink`
    }

    /// init
    fun init(ctx: &mut TxContext) {
        let pallet = Pallet {
            id: object::new(ctx),
            water: WATER_INIT,
        };

        transfer::share_object(pallet);
    }

    /// creation
    public entry fun mint_ink(color: u64, ctx: &mut TxContext) {
        let ink = Ink {
            id: object::new(ctx),
            color,
        };

        transfer::transfer(ink, tx_context::sender(ctx));
    }

    public entry fun delete_ink(ink: Ink, _: &mut TxContext) {
        let Ink {id, color: _} = ink;
        object::delete(id);
    }

    public entry fun mint_blank_picture(ctx: &mut TxContext) {
        let pic = Picture {
            id: object::new(ctx),
            mix_size: 0,
        };

        transfer::transfer(pic, tx_context::sender(ctx));
    }

    /// operations
    public entry fun draw_picture(pallet: &mut Pallet, picture: &mut Picture, ink: Ink, _: &mut TxContext) {
        assert!(pallet.water > 0, WATER_Exhausted);
        pallet.water = pallet.water - 1;
        // When `dynamic_object_field` mechanism, 
        // the object being added will be wrapped by `0x2::dynamic_field::Field<0x2::dynamic_object_field::Wrapper<u64>, 0x2::object::ID>`
        // And the owner object in application level is only a record, that is, the `picture.id` in this example
        // We can use `sui client object --id <ink object id in this example> --json` to find the id of `0x2::dynamic_object_field::Wrapper<u64>`
        dynamic_object_field::add(&mut picture.id, picture.mix_size, ink);
        picture.mix_size = picture.mix_size + 1;
    }

    #[test]
    public fun shared_pallet_test() {
        use sui::test_scenario;
    
        let alice = @0xACEE;
        let bob = @0xB0B1;

        let scenario_val = test_scenario::begin(alice);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, alice);
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, alice);
        {
            mint_blank_picture(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, bob);
        {
            mint_blank_picture(test_scenario::ctx(scenario));
        };

        // Alice draw picture
        test_scenario::next_tx(scenario, alice);
        {
            let pallet = test_scenario::take_shared<Pallet>(scenario);
            let picture = test_scenario::take_from_sender<Picture>(scenario);
            let ink = Ink {
                id: object::new(test_scenario::ctx(scenario)),
                color: COLOR_RED,
            };

            draw_picture(&mut pallet, &mut picture, ink, test_scenario::ctx(scenario));
            test_scenario::return_shared(pallet);
            test_scenario::return_to_sender(scenario, picture);
        };

        test_scenario::next_tx(scenario, alice);
        {
            let picture = test_scenario::take_from_sender<Picture>(scenario);
            assert!(picture.mix_size == 1, 0);
            assert!(dynamic_object_field::exists_with_type<u64, Ink>(&picture.id, 0), 1);

            test_scenario::return_to_sender(scenario, picture);
        };

        // Bob draw picture
        test_scenario::next_tx(scenario, bob);
        {
            let pallet = test_scenario::take_shared<Pallet>(scenario);
            let picture = test_scenario::take_from_sender<Picture>(scenario);
            let ink = Ink {
                id: object::new(test_scenario::ctx(scenario)),
                color: COLOR_BLUE,
            };

            draw_picture(&mut pallet, &mut picture, ink, test_scenario::ctx(scenario));
            test_scenario::return_shared(pallet);
            test_scenario::return_to_sender(scenario, picture);
        };

        test_scenario::next_tx(scenario, bob);
        {
            let picture = test_scenario::take_from_sender<Picture>(scenario);
            assert!(picture.mix_size == 1, 0);
            assert!(dynamic_object_field::exists_with_type<u64, Ink>(&picture.id, picture.mix_size - 1), 1);

            test_scenario::return_to_sender(scenario, picture);
        };

        // water check
        test_scenario::next_tx(scenario, bob);
        {
            let pallet = test_scenario::take_shared<Pallet>(scenario);
            assert!((WATER_INIT - 2) == pallet.water, 2);
            test_scenario::return_shared(pallet);
        };

        test_scenario::end(scenario_val);
    }
}

// test dependency cycle
// module cook_m3::a {
//     use cook_m3::b;

//     public fun a() {}

//     fun call_b() {
//         b::b();
//     }
// }

// module cook_m3::b {
//     use cook_m3::a;

//     public fun b() {}

//     fun call_a() {
//         a::a();
//     }
// }
