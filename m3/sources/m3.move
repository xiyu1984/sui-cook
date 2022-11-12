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
    public fun init(ctx: &mut TxContext) {
        let pallet = Pallet {
            id: object::new(ctx),
            water: 100,
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

    public entry fun mint_blank(ctx: &mut TxContext) {
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
        dynamic_object_field::add(&mut picture.id, picture.mix_size, ink);
        picture.mix_size = picture.mix_size + 1;
    }
}
