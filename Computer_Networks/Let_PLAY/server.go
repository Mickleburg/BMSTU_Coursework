package main

import (
    "fmt"
    "math/rand"
    "net"
    "os"
    "strconv"
    "strings"
    "sync"
    "time"
)

const (
    width      = 4
    height     = 4
    minesCount = 4
)

type GameState struct {
    mines   map[string]bool
    opened  map[string]bool
    flagged map[string]bool
    lost    bool
    won     bool
}

var (
    games   = make(map[string]*GameState)
    gamesMu sync.Mutex
)

func cellKey(x, y int) string {
    return fmt.Sprintf("%d,%d", x, y)
}

func newGame() *GameState {
    gs := &GameState{
        mines:   make(map[string]bool),
        opened:  make(map[string]bool),
        flagged: make(map[string]bool),
    }
    perm := rand.Perm(width * height)
    for i := 0; i < minesCount; i++ {
        idx := perm[i]
        x := idx % width
        y := idx / width
        gs.mines[cellKey(x, y)] = true
    }
    return gs
}

func countMines(gs *GameState, x, y int) int {
    cnt := 0
    for dx := -1; dx <= 1; dx++ {
        for dy := -1; dy <= 1; dy++ {
            nx, ny := x+dx, y+dy
            if nx>=0 && nx<width && ny>=0 && ny<height {
                if gs.mines[cellKey(nx, ny)] {
                    cnt++
                }
            }
        }
    }
    return cnt
}

func floodOpen(gs *GameState, x, y int) {
    key := cellKey(x, y)
    if gs.opened[key] || gs.flagged[key] {
        return
    }
    gs.opened[key] = true
    if countMines(gs, x, y) != 0 {
        return
    }
    for dx := -1; dx <= 1; dx++ {
        for dy := -1; dy <= 1; dy++ {
            nx, ny := x+dx, y+dy
            if nx>=0 && nx<width && ny>=0 && ny<height {
                floodOpen(gs, nx, ny)
            }
        }
    }
}

func checkWin(gs *GameState) bool {
    // все безопасные клетки открыты
    return len(gs.opened) == width*height - minesCount
}

func render(gs *GameState) string {
    var sb strings.Builder
    sb.WriteString("   ")
    for x := 0; x < width; x++ {
        sb.WriteString(fmt.Sprintf(" %d ", x))
    }
    sb.WriteString("\n")
    for y := 0; y < height; y++ {
        sb.WriteString(fmt.Sprintf(" %d ", y))
        for x := 0; x < width; x++ {
            key := cellKey(x, y)
            ch := "."
            if gs.lost && gs.mines[key] {
                ch = "*"
            } else if gs.opened[key] {
                cnt := countMines(gs, x, y)
                ch = fmt.Sprintf("%d", cnt)
            } else if gs.flagged[key] {
                ch = "F"
            }
            sb.WriteString(" " + ch + " ")
        }
        sb.WriteString("\n")
    }
    if gs.lost {
        sb.WriteString("BOOM! Вы подорвались.\nType NEW to start again.\n")
    } else if gs.won {
        sb.WriteString("CONGRATS! Вы обезвредили все мины.\nType NEW to start again.\n")
    } else {
        sb.WriteString("Commands: open X Y | flag X Y | new | quit\n")
    }
    return sb.String()
}

func handleRequest(msg string, addr *net.UDPAddr) string {
    key := addr.String()

    gamesMu.Lock()
    gs, ok := games[key]
    if !ok {
        gs = newGame()
        games[key] = gs
        gamesMu.Unlock()
        return "New game started!\n" + render(gs)
    }
    gamesMu.Unlock()

    parts := strings.Fields(strings.ToLower(strings.TrimSpace(msg)))
    if len(parts) == 0 {
        return render(gs)
    }

    cmd := parts[0]
    switch cmd {
    case "new":
        gamesMu.Lock()
        gs = newGame()
        games[key] = gs
        gamesMu.Unlock()
        return "New game started!\n" + render(gs)

    case "quit":
        gamesMu.Lock()
        delete(games, key)
        gamesMu.Unlock()
        return "Goodbye!"

    case "open", "flag":
        if len(parts) != 3 {
            return "Usage: open X Y   or   flag X Y\n" + render(gs)
        }
        x, err1 := strconv.Atoi(parts[1])
        y, err2 := strconv.Atoi(parts[2])
        if err1!=nil || err2!=nil || x<0 || x>=width || y<0 || y>=height {
            return "Bad coordinates.\n" + render(gs)
        }
        cell := cellKey(x, y)
        if cmd == "flag" {
            if !gs.opened[cell] {
                if gs.flagged[cell] {
                    delete(gs.flagged, cell)
                } else {
                    gs.flagged[cell] = true
                }
            }
        } else { // open
            if !gs.flagged[cell] && !gs.opened[cell] {
                if gs.mines[cell] {
                    gs.lost = true
                } else {
                    floodOpen(gs, x, y)
                    if checkWin(gs) {
                        gs.won = true
                    }
                }
            }
        }
        return render(gs)

    default:
        return "Unknown command.\n" + render(gs)
    }
}

func main() {
    rand.Seed(time.Now().UnixNano())
    addr, err := net.ResolveUDPAddr("udp", ":8080")
    if err != nil {
        fmt.Println("ResolveUDPAddr:", err)
        os.Exit(1)
    }
    conn, err := net.ListenUDP("udp", addr)
    if err != nil {
        fmt.Println("ListenUDP:", err)
        os.Exit(1)
    }
    defer conn.Close()
    fmt.Println("Minesweeper 4×4 UDP server on :8080")

    buf := make([]byte, 2048)
    for {
        n, clientAddr, err := conn.ReadFromUDP(buf)
        if err != nil {
            fmt.Println("ReadFromUDP:", err)
            continue
        }
        msg := string(buf[:n])
        fmt.Printf("[%s] %s\n", clientAddr, msg)
        resp := handleRequest(msg, clientAddr)
        conn.WriteToUDP([]byte(resp), clientAddr)
    }
}
