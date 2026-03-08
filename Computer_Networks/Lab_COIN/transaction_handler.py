import asyncio
import json
from datetime import datetime, timedelta
import websockets

class TransactionHandler:
    def __init__(self, node_manager):
        self.node_manager = node_manager

    async def broadcast_table_update(self):
        """Рассылаем nodes_table всем соседям из таблицы."""
        table = self.node_manager.nodes_table
        tasks = []
        for node in list(table):
            ip = node.get("ip")
            if not ip or ip == self.node_manager.my_ip:
                continue
            # Создаем задачи для параллельной рассылки
            task = asyncio.create_task(self._send_table_update(ip, table))
            tasks.append(task)
        
        if tasks:
            await asyncio.wait(tasks, timeout=2.0)

    async def _send_table_update(self, ip: str, table: list):
        try:
            async with websockets.connect(f"ws://{ip}:{self.node_manager.port}", open_timeout=0.6, close_timeout=0.2) as ws:
                await ws.send(json.dumps({"type":"update_table", "table": table}))
        except Exception:
            # сосед недоступен — просто пропускаем
            pass

    async def broadcast_message(self, typ: str):
        tasks = []
        for node in list(self.node_manager.nodes_table):
            ip = node.get("ip")
            if not ip or ip == self.node_manager.my_ip:
                continue
            # Создаем задачи для параллельной рассылки
            task = asyncio.create_task(self._send_message(ip, typ))
            tasks.append(task)
        
        if tasks:
            await asyncio.wait(tasks, timeout=2.0)

    async def _send_message(self, ip: str, typ: str):
        try:
            async with websockets.connect(f"ws://{ip}:{self.node_manager.port}", open_timeout=0.6, close_timeout=0.2) as ws:
                await ws.send(json.dumps({"type": typ}))
        except Exception:
            pass

    async def send_transaction(self, to_id: int, amount: int):
        # простая блокировка сети на время транзакции
        if self.node_manager.lock_flag == 1:
            print("[tx] Сеть занята, попробуйте позже")
            return

        from_node = next((n for n in self.node_manager.nodes_table if n["ip"] == self.node_manager.my_ip), None)
        to_node = self.node_manager.get_node_by_id(to_id)
        if not from_node or not to_node:
            print("[tx] Некорректные участники")
            return
        if amount <= 0:
            print("[tx] Сумма должна быть > 0")
            return
        if from_node["balance"] < amount:
            print("[tx] Недостаточно средств")
            return

        # Lock сеть (3 минуты таймаут)
        self.node_manager.lock_flag = 1
        self.node_manager.lock_timeout = datetime.now() + timedelta(minutes=3)

        # Локально применяем временно
        from_node["balance"] -= amount
        to_node["balance"] += amount

        # Рассылаем всем
        await self.broadcast_message("lock_network")
        ok = await self._wait_verifications(to_id=to_id, amount=amount)
        await self.broadcast_message("unlock_network")

        # Снимаем лок
        self.node_manager.lock_flag = 0
        self.node_manager.lock_timeout = None

        if ok:
            print("[tx] Транзакция подтверждена узлами")
            await self.broadcast_table_update()
        else:
            print("[tx] Подтверждений нет — откат")
            from_node["balance"] += amount
            to_node["balance"] -= amount

    async def _wait_verifications(self, to_id: int, amount: int, timeout=2.0) -> bool:
        """Примитивная "верификация": шлём каждому запрос и ждём любую положительную реакцию."""

        async def ask(ip):
            try:
                print(f"[verify] Отправляю запрос верификации к {ip}")
                async with websockets.connect(f"ws://{ip}:{self.node_manager.port}", open_timeout=0.6,
                                              close_timeout=0.2) as ws:
                    await ws.send(json.dumps({"type": "verify_req", "to_id": to_id, "amount": amount}))
                    resp = await asyncio.wait_for(ws.recv(), timeout=0.8)
                    data = json.loads(resp)
                    print(f"[verify] Ответ от {ip}: {data}")
                    return data.get("type") == "verification" and data.get("ok") == True
            except Exception as e:
                print(f"[verify] Ошибка при запросе к {ip}: {e}")
                return False

        peers = [n["ip"] for n in self.node_manager.nodes_table if n["ip"] != self.node_manager.my_ip]
        print(f"[verify] Запрашиваю верификацию у пиров: {peers}")

        if not peers:
            # одиночный узел — считаем подтверждённым
            print("[verify] Нет других узлов - автоматическое подтверждение")
            return True

        # Создаем задачи для параллельных запросов
        tasks = [asyncio.create_task(ask(ip)) for ip in peers]
        done, pending = await asyncio.wait(tasks, timeout=timeout)

        # Отменяем оставшиеся задачи
        for task in pending:
            task.cancel()

        results = [task.result() for task in done if not task.cancelled() and task.result() is not None]
        print(f"[verify] Результаты верификации: {results}")

        return any(results)

    async def handle_incoming_transaction(self, websocket, data: dict):
        typ = data.get("type")
        if typ == "verify_req":
            # Наивная проверка: структура валидна и сумма положительна
            print(f"[verify] Получен запрос верификации: {data}")
            ok = isinstance(data.get("to_id"), int) and isinstance(data.get("amount"), int) and data["amount"] > 0
            response = {"type": "verification", "ok": ok}
            print(f"[verify] Отправляю ответ: {response}")
            await websocket.send(json.dumps(response))