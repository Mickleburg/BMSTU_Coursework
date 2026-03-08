import asyncio
import json
from datetime import datetime, timedelta
import websockets

from transaction_handler import TransactionHandler

class WebSocketServer:
    def __init__(self, node_manager):
        self.node_manager = node_manager
        self.tx = TransactionHandler(node_manager)

    async def start(self):
        async with websockets.serve(self._handle, "0.0.0.0", self.node_manager.port):
            print(f"[ws] Слушаю 0.0.0.0:{self.node_manager.port}")
            await asyncio.Future()

    async def _handle(self, websocket):
        async for raw in websocket:
            try:
                data = json.loads(raw)
            except Exception:
                continue

            typ = data.get("type")
            if typ == "get_table":
                await websocket.send(json.dumps({"type":"table_data", "table": self.node_manager.nodes_table}))

            elif typ == "update_table":
                # доверяем источнику в рамках примера
                async with self.node_manager.table_lock:
                    self.node_manager.nodes_table = data.get("table", [])
                print("[ws] Таблица принята и применена")

            elif typ == "lock_network":
                self.node_manager.lock_flag = 1
                self.node_manager.lock_timeout = datetime.now() + timedelta(minutes=3)

            elif typ == "unlock_network":
                self.node_manager.lock_flag = 0
                self.node_manager.lock_timeout = None

            elif typ == "verify_req":
                # Обрабатываем запрос верификации транзакции
                await self.tx.handle_incoming_transaction(websocket, data)