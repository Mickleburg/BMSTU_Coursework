package main

import (
	"bufio"
	"fmt"
	"net"
	"os"
	"time"
)

func main() {
	// Подключение к UDP серверу
	serverAddr, err := net.ResolveUDPAddr("udp", "localhost:8080")
	if err != nil {
		fmt.Println("Error resolving address:", err)
		os.Exit(1)
	}

	conn, err := net.DialUDP("udp", nil, serverAddr)
	if err != nil {
		fmt.Println("Error connecting:", err)
		os.Exit(1)
	}
	defer conn.Close()

	fmt.Println("Connected to UDP server. Type messages to send (type 'quit' to exit):")

	scanner := bufio.NewScanner(os.Stdin)

	for {
		fmt.Print("> ")
		if !scanner.Scan() {
			break
		}

		message := scanner.Text()
		if message == "quit" {
			break
		}

		// Отправка сообщения
		_, err = conn.Write([]byte(message))
		if err != nil {
			fmt.Println("Error sending:", err)
			continue
		}

		// Чтение ответа с таймаутом
		conn.SetReadDeadline(time.Now().Add(5 * time.Second))

		buffer := make([]byte, 1024)
		n, err := conn.Read(buffer)
		if err != nil {
			if netErr, ok := err.(net.Error); ok && netErr.Timeout() {
				fmt.Println("Timeout: no response from server")
				continue
			}
			fmt.Println("Error reading:", err)
			continue
		}

		response := string(buffer[:n])
		fmt.Printf("Server response: %s\n", response)
	}
}
