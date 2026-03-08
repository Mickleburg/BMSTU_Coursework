import asyncio
from transaction_handler import TransactionHandler

class UserInterface:
    def __init__(self, node_manager):
        self.node_manager = node_manager
        self.tx = TransactionHandler(node_manager)

    async def run(self):
        while True:
            print("\n1. Показать таблицу узлов")
            print("2. Отправить коины")
            print("3. Выход")
            choice = await asyncio.to_thread(input, "Выберите действие: ")
            if choice == "1":
                self.node_manager.print_nodes_table()
            elif choice == "2":
                try:
                    to_id = int(await asyncio.to_thread(input, "ID получателя: "))
                    amount = int(await asyncio.to_thread(input, "Сумма: "))
                    await self.tx.send_transaction(to_id, amount)
                except ValueError:
                    print("Некорректный ввод")
            elif choice == "3":
                print("Выход...")
                break
            else:
                print("Неверный выбор")
