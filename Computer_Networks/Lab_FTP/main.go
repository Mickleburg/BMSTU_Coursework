package main

import (
	"fmt"
	"io"
	"log"
	"net/http"
	"os"
	"strings"
	"sync"
	"time"

	"github.com/gorilla/websocket"
	"github.com/jlaffaye/ftp"
)

func getenv(key, def string) string {
	v := strings.TrimSpace(os.Getenv(key))
	if v == "" {
		return def
	}
	return v
}

var (
	addr = getenv("FTP_ADDR", "students.yss.su:21")
	user = getenv("FTP_USER", "ftpiu8")
	pass = getenv("FTP_PASS", "3Ru7yOTA")
)

func connect(addr, user, pass string) *ftp.ServerConn {
	c, err := ftp.Dial(addr, ftp.DialWithTimeout(5*time.Second))
	if err != nil {
		log.Fatalf("ftp dial error: %v", err)
	}
	if err := c.Login(user, pass); err != nil {
		log.Fatalf("ftp login error: %v", err)
	}
	return c
}

var (
	ftpMu sync.Mutex
	ftpC  *ftp.ServerConn
)

func mkdir(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("mkdir: empty path")
	}
	if err := c.MakeDir(path); err != nil {
		return "", err
	}
	return "OK", nil
}

func rmfile(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("rmfile: empty path")
	}
	if err := c.Delete(path); err != nil {
		return "", err
	}
	return "OK", nil
}

func ls(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		path = "."
	}

	entries, err := c.List(path)
	if err != nil {
		return "", err
	}

	var b strings.Builder
	for _, e := range entries {
		fmt.Fprintf(&b, "%s\n", e.Name)
	}
	return b.String(), nil
}

func cd(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("cd: empty path")
	}
	if err := c.ChangeDir(path); err != nil {
		return "", err
	}
	pwd, err := c.CurrentDir()
	if err != nil {
		return "", err
	}
	return pwd, nil
}

func rmdir(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("rmdir: empty path")
	}
	if err := c.RemoveDir(path); err != nil {
		return "", err
	}
	return "OK", nil
}

func rmdirRecur(c *ftp.ServerConn, path string) (string, error) {
	if path == "" {
		return "", fmt.Errorf("rmdirrecur: empty path")
	}
	if err := c.RemoveDirRecur(path); err != nil {
		return "", err
	}
	return "OK", nil
}

func runCommand(line string) (string, error) {
	parts := strings.Fields(line)
	if len(parts) == 0 {
		return "", fmt.Errorf("empty command")
	}
	op := parts[0]
	arg := ""
	if len(parts) > 1 {
		arg = parts[1]
	}

	switch op {
	case "mkdir":
		return mkdir(ftpC, arg)
	case "rmfile":
		return rmfile(ftpC, arg)
	case "ls":
		if arg == "" {
			arg = "."
		}
		return ls(ftpC, arg)
	case "cd":
		return cd(ftpC, arg)
	case "rmdir":
		return rmdir(ftpC, arg)
	case "rmdirrecur":
		return rmdirRecur(ftpC, arg)
	default:
		return "", fmt.Errorf("unknown op: %s", op)
	}
}

var upgrader = websocket.Upgrader{
	ReadBufferSize:  1024,
	WriteBufferSize: 1024,
	CheckOrigin:     func(r *http.Request) bool { return true },
}

func wsHandler(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("ws upgrade error:", err)
		return
	}
	defer conn.Close()

	_ = conn.WriteMessage(websocket.TextMessage, []byte("connected"))

	for {
		mt, msg, err := conn.ReadMessage()
		if err != nil {
			return
		}
		if mt != websocket.TextMessage {
			_ = conn.WriteMessage(websocket.TextMessage, []byte("ERROR: text messages only"))
			continue
		}

		line := strings.TrimSpace(string(msg))
		if line == "" {
			_ = conn.WriteMessage(websocket.TextMessage, []byte("ERROR: empty command"))
			continue
		}

		ftpMu.Lock()
		resp, cmdErr := runCommand(line)
		ftpMu.Unlock()

		if cmdErr != nil {
			resp = "ERROR: " + cmdErr.Error()
		}

		if err := conn.WriteMessage(websocket.TextMessage, []byte(resp)); err != nil {
			return
		}
	}
}

func apiCmdHandler(w http.ResponseWriter, r *http.Request) {
	if r.Method != http.MethodPost {
		http.Error(w, "POST only", http.StatusMethodNotAllowed)
		return
	}
	body, _ := io.ReadAll(r.Body)
	line := strings.TrimSpace(string(body))

	ftpMu.Lock()
	resp, err := runCommand(line)
	ftpMu.Unlock()

	if err != nil {
		http.Error(w, err.Error(), http.StatusBadRequest)
		return
	}
	w.Header().Set("Content-Type", "text/plain; charset=utf-8")
	_, _ = w.Write([]byte(resp))
}

func main() {
	if user == "" || pass == "" {
		log.Fatal("set env FTP_USER and FTP_PASS (and optionally FTP_ADDR)")
	}

	ftpC = connect(addr, user, pass)

	mux := http.NewServeMux()
	mux.HandleFunc("/ws", wsHandler)
	mux.HandleFunc("/api/cmd", apiCmdHandler)
	mux.HandleFunc("/", func(w http.ResponseWriter, r *http.Request) {
		w.Header().Set("Content-Type", "text/plain; charset=utf-8")
		_, _ = w.Write([]byte("OK. Use WebSocket: ws://localhost:8080/ws"))
	})

	log.Println("listen on :8080 (ws endpoint: /ws)")
	log.Fatal(http.ListenAndServe(":8080", mux))
}
