import { JsonRpcProvider, Network } from '@mysten/sui.js';
import {BCS, fromB64, getSuiMoveConfig } from '@mysten/bcs'

const provider = new JsonRpcProvider(Network.DEVNET);
const bcs = new BCS(getSuiMoveConfig());

async function event_test() {
    const eventQuery = {"MoveModule": {package: "0x6a8870d9194ac8cfd013fa64428885117ed8fb50", module: 'm3'}};
    const allEvents = await provider.getEvents(eventQuery);
    for (var idx in allEvents.data) {
        console.log(allEvents.data[idx].event);
        if (undefined != allEvents.data[idx].event.moveEvent) {
            console.log(allEvents.data[idx].event.moveEvent.fields);
        }
    }
}

// doesn't work
async function struct_event_test() {
    const eventQuery = {"MoveEvent": "EventOperatePic"};
    const allEvents = await provider.getEvents(eventQuery);
    console.log(allEvents);
}

// await event_test();
await struct_event_test();
