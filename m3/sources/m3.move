module cook_m3::m3 {
    use sui::object::{UID};

    const COLOR_RED: u64 = 0;
    public fun red(): u64 {COLOR_RED}
    const COLOR_GREEN: u64 = 1;
    public fun green(): u64 {COLOR_GREEN}

    struct Apple has key, store {
        id: UID,
        color: u64,
    }

    struct Juice has key, store {
        id: UID,
    }


    struct JuiceExtractor has key, store {
        id: UID,
    }

    
}