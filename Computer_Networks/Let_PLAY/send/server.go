package main

import (
    "fmt"
    "net"
    "os"
)

func main() {
    // Запуск UDP сервера на порту 8080
    addr, err := net.ResolveUDPAddr("udp", ":8080")
    if err != nil {
        fmt.Println("Error resolving address:", err)
        os.Exit(1)
    }

    conn, err := net.ListenUDP("udp", addr)
    if err != nil {
        fmt.Println("Error listening:", err)
        os.Exit(1)
    }
    defer conn.Close()

    fmt.Println("UDP server listening on port 8080")

    buffer := make([]byte, 1024)

    for {
        // Чтение данных от клиента
        n, clientAddr, err := conn.ReadFromUDP(buffer)
        if err != nil {
            fmt.Println("Error reading:", err)
            continue
        }

        message := string(buffer[:n])
        fmt.Printf("Received from %s: %s\n", clientAddr, message)

        // Отправка ответа клиенту
        response := fmt.Sprintf("Echo: %s", message)
        _, err = conn.WriteToUDP([]byte(response), clientAddr)
        if err != nil {
            fmt.Println("Error writing:", err)
        }
    }
}