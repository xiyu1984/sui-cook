module cook_m2::m2 {
    use std::option::{Self, Option};
    use sui::object::{Self, ID, UID};
    use sui::tx_context::{Self, TxContext};
    use sui::transfer;
    use sui::dynamic_object_field::{Self};

    struct Parent has key {
        id: UID,
        child_id: Option<ID>,
    }

    struct Child has key, store {
        id: UID,
        v: u128,
    }

    fun init(_ctx: &mut TxContext) {
        
    }

    public entry fun create_parent_and_child(ctx: &mut TxContext) {
        let parent_id = object::new(ctx);
        let child = Child{id: object::new(ctx), v: 11223344};
        let c_id = object::id(&child);
        dynamic_object_field::add(&mut parent_id, b"firstChild", child);
        let parent = Parent {
            id: parent_id, 
            child_id: option::some(c_id),
        };

        // transfer::transfer_to_object(child, &mut parent);

        transfer::transfer(parent, tx_context::sender(ctx));
        // transfer::transfer(child, tx_context::sender(ctx));
    }

    public entry fun set_value_child(child: &mut Child, _ctx: &mut TxContext) {
        child.v = child.v * 2; 
    }

    public fun get_value_child(child: &Child): u128 {
        child.v
    }

    public entry fun delete_parent(parent: Parent, child: Child, _ctx: &mut TxContext) {
        let Parent {id: parent_id, child_id: _} = parent;
        object::delete(parent_id);
        let Child {id: child_id, v: _} = child;
        object::delete(child_id);
    }

    #[test]
    public fun test_create() {
        use sui::test_scenario;
        // use std::debug;

        // let admin = @0xABBA;
        let owner = @0xCAFE;

        let scenario_val = test_scenario::begin(owner);
        let scenario = &mut scenario_val;

        test_scenario::next_tx(scenario, owner);
        {
            init(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            create_parent_and_child(test_scenario::ctx(scenario));
        };

        test_scenario::next_tx(scenario, owner);
        {
            let parent = test_scenario::take_from_sender<Parent>(scenario);
            
            let child = dynamic_object_field::borrow_mut<vector<u8>, Child>(&mut parent.id, b"firstChild");

            assert!(option::is_some(&mut parent.child_id), 0);
            let _child_id = option::extract(&mut parent.child_id);
            assert!(option::is_none(&mut parent.child_id), 0);
            
            assert!(get_value_child(child) == 11223344, 0);
            set_value_child(child, test_scenario::ctx(scenario));
            assert!(get_value_child(child) == 22446688, 0);

            // option::fill(&mut parent.child_id, _child_id);

            test_scenario::return_to_sender(scenario, parent);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let parent = test_scenario::take_from_sender<Parent>(scenario);

            let child = dynamic_object_field::remove<vector<u8>, Child>(&mut parent.id, b"firstChild");
            let val = get_value_child(&mut child);
            set_value_child(&mut child, test_scenario::ctx(scenario));
            assert!(get_value_child(&mut child) == val * 2, 1);

            // This will abort as `assert!(was_taken_from_address(account, id), ECantReturnObject);`
            // test_scenario::return_to_sender(scenario, child);

            transfer::transfer(child, tx_context::sender(test_scenario::ctx(scenario)));
            test_scenario::return_to_sender(scenario, parent);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let parent = test_scenario::take_from_sender<Parent>(scenario);

            // This will abort with `assert!(option::is_some(&field.value), EFieldDoesNotExist);`
            // let child = dynamic_object_field::remove<vector<u8>, Child>(&mut parent.id, b"firstChild");

            let child = test_scenario::take_from_sender<Child>(scenario);
            dynamic_object_field::add(&mut parent.id, b"firstChild", child);

            test_scenario::return_to_sender(scenario, parent);
        };

        test_scenario::next_tx(scenario, owner);
        {
            let parent = test_scenario::take_from_sender<Parent>(scenario);

            // `Parant.child_id` is an user defined member, 
            // and the underly implementation has its own child management mechanism
            assert!(option::is_none(&parent.child_id), 0);

            // transfer::transfer_to_object(child, &mut parent);
            test_scenario::return_to_sender(scenario, parent);
        };



        test_scenario::end(scenario_val);
    }
}