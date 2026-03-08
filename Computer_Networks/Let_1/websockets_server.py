#!/usr/bin/python3

import asyncio
import websockets

async def hello(websocket, path):
    name = await websocket.recv()
    print("client say: "+str(name))

    while(True):
        greeting = input("enter answer to client: ")
        await websocket.send(greeting)
        print(str(greeting))

start_server = websockets.serve(hello, "185.102.139.168", 1566)
asyncio.get_event_loop().run_until_complete(start_server)
asyncio.get_event_loop().run_forever()
