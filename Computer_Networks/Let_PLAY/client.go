package main

import (
    "bufio"
    "fmt"
    "net"
    "os"
    "time"
)

func main() {
    srv, err := net.ResolveUDPAddr("udp", "localhost:8080")
    if err != nil {
        fmt.Println("ResolveUDPAddr:", err)
        os.Exit(1)
    }
    conn, err := net.DialUDP("udp", nil, srv)
    if err != nil {
        fmt.Println("DialUDP:", err)
        os.Exit(1)
    }
    defer conn.Close()

    fmt.Println("Minesweeper 4×4 (UDP localhost:8080)")
    fmt.Println("Commands:")
    fmt.Println("  new           — новая игра")
    fmt.Println("  quit          — выход")
    fmt.Println("  open X Y      — открыть клетку (0≤X,Y≤3)")
    fmt.Println("  flag X Y      — поставить/снять флажок")

    scanner := bufio.NewScanner(os.Stdin)
    for {
        fmt.Print("> ")
        if !scanner.Scan() {
            break
        }
        line := scanner.Text()
        if line == "" {
            continue
        }
        conn.Write([]byte(line))
        conn.SetReadDeadline(time.Now().Add(5 * time.Second))
        buf := make([]byte, 4096)
        n, err := conn.Read(buf)
        if err != nil {
            fmt.Println("Read error:", err)
            continue
        }
        resp := string(buf[:n])
        fmt.Println(resp)
        if resp == "Goodbye!" {
            break
        }
    }
}
