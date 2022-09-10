module cook_m1::m1 {
    use sui::object::{Self, UID};
    use sui::tx_context::TxContext;

    struct Sword has key, store {
        id: UID,
        magic: u64,
        strength: u64,
    }

    struct Association has key, store {
        id: UID,
        license_count: u64,
    }

    struct CastLicense has key, store {
        id: UID,
        sword_count: u64,
    }

    fun init(ctx: &mut TxContext) {
        use sui::transfer;
        use sui::tx_context;

        let admin = Association {
            id: object::new(ctx),
            license_count: 0,
        };

        transfer::transfer(admin, tx_context::sender(ctx));
    }

    public fun get_license_count(asso: &Association): u64 {
        asso.license_count
    }

    public fun magic(self: &Sword): u64 {
        self.magic
    }

    public fun strength(self: &Sword): u64 {
        self.strength
    }

    public entry fun publish_license(asso: &mut Association, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;

        let license = CastLicense {
            id: object::new(ctx),
            sword_count: 0,
        };

        transfer::transfer(license, recipient);

        asso.license_count = asso.license_count + 1;
    }

    public entry fun sword_create(license: &mut CastLicense, magic: u64, strength: u64, recipient: address, ctx: &mut TxContext) {
        use sui::transfer;
        // use sui::tx_context;
        // create a sword
        let sword = Sword {
            id: object::new(ctx),
            magic: magic,
            strength: strength,
        };
        // transfer the sword
        transfer::transfer(sword, recipient);

        license.sword_count = license.sword_count + 1;
    }

    public fun get_sword_count(license: &CastLicense): u64 {
        license.sword_count
    }

    public entry fun sword_transfer(sword: Sword, recipient: address, _ctx: &mut TxContext) {
        use sui::transfer;
        // transfer the sword
        transfer::transfer(sword, recipient);
    }

    #[test]
    public fun test_sword_create() {
        use sui::tx_context;
        use sui::transfer;
        // use std::debug;

        // create a dummy TxContext for testing
        let ctx = tx_context::dummy();

        // create a sword
        let sword = Sword {
            id: object::new(&mut ctx),
            magic: 42,
            strength: 7,
        };

        // let myBytes: vector<u8> = b"Hello";
        // let myBytes2 = x"11223344";
        // debug::print<vector<u8>>(&myBytes);
        // debug::print<vector<u8>>(&myBytes2);

        // check if accessor functions return correct values
        assert!(magic(&sword) == 42 && strength(&sword) == 7, 99);

        let dummy_address = @0xCAFE;
        transfer::transfer(sword, dummy_address);
    }

    #[test]
    public fun test_transaction() {
        use sui::test_scenario;
        // use std::debug;

        let admin = @0xABBA;
        let caster = @0xCAFE;
        let sword_holder = @0xFACE;
        let killer = @0xFFAA;

        // first transaction executed by admin
        let scenario = &mut test_scenario::begin(&admin);
        {
            init(test_scenario::ctx(scenario));
        };

        // next transaction executed by admin
        test_scenario::next_tx(scenario, &admin);
        {
            let asso = test_scenario::take_owned<Association>(scenario);
            // create the license and transfer it to the caster
            publish_license(&mut asso, caster, test_scenario::ctx(scenario));
            // debug::print<u64>(&get_license_count(&asso));

            test_scenario::return_owned(scenario, asso);
        };

        // next transaction executed by caster
        test_scenario::next_tx(scenario, &caster);
        {
            let license = test_scenario::take_owned<CastLicense>(scenario);

            // create a sword to the `sword holder` by the caster
            sword_create(&mut license, 99, 99, sword_holder, test_scenario::ctx(scenario));
            // debug::print<u64>(&get_sword_count(&license));

            test_scenario::return_owned(scenario, license);
        };

        // next transaction executed by the sword holder
        test_scenario::next_tx(scenario, &sword_holder);
        {
            // extract the sword owned by the initial owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // transfer the sword to the final owner
            sword_transfer(sword, killer, test_scenario::ctx(scenario));
        };

        // third transaction executed by the final sword owner
        test_scenario::next_tx(scenario, &killer);
        {
            // extract the sword owned by the final owner
            let sword = test_scenario::take_owned<Sword>(scenario);
            // verify that the sword has expected properties
            assert!(magic(&sword) == 99 && strength(&sword) == 99, 1);
            // return the sword to the object pool (it cannot be simply "dropped")
            test_scenario::return_owned(scenario, sword)
        }
    }
}
