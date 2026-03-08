package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"
)

const port = "8002"

func getHostWithoutPort(r *http.Request) string {
	host := r.Host
	if strings.Contains(host, ":") {
		host = strings.Split(host, ":")[0]
	}
	return host
}

// Главная страница
func indexHandler(w http.ResponseWriter, r *http.Request) {
	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Главная страница</title>
</head>
<body>
    <h1>Добро пожаловать на главную страницу!</h1>
    <p>Вы находитесь на: %s</p>
    <ul>
        <li><a href="http://page1.shalimov.zzz.iu9.org.ru:%s">Page 1</a></li>
        <li><a href="http://page2.shalimov.zzz.iu9.org.ru:%s">Page 2</a></li>
        <li><a href="http://page3.shalimov.zzz.iu9.org.ru:%s">Page 3</a></li>
    </ul>
</body>
</html>`
	fmt.Fprintf(w, html, r.Host, port, port, port)
}

// Обработчик для страниц по поддоменам
func pageHandler(w http.ResponseWriter, r *http.Request, pageNum string) {
	html := `<!DOCTYPE html>
<html>
<head>
    <meta charset="UTF-8">
    <title>Page %s</title>
</head>
<body>
    <h1>Это Page %s</h1>
    <p>Вы находитесь на: %s</p>
    <p><a href="http://shalimov.zzz.iu9.org.ru:%s">Вернуться на главную</a></p>
    <p>Другие страницы:</p>
    <ul>
        <li><a href="http://page1.shalimov.zzz.iu9.org.ru:%s">Page 1</a></li>
        <li><a href="http://page2.shalimov.zzz.iu9.org.ru:%s">Page 2</a></li>
        <li><a href="http://page3.shalimov.zzz.iu9.org.ru:%s">Page 3</a></li>
    </ul>
</body>
</html>`
	fmt.Fprintf(w, html, pageNum, pageNum, r.Host, port, port, port, port)
}

// Главный обработчик
func mainHandler(w http.ResponseWriter, r *http.Request) {
	host := getHostWithoutPort(r)

	switch host {
	case "shalimov.zzz.iu9.org.ru":
		indexHandler(w, r)

	case "page1.shalimov.zzz.iu9.org.ru":
		pageHandler(w, r, "1")

	case "page2.shalimov.zzz.iu9.org.ru":
		pageHandler(w, r, "2")

	case "page3.shalimov.zzz.iu9.org.ru":
		pageHandler(w, r, "3")

	default:
		http.NotFound(w, r)
	}
}

func main() {
	http.HandleFunc("/", mainHandler)

	log.Printf("Server starting on :%s", port)
	log.Printf("Available URLs:")
	log.Printf("  http://shalimov.zzz.iu9.org.ru:%s", port)
	log.Printf("  http://page1.shalimov.zzz.iu9.org.ru:%s", port)
	log.Printf("  http://page2.shalimov.zzz.iu9.org.ru:%s", port)
	log.Printf("  http://page3.shalimov.zzz.iu9.org.ru:%s", port)

	log.Fatal(http.ListenAndServe(":"+port, nil))
}
