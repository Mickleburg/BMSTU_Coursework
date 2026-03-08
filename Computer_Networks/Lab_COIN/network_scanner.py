import asyncio
import json
import websockets

class NetworkScanner:
    def __init__(self, node_manager):
        self.node_manager = node_manager

    async def initialize_or_join(self) -> str:
        """Ищем соседа в локальной подсети. Если нашли — тянем таблицу и добавляем себя.
        Если нет — создаём новую сеть."""
        table = await self._discover_table_from_any_peer()
        if table:
            status = self.node_manager.add_self_to_network(table)
            if status == "connected_new":
                # Расшарим обновленную таблицу
                await self._broadcast_table()
            return status
        else:
            self.node_manager.create_new_network()
            return "new_network"

    async def _discover_table_from_any_peer(self) -> list[dict] | None:
        tasks = []
        # Параллельно пробуем весь /24 (кроме своего IP)
        for i in range(1, 255):
            ip = f"{self.node_manager.network_base}{i}"
            if ip == self.node_manager.my_ip:
                continue
            # Явно создаем задачи
            task = asyncio.create_task(self._try_get_table(ip))
            tasks.append(task)

        if tasks:
            done, pending = await asyncio.wait(tasks, timeout=3.5)
            
            # Отменяем оставшиеся задачи
            for task in pending:
                task.cancel()
            
            # Проверяем результаты выполненных задач
            for task in done:
                try:
                    table = await task
                    if table:
                        return table
                except Exception:
                    continue
        return None

    async def _try_get_table(self, ip: str):
        try:
            uri = f"ws://{ip}:{self.node_manager.port}"
            async with websockets.connect(uri, open_timeout=0.6, close_timeout=0.2) as ws:
                await ws.send(json.dumps({"type":"get_table", "ip": self.node_manager.my_ip}))
                reply = await asyncio.wait_for(ws.recv(), timeout=1.0)
                data = json.loads(reply)
                if data.get("type") == "table_data":
                    return data.get("table")
        except Exception:
            return None

    async def _broadcast_table(self):
        from transaction_handler import TransactionHandler
        await TransactionHandler(self.node_manager).broadcast_table_update()