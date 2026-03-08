import asyncio
import argparse

from node_manager import NodeManager
from network_scanner import NetworkScanner
from websocket_server import WebSocketServer
from user_interface import UserInterface

async def main():
    parser = argparse.ArgumentParser()
    parser.add_argument("--owner", required=True, help="Имя владельца узла")
    parser.add_argument("--port", type=int, default=9000)
    parser.add_argument("--subnet", default=None, help="Напр. 192.168.1.")
    args = parser.parse_args()

    node_manager = NodeManager(owner_name=args.owner, port=args.port, network_base=args.subnet)
    network_scanner = NetworkScanner(node_manager)
    ws_server = WebSocketServer(node_manager)
    ui = UserInterface(node_manager)

    print(f"Мой IP: {node_manager.my_ip}, подсеть: {node_manager.network_base}0/24, порт: {node_manager.port}")

    server_task = asyncio.create_task(ws_server.start())
    status = await network_scanner.initialize_or_join()
    print(f"[init] Режим: {status}")

    timeout_task = asyncio.create_task(node_manager.check_lock_timeout())
    ui_task = asyncio.create_task(ui.run())

    try:
        await ui_task
    finally:
        for t in (server_task, timeout_task):
            t.cancel()
        await asyncio.gather(server_task, timeout_task, return_exceptions=True)

if __name__ == "__main__":
    asyncio.run(main())
