package main

import (
	"bytes"
	"fmt"
	"log"
	"net/http"
	"path"
	"regexp"
	"strings"
	"time"

	"github.com/gorilla/websocket"
	"golang.org/x/crypto/ssh"
)

var upgrader = websocket.Upgrader{
	CheckOrigin: func(r *http.Request) bool { return true },
}

// наше соединение
var sshConn *ssh.Client
var currentDir = "/"

// данные
const sshAddr = "95.81.121.63:22"
const sshUser = "root"
const sshPass = "nG648u1s03Sr"

var safePathRe = regexp.MustCompile(`^[a-zA-Z0-9._/\-]+$`)

func validateUserPath(p string) error {
	if p == "" {
		return fmt.Errorf("пустой путь")
	}
	if strings.Contains(p, "\x00") {
		return fmt.Errorf("NUL в пути запрещён")
	}
	if !safePathRe.MatchString(p) {
		return fmt.Errorf("запрещённые символы в пути (разрешены: a-zA-Z0-9 . _ - /)")
	}
	return nil
}

func shQuote(s string) string {
	return "'" + strings.ReplaceAll(s, "'", `'\''`) + "'"
}

func resolvePath(pth string) string {
	pth = strings.TrimSpace(pth)
	if pth == "" {
		return currentDir
	}
	if strings.HasPrefix(pth, "/") {
		return path.Clean(pth)
	}
	return path.Clean(path.Join(currentDir, pth))
}

func connectSSH() error {
	cfg := &ssh.ClientConfig{
		User:            sshUser,
		Auth:            []ssh.AuthMethod{ssh.Password(sshPass)},
		HostKeyCallback: ssh.InsecureIgnoreHostKey(),
		Timeout:         10 * time.Second,
	}

	var err error
	sshConn, err = ssh.Dial("tcp", sshAddr, cfg)
	if err != nil {
		return err
	}

	// Проверка соединения
	_, err = runRemote("true")
	if err != nil {
		_ = sshConn.Close()
		sshConn = nil
		return err
	}

	fmt.Println("SSH подключен")
	return nil
}

// проверяет соединение и переподключается если нужно
func ensureConnected() error {
	if sshConn == nil {
		fmt.Println("SSH соединение отсутствует, подключаемся...")
		return connectSSH()
	}

	_, err := runRemote("true")
	if err != nil {
		fmt.Println("SSH соединение потеряно, переподключаемся...")
		_ = sshConn.Close()
		sshConn = nil
		return connectSSH()
	}
	return nil
}

func runRemote(command string) (string, error) {
	session, err := sshConn.NewSession()
	if err != nil {
		return "", err
	}
	defer session.Close()

	var stdout bytes.Buffer
	var stderr bytes.Buffer

	session.Stdout = &stdout
	session.Stderr = &stderr

	err = session.Run(command)

	// Возвращаем stdout, даже если есть ошибка
	output := stdout.String()
	if err != nil && stderr.Len() > 0 {
		output += "\nSTDERR: " + stderr.String()
	}

	return output, err
}

// Выполнить команду в "текущей директории"
func runInCurrentDir(cmd string) (string, error) {
	full := "cd " + shQuote(currentDir) + " && " + cmd
	return runRemote(full)
}

func handleWebSocket(w http.ResponseWriter, r *http.Request) {
	conn, err := upgrader.Upgrade(w, r, nil)
	if err != nil {
		log.Println("WebSocket upgrade error:", err)
		return
	}
	defer conn.Close()

	for {
		_, message, err := conn.ReadMessage()
		if err != nil {
			log.Println("WebSocket read error:", err)
			break
		}

		cmd := strings.TrimSpace(string(message))
		response := processCommand(cmd)

		err = conn.WriteMessage(websocket.TextMessage, []byte(response))
		if err != nil {
			log.Println("WebSocket write error:", err)
			break
		}
	}
}

func processCommand(cmd string) string {
	if err := ensureConnected(); err != nil {
		return fmt.Sprintf("Ошибка переподключения к SSH: %v", err)
	}

	parts := strings.Fields(cmd)
	if len(parts) == 0 {
		return "Ошибка: пустая команда"
	}

	switch parts[0] {
	case "mkdir":
		return mkdir(parts)
	case "rm":
		return rm(parts)
	case "ls":
		return listDir()
	case "cd":
		return changeDir(parts)
	case "rmdir":
		return rmdir(parts)
	case "pwd":
		return pwd()
	default:
		return fmt.Sprintf("Неизвестная команда: %s", parts[0])
	}
}

func mkdir(parts []string) string {
	if len(parts) < 2 {
		return "Использование: mkdir <имя_директории>"
	}
	if err := validateUserPath(parts[1]); err != nil {
		return fmt.Sprintf("Ошибка: некорректный путь: %v", err)
	}

	p := resolvePath(parts[1])
	out, err := runRemote("mkdir -p -- " + shQuote(p))
	if err != nil {
		return fmt.Sprintf("Ошибка создания директории: %v\n%s", err, out)
	}
	return fmt.Sprintf("Директория '%s' создана", p)
}

func rm(parts []string) string {
	if len(parts) < 2 {
		return "Использование: rm <имя_файла>"
	}
	if err := validateUserPath(parts[1]); err != nil {
		return fmt.Sprintf("Ошибка: некорректный путь: %v", err)
	}

	p := resolvePath(parts[1])

	out, err := runRemote("rm -f -- " + shQuote(p))
	if err != nil {
		return fmt.Sprintf("Ошибка удаления файла: %v\n%s", err, out)
	}
	return fmt.Sprintf("Файл '%s' удален", p)
}


func listDir() string {
	// Выполняем ls
	cmd := fmt.Sprintf("cd %s && pwd && echo '---FILES---' && ls -1A", shQuote(currentDir))
	out, err := runRemote(cmd)

	if err != nil {
		return fmt.Sprintf("Ошибка при выполнении ls в '%s': %v\nВывод: %s", currentDir, err, out)
	}

	// Разбираем вывод
	lines := strings.Split(strings.TrimSpace(out), "\n")

	if len(lines) < 2 {
		return fmt.Sprintf("Ошибка: неожиданный вывод команды ls:\n%s", out)
	}

	actualDir := lines[0]

	// Ищем разделитель
	filesStartIdx := -1
	for i, line := range lines {
		if strings.Contains(line, "---FILES---") {
			filesStartIdx = i + 1
			break
		}
	}

	if filesStartIdx == -1 || filesStartIdx >= len(lines) {
		return fmt.Sprintf("Директория %s пустая", actualDir)
	}

	// Получаем список файлов
	filesList := lines[filesStartIdx:]

	if len(filesList) == 0 || (len(filesList) == 1 && strings.TrimSpace(filesList[0]) == "") {
		return fmt.Sprintf("Директория %s пустая", actualDir)
	}

	return fmt.Sprintf("Содержимое %s:\n%s", actualDir, strings.Join(filesList, "\n"))
}

func changeDir(parts []string) string {
	if len(parts) < 2 {
		return "Использование: cd <директория>"
	}
	if err := validateUserPath(parts[1]); err != nil {
		return fmt.Sprintf("Ошибка: некорректный путь: %v", err)
	}

	p := resolvePath(parts[1])

	// Проверяем что это директория И получаем реальный путь
	cmd := fmt.Sprintf("cd %s && pwd", shQuote(p))
	out, err := runRemote(cmd)

	if err != nil {
		return fmt.Sprintf("Ошибка: '%s' не является директорией или недоступна: %v", p, err)
	}

	// Обновляем currentDir на реальный путь, который вернул pwd
	realPath := strings.TrimSpace(out)
	if realPath != "" {
		currentDir = realPath
	} else {
		currentDir = p
	}

	return fmt.Sprintf("Перешли в директорию: %s", currentDir)
}

func rmdir(parts []string) string {
	if len(parts) < 2 {
		return "Использование: rmdir <директория> или rmdir -r <директория>"
	}

	if parts[1] == "-r" {
		if len(parts) < 3 {
			return "Использование: rmdir -r <директория>"
		}
		if err := validateUserPath(parts[2]); err != nil {
			return fmt.Sprintf("Ошибка: некорректный путь: %v", err)
		}

		p := resolvePath(parts[2])
		out, err := runRemote("rm -rf -- " + shQuote(p))
		if err != nil {
			return fmt.Sprintf("Ошибка рекурсивного удаления '%s': %v\n%s", p, err, out)
		}
		return fmt.Sprintf("Директория '%s' и её содержимое успешно удалены", p)
	}

	if err := validateUserPath(parts[1]); err != nil {
		return fmt.Sprintf("Ошибка: некорректный путь: %v", err)
	}

	p := resolvePath(parts[1])
	out, err := runRemote("rmdir -- " + shQuote(p))
	if err != nil {
		return fmt.Sprintf("Ошибка удаления пустой директории '%s': %v\n%s", p, err, out)
	}
	return fmt.Sprintf("Пустая директория '%s' удалена", p)
}

// Новая функция для отладки
func pwd() string {
	out, err := runInCurrentDir("pwd")
	if err != nil {
		return fmt.Sprintf("Ошибка получения текущей директории: %v", err)
	}
	return fmt.Sprintf("Текущая директория: %s\nСохраненная: %s", strings.TrimSpace(out), currentDir)
}

func main() {
	err := connectSSH()
	if err != nil {
		log.Fatalf("Ошибка SSH подключения: %v", err)
	}
	defer func() {
		if sshConn != nil {
			_ = sshConn.Close()
		}
	}()

	http.HandleFunc("/ws", handleWebSocket)

	fmt.Println("Сервер запущен на :8080")
	log.Fatal(http.ListenAndServe(":8080", nil))
}
