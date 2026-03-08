package proto

import "encoding/json"

// Request -- запрос клиента к серверу.
type Request struct {
	// Command может принимать значения:
	// "quit" - завершение соединения
	// "calculate" - вычисление тригонометрической функции
	Command string           `json:"command"`
	Data    *json.RawMessage `json:"data"`
}

// Response -- ответ сервера клиенту.
type Response struct {
	// Status может принимать значения:
	// "ok" - успешное выполнение команды "quit"
	// "result" - возврат результата вычисления
	// "failed" - ошибка при выполнении команды
	Status string           `json:"status"`
	Data   *json.RawMessage `json:"data"`
}

// TrigRequest -- данные для вычисления тригонометрической функции.
type TrigRequest struct {
	Function string  `json:"function"` // Название функции: "sin", "cos", "tan"
	Angle    float64 `json:"angle"`    // Угол в градусах
}
