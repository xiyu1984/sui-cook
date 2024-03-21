module cook_m4::receiver {
    use cook_m4::payload::{Self, RawPayload};
    use cook_m4::message_item;
    use cook_m4::SQoS::{Self, SQoS};
    use cook_m4::session::{Self, Session};

    use sui::object::{Self, UID, ID};
    use sui::tx_context::{TxContext};
    use sui::table;
    use sui::ecdsa;
    use sui::transfer;
    // use sui::event;

    use std::vector;
    // use std::option::{Self, Option};

    struct RecvMessage has copy, drop, store {
        msgID: u128,
        fromChain: vector<u8>,
        toChain: vector<u8>,

        sqos: SQoS,
        contractName: address,   // Target Sui account
        actionName: vector<u8>,     // Target operation name
        data: RawPayload,

        sender: vector<u8>,
        signer: vector<u8>,

        session: Session,

        // message hash. not included in raw bytes
        message_hash: vector<u8>,
    }

    // The event happens when message verification completed
    struct EventToAccount has copy, drop {
        id: ID,
        msgID: u128,
        fromChain: vector<u8>,
    }

    struct MessageCopy has copy, drop, store {
        message: RecvMessage,
        submitters: vector<address>,
        credibility: u64,
    }

    struct RecvCache has copy, drop, store {
        copy_cache: vector<MessageCopy>,
        submission_count: u32,
    }

    struct ProtocolRecver has key, store {
        id: UID,
        max_recved_id: table::Table<vector<u8>, u128>,          // map<from chain, received message ID>
        message_cache: table::Table<vector<u8>, RecvCache>,     // map<from chain | msgID, RecvCache>

        default_copy_count: u32,
    }

    fun init(ctx: &mut TxContext) {
        let recver = ProtocolRecver {
            id: object::new(ctx),
            max_recved_id: table::new(ctx),
            message_cache: table::new(ctx),
            default_copy_count: 1,
        };

        transfer::share_object(recver);
    }

    #[test_only]
    fun test_init(ctx: &mut TxContext) {
        let recver = ProtocolRecver {
            id: object::new(ctx),
            max_recved_id: table::new(ctx),
            message_cache: table::new(ctx),
            default_copy_count: 1,
        };

        transfer::share_object(recver);
    }

    /////////////////////////////////////////////////////////////////////////
    /// RecvMessage
    public fun rv_msg_id(rv: &RecvMessage): u128 {rv.msgID}
    public fun rv_from_chain(rv: &RecvMessage): vector<u8> {rv.fromChain}
    public fun rv_to_chain(rv: &RecvMessage): vector<u8> {rv.toChain}
    public fun rv_sqos(rv: &RecvMessage): SQoS {rv.sqos}
    public fun rv_contract_name(rv: &RecvMessage): address {rv.contractName}
    public fun rv_action_name(rv: &RecvMessage): vector<u8> {rv.actionName}
    public fun rv_payload(rv: &RecvMessage): RawPayload {rv.data}
    public fun rv_sender(rv: &RecvMessage): vector<u8> {rv.sender}
    public fun rv_signer(rv: &RecvMessage): vector<u8> {rv.signer}
    public fun rv_session(rv: &RecvMessage): Session {rv.session}
    public fun rv_hash(rv: &RecvMessage): vector<u8> {rv.message_hash}

    // The entry function for off-chain nodes delivering cross-chain message
    public entry fun submit_message(msgID: u128,
                                    fromChain: vector<u8>,
                                    toChain: vector<u8>,
                                    bcs_sqos: vector<vector<u8>>,       // bcs bytes of SQoSItem
                                    contractName: address,
                                    actionName: vector<u8>,
                                    bcs_data: vector<vector<u8>>,       // bcs bytes of MessageItem
                                    sender: vector<u8>,
                                    signer: vector<u8>,
                                    bcs_session: vector<u8>,            // bcs bytes of Session
                                    protocol_recver: address,
                                    _: &mut TxContext) {
        // let submitter = tx_context::sender(ctx);

        std::debug::print(&msgID);
        std::debug::print(&fromChain);
        std::debug::print(&toChain);
        std::debug::print(&bcs_sqos);
        std::debug::print(&contractName);
        std::debug::print(&actionName);
        std::debug::print(&bcs_data);
        std::debug::print(&sender);
        std::debug::print(&signer);
        std::debug::print(&bcs_session);
        std::debug::print(&protocol_recver);

        // test decoding
        // let _ = session::de_item_from_bcs(&bcs_session);

        // let sqos = SQoS::create_SQoS();
        // let idx = 0;
        // while (idx < vector::length(&bcs_sqos)) {
        //     SQoS::add_sqos_item(&mut sqos, SQoS::de_item_from_bcs(vector::borrow(&bcs_sqos, idx)));  
        //     idx = idx + 1;
        // };

        // let payload_data = payload::create_raw_payload();
        // idx = 0;
        // while (idx < vector::length(&bcs_data)) {
        //     payload::push_back_raw_item(&mut payload_data, message_item::de_item_from_bcs(vector::borrow(&bcs_data, idx)));
        //     idx = idx + 1;
        // };
        let _ = create_recv_message(msgID, fromChain, toChain, bcs_sqos, contractName, actionName, bcs_data, sender, signer, bcs_session);

    }

    public fun into_raw_bytes(recvMessage: &RecvMessage): vector<u8> {
        let output = vector::empty<u8>();

        vector::append(&mut output, message_item::number_to_be_rawbytes(&recvMessage.msgID));
        vector::append(&mut output, recvMessage.fromChain);
        vector::append(&mut output, recvMessage.toChain);

        vector::append(&mut output, SQoS::sqos_to_bytes(&recvMessage.sqos));

        vector::append(&mut output, message_item::address_to_rawbytes(&recvMessage.contractName));
        vector::append(&mut output, recvMessage.actionName);

        vector::append(&mut output, payload::raw_payload_to_rawbytes(&recvMessage.data));

        vector::append(&mut output, recvMessage.sender);
        vector::append(&mut output, recvMessage.signer);

        vector::append(&mut output, session::session_to_rawbytes(&recvMessage.session));

        output
    }

    /////////////////////////////////////////////////////////////////////////
    // private functions
    fun create_recv_message(msgID: u128,
                            fromChain: vector<u8>,
                            toChain: vector<u8>,
                            bcs_sqos: vector<vector<u8>>,       // bcs bytes of SQoSItem
                            contractName: address,
                            actionName: vector<u8>,
                            bcs_data: vector<vector<u8>>,       // bcs bytes of MessageItem
                            sender: vector<u8>,
                            signer: vector<u8>,
                            bcs_session: vector<u8>,            // bcs bytes of Session
                            ): RecvMessage {
        // generate `RecvMessage`
        let sqos = SQoS::create_SQoS();
        let idx = 0;
        while (idx < vector::length(&bcs_sqos)) {
            SQoS::add_sqos_item(&mut sqos, SQoS::de_item_from_bcs(vector::borrow(&bcs_sqos, idx)));  
            idx = idx + 1;
        };

        let payload_data = payload::create_raw_payload();
        idx = 0;
        while (idx < vector::length(&bcs_data)) {
            payload::push_back_raw_item(&mut payload_data, message_item::de_item_from_bcs(vector::borrow(&bcs_data, idx)));
            idx = idx + 1;
        };

        let sess = session::de_item_from_bcs(&bcs_session);
        
        let recv_message = RecvMessage {
            msgID,
            fromChain,
            toChain,
            sqos,
            contractName,
            actionName,
            data: payload_data,
            sender,
            signer,
            session: sess,
            message_hash: vector<u8>[],
        };

        recv_message.message_hash = ecdsa::keccak256(&into_raw_bytes(&recv_message));

        recv_message
    }
}
