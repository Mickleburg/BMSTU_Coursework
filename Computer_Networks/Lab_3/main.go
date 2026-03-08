package main

import (
	"bufio"
	"encoding/json"
	"flag"
	"fmt"
	"io"
	"log"
	"net"
	"os"
	"strconv"
	"strings"
	"sync"
	"time"
)

// ==========================================
// 1. Структуры данных
// ==========================================

type MsgType string

const (
	TypeSet MsgType = "SET"
	TypeSum MsgType = "SUM"
)

type Message struct {
	Type   MsgType `json:"type"`
	Index  int     `json:"idx,omitempty"`
	Value  int     `json:"val,omitempty"`
	Start  int     `json:"start,omitempty"`
	End    int     `json:"end,omitempty"`
	Acc    int     `json:"acc,omitempty"`
	Origin string  `json:"origin,omitempty"`
}

type Node struct {
	ID         int
	TotalNodes int
	LocalPort  string
	NextIP     string
	NextPort   string

	Storage map[int]int
	mu      sync.RWMutex

	outbox   chan Message
	logger   *log.Logger
	selfAddr string
}

// ==========================================
// 2. Логика данных
// ==========================================

func (n *Node) isMyData(index int) bool {
	if n.TotalNodes == 0 {
		return false
	}
	mod := index % n.TotalNodes
	if mod < 0 {
		mod += n.TotalNodes
	}
	return mod == n.ID
}

func (n *Node) setLocal(idx, val int) {
	n.mu.Lock()
	defer n.mu.Unlock()
	n.Storage[idx] = val
	n.logger.Printf("[DATA] Stored locally: array[%d] = %d", idx, val)
}

func (n *Node) getLocalPartSum(start, end int) int {
	n.mu.RLock()
	defer n.mu.RUnlock()

	sum := 0
	for i := start; i < end; i++ {
		if n.isMyData(i) {
			if val, ok := n.Storage[i]; ok {
				sum += val
			}
		}
	}
	return sum
}

// ==========================================
// 3. Сетевая служба
// ==========================================

func (n *Node) StartServer() {
	// Явно указываем tcp4, чтобы избежать путаницы с IPv6 на некоторых системах
	ln, err := net.Listen("tcp4", ":"+n.LocalPort)
	if err != nil {
		n.logger.Fatalf("CRITICAL: Cannot listen on port %s: %v", n.LocalPort, err)
	}
	n.logger.Printf("[NET] SERVER listening on 0.0.0.0:%s", n.LocalPort)

	for {
		conn, err := ln.Accept()
		if err != nil {
			n.logger.Printf("[NET] Accept error: %v", err)
			continue
		}
		go n.handleIncomingConnection(conn)
	}
}

func (n *Node) handleIncomingConnection(conn net.Conn) {
	remote := conn.RemoteAddr().String()
	n.logger.Printf("[NET] NEW INCOMING connection from %s", remote)
	defer conn.Close()

	decoder := json.NewDecoder(conn)

	for {
		var msg Message
		err := decoder.Decode(&msg)
		if err != nil {
			if err == io.EOF {
				n.logger.Printf("[NET] Connection closed by peer %s", remote)
			} else {
				n.logger.Printf("[NET] Decode error from %s: %v", remote, err)
			}
			return
		}

		// Логируем факт получения
		n.logger.Printf("[RX] Recv %s. Origin=%s. Acc=%d", msg.Type, msg.Origin, msg.Acc)
		n.processMessage(msg)
	}
}

func (n *Node) processMessage(msg Message) {
	switch msg.Type {
	case TypeSet:
		if n.isMyData(msg.Index) {
			n.setLocal(msg.Index, msg.Value)
		} else {
			n.logger.Printf("[FWD] Index %d belongs to peer %d. Forwarding...", msg.Index, msg.Index%n.TotalNodes)
			n.outbox <- msg
		}

	case TypeSum:
		// Если Origin совпадает с нашим ID - круг замкнулся
		if msg.Origin == n.selfAddr {
			fmt.Printf("\n>>> SUM RESULT [%d, %d): %d <<<\n\n", msg.Start, msg.End, msg.Acc)
			fmt.Print("> ")
			return
		}

		localSum := n.getLocalPartSum(msg.Start, msg.End)
		msg.Acc += localSum
		n.logger.Printf("[LOGIC] Added local %d. Sending Acc=%d to next.", localSum, msg.Acc)

		n.outbox <- msg
	}
}

func (n *Node) StartClientLoop() {
	address := net.JoinHostPort(n.NextIP, n.NextPort)
	var conn net.Conn
	var encoder *json.Encoder

	// Буфер для повторной отправки сообщения при сбое
	var pendingMsg *Message

	for {
		// 1. Установка соединения (с таймаутом!)
		if conn == nil {
			n.logger.Printf("[NET] Dialing next peer %s (timeout 5s)...", address)
			// ИСПРАВЛЕНИЕ: DialTimeout не даст зависнуть, если IP недоступен
			c, err := net.DialTimeout("tcp", address, 5*time.Second)
			if err != nil {
				n.logger.Printf("[NET] Dial failed: %v. Retrying in 2s...", err)
				time.Sleep(2 * time.Second)
				continue
			}

			// Настройка KeepAlive
			if tcpConn, ok := c.(*net.TCPConn); ok {
				tcpConn.SetKeepAlive(true)
				tcpConn.SetKeepAlivePeriod(10 * time.Second)
			}

			conn = c
			encoder = json.NewEncoder(conn)
			n.logger.Printf("[NET] SUCCESS: Connected to next peer %s", address)
		}

		// 2. Определяем, какое сообщение отправлять
		var msgToSend Message

		if pendingMsg != nil {
			msgToSend = *pendingMsg
			pendingMsg = nil // Сбрасываем, попробуем отправить сейчас
		} else {
			// Ждем новое сообщение из канала
			select {
			case m := <-n.outbox:
				msgToSend = m
			case <-time.After(1 * time.Second):
				// Периодически проверяем состояние коннекта (опционально),
				// или просто крутимся в цикле, чтобы проверить conn != nil
				continue
			}
		}

		// 3. Отправка
		// Ставим таймаут на запись, чтобы не зависнуть при отправке
		conn.SetWriteDeadline(time.Now().Add(5 * time.Second))
		err := encoder.Encode(msgToSend)

		if err != nil {
			n.logger.Printf("[NET] Send ERROR: %v. Drop connection.", err)
			conn.Close()
			conn = nil
			// Сохраняем сообщение, чтобы отправить его в следующей итерации после реконнекта
			pendingMsg = &msgToSend
			time.Sleep(1 * time.Second)
		} else {
			n.logger.Printf("[TX] Sent %s to %s", msgToSend.Type, address)
			// Сбрасываем дедлайн
			conn.SetWriteDeadline(time.Time{})
		}
	}
}

// ==========================================
// 4. CLI
// ==========================================

func (n *Node) StartCLI() {
	scanner := bufio.NewScanner(os.Stdin)
	time.Sleep(500 * time.Millisecond)

	fmt.Println("--- Node Started ---")
	fmt.Printf("ID: %d | Total: %d | Self: %s -> Next: %s:%s\n", n.ID, n.TotalNodes, n.selfAddr, n.NextIP, n.NextPort)
	fmt.Print("> ")

	for scanner.Scan() {
		line := scanner.Text()
		parts := strings.Fields(line)
		if len(parts) == 0 {
			fmt.Print("> ")
			continue
		}

		cmd := strings.ToLower(parts[0])

		if cmd == "set" && len(parts) == 3 {
			idx, _ := strconv.Atoi(parts[1])
			val, _ := strconv.Atoi(parts[2])

			if n.isMyData(idx) {
				n.setLocal(idx, val)
			} else {
				// n.logger.Printf("[CLI] Queuing SET %d->%d for forwarding", idx, val)
				n.outbox <- Message{Type: TypeSet, Index: idx, Value: val}
			}

		} else if cmd == "sum" && len(parts) == 3 {
			start, _ := strconv.Atoi(parts[1])
			end, _ := strconv.Atoi(parts[2])

			initialAcc := n.getLocalPartSum(start, end)

			// n.logger.Printf("[CLI] Queuing SUM [%d, %d). Local=%d", start, end, initialAcc)
			n.outbox <- Message{
				Type:   TypeSum,
				Start:  start,
				End:    end,
				Acc:    initialAcc,
				Origin: n.selfAddr,
			}
			fmt.Println("Request queued...")

		} else {
			fmt.Println("Usage: set <idx> <val> OR sum <start> <end>")
		}
		fmt.Print("> ")
	}
}

// Main

func main() {
	nodeID := flag.Int("id", 0, "Current Node ID (0, 1, ...)")
	totalNodes := flag.Int("n", 3, "Total number of nodes")

	localPort := flag.String("port", "7533", "Local port to listen")
	selfIP := flag.String("self-ip", "127.0.0.1", "Public IP of THIS server")

	nextIP := flag.String("next-ip", "127.0.0.1", "IP of the next node")
	nextPort := flag.String("next-port", "7533", "Port of the next node")

	flag.Parse()

	// Формируем уникальный идентификатор узла из IP и Port
	selfAddr := net.JoinHostPort(*selfIP, *localPort)

	// Настройка логов в stdout
	logger := log.New(os.Stdout, fmt.Sprintf("[NODE-%d] ", *nodeID), log.Ltime)

	node := &Node{
		ID:         *nodeID,
		TotalNodes: *totalNodes,
		LocalPort:  *localPort,
		NextIP:     *nextIP,
		NextPort:   *nextPort,
		Storage:    make(map[int]int),
		outbox:     make(chan Message, 1000), // Буфер 1000, чтобы CLI не вис при обрыве
		logger:     logger,
		selfAddr:   selfAddr,
	}

	go node.StartServer()
	go node.StartClientLoop()

	node.StartCLI()
}

// go run main.go -id=0 -n=3 -port=7533 -self-ip=95.81.121.63 -next-ip=185.102.139.161 -next-port=7533
// go run main.go -id=1 -n=3 -port=7533 -self-ip=185.102.139.161 -next-ip=185.102.139.168 -next-port=7533
// go run main.go -id=2 -n=3 -port=7533 -self-ip=185.102.139.168 -next-ip=95.81.121.63 -next-port=7533

