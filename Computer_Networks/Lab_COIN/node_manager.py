import asyncio
import socket
from datetime import datetime, timedelta

class NodeManager:
    def __init__(self, owner_name: str, port: int = 9000, network_base: str | None = None):
        self.port = port
        self.network_base = network_base or self._derive_subnet()
        self.my_ip = self._get_my_ip()
        self.owner_name = owner_name

        self.nodes_table: list[dict] = []
        self._id_counter = 0

        self.lock_flag = 0
        self.lock_timeout: datetime | None = None

        self.table_lock = asyncio.Lock()

    def _get_my_ip(self) -> str:
        s = socket.socket(socket.AF_INET, socket.SOCK_DGRAM)
        try:
            s.connect(("8.8.8.8", 80))
            ip = s.getsockname()[0]
        except Exception:
            ip = "127.0.0.1"
        finally:
            s.close()
        return ip

    def _derive_subnet(self) -> str:
        ip = self._get_my_ip()
        parts = ip.split(".")
        if len(parts) == 4:
            return ".".join(parts[:3]) + "."
        return "192.168.1."

    async def check_lock_timeout(self):
        while True:
            if self.lock_flag == 1 and self.lock_timeout and datetime.now() > self.lock_timeout:
                print("[lock] Таймаут, снимаю блокировку сети")
                self.lock_flag = 0
                self.lock_timeout = None
            await asyncio.sleep(2)

    def _gen_id(self) -> int:
        self._id_counter += 1
        return self._id_counter

    def get_node_by_id(self, node_id: int) -> dict | None:
        for n in self.nodes_table:
            if n["id"] == node_id:
                return n
        return None

    def create_new_network(self):
        # Первый узел сети
        self.nodes_table = [{
            "id": 1,
            "ip": self.my_ip,
            "owner": self.owner_name,
            "balance": 10
        }]
        self._id_counter = 1
        print("[net] Создана новая сеть, я — узел #1")

    def add_self_to_network(self, table_from_peer: list[dict]) -> str:
        # Копируем таблицу, проверяем наличие себя
        self.nodes_table = [dict(x) for x in table_from_peer]
        exists = any(n["ip"] == self.my_ip for n in self.nodes_table)
        if exists:
            # Уже есть: просто обновим owner (на случай изменения имени)
            for n in self.nodes_table:
                if n["ip"] == self.my_ip:
                    n["owner"] = self.owner_name
            print("[net] Уже в сети")
            # установим счётчик id выше максимума
            self._id_counter = max(n["id"] for n in self.nodes_table) if self.nodes_table else 0
            return "connected_existing"
        else:
            # Добавляем себя с новым ID
            new_id = max([n["id"] for n in self.nodes_table] + [0]) + 1
            self.nodes_table.append({
                "id": new_id,
                "ip": self.my_ip,
                "owner": self.owner_name,
                "balance": 10
            })
            self._id_counter = max(self._id_counter, new_id)
            print(f"[net] Присоединился как узел #{new_id}")
            return "connected_new"

    def print_nodes_table(self):
        print("\n" + "="*58)
        print("ТАБЛИЦА УЗЛОВ")
        print("="*58)
        for n in self.nodes_table:
            print(f"ID: {n['id']:>2} | IP: {n['ip']:<15} | Owner: {n['owner']:<10} | Balance: {n['balance']}")
        print("="*58)