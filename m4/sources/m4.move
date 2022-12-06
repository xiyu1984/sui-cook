module cook_m4::m4 {
    // use sui::bcs;
    
    use std::option::{Option};
    // use std::vector;

    struct TestOption has copy, drop, store {
        n: u128,
        t: vector<u8>,
        v: Option<vector<u8>>,
    }

    #[test]
    public fun test_bcs_opt_in_struct() {
        use sui::bcs;
        use std::option;

        let raw_opt: Option<vector<u8>> = option::some(vector<u8>[73, 37]);
        let raw_opt_none: Option<vector<u8>> = option::none();
        std::debug::print(&bcs::to_bytes(&raw_opt));
        std::debug::print(&bcs::to_bytes(&raw_opt_none));

        let t_opt = TestOption {
            n: 128000,
            t: vector<u8>[1,2,3,4],
            v: option::some(vector<u8>[73, 37]),
        };

        let optBytes = bcs::to_bytes(&t_opt);
        std::debug::print(&optBytes);

        assert!(optBytes == vector<u8>[
                                        0, 244, 1, 0, 0, 0, 0,  0,
                                        0,   0, 0, 0, 0, 0, 0,  0,
                                        4,   1, 2, 3, 4, 1, 2, 73,
                                        37
                                        ], 0);

        let t_opt_none = TestOption {
            n: 128000,
            t: vector<u8>[1,2,3,4],
            v: option::none(),
        };

        let optBytesNone = bcs::to_bytes(&t_opt_none);
        std::debug::print(&optBytesNone);

        assert!(optBytesNone == vector<u8>[
                                            0, 244, 1, 0, 0, 0, 0,
                                            0,   0, 0, 0, 0, 0, 0,
                                            0,   0, 4, 1, 2, 3, 4,
                                            0
                                            ], 0);
    }
}
