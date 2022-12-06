import { JsonRpcProvider, Network } from '@mysten/sui.js';
import {BCS, fromB64, getSuiMoveConfig } from '@mysten/bcs'

async function test_bcs_option() {
    const bcs = new BCS(getSuiMoveConfig());
    bcs.registerEnumType('Option<vector<u8>>', {
        some: BCS.STRING,
        none: null
    });
    
    const optName = 'OptStruct';
    bcs.registerStructType('OptStruct', {
        v: 'Option<vector<u8>>'
    });

    const serBytes = bcs.ser(optName, {
        v: {some: Buffer.from([73, 37]).toString('base64')}
    }).toBytes();
    console.log(serBytes);

    const deItem = bcs.de(optName, serBytes, 'base64');
    console.log(deItem);
}

async function test_bcs_on_chain_option() {
    const bcs = new BCS(getSuiMoveConfig());

    const optName = 'OptStruct';
    bcs.registerStructType(optName, {
        n: BCS.U128,
        t: 'vector<u8>',
        v: 'vector<vector<u8>>'
    });

    const serBytes = bcs.ser(optName, {
        n: '128000',
        t: [1,2,3,4],
        v: [[73, 37]]
    }).toBytes();
    console.log(serBytes);

    const deItem = bcs.de(optName, serBytes, 'base64');
    console.log(deItem);

    const serNoneBytes = bcs.ser(optName, {
        n: '128000',
        t: [1,2,3,4],
        v: [],
    }).toBytes();
    console.log(serNoneBytes);

    const deItemNone = bcs.de(optName, serNoneBytes, 'base64');
    console.log(deItemNone);
}

async function test_bcs_option_raw() {
    const bcs = new BCS(getSuiMoveConfig());
    
    console.log(bcs.parseTypeName('vector<vector<u8>>'));

    // bcs.registerVectorType('vector<u8>', 'u8');
    // bcs.registerStructType('structVec', 'vector<vector<u8>>');

    const optName = 'OptStruct';
    bcs.registerStructType('OptStruct', {
        v: 'vector<vector<u8>>'
    });

    const serBytesSome = bcs.ser(optName, {
        v: [[73, 37]]
    }).toBytes();
    console.log(serBytesSome);

    const serBytesNone = bcs.ser(optName, {
        v: []
    }).toBytes();
    console.log(serBytesNone);

    // const deItem = bcs.de(optName, serBytes, 'base64');
    // console.log(deItem);
}

// await test_bcs_option();
await test_bcs_on_chain_option();
// await test_bcs_option_raw();