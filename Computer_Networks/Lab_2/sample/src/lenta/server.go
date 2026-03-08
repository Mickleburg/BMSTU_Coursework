package main

import (
	"html/template"
	"net/http"

	log "github.com/mgutz/logxi/v1"
)

const INDEX_HTML = `
<!doctype html>
<html lang="ru">
<head>
    <meta charset="utf-8">
    <title>Темы с форума ecigtalk.org → раздел «Отзывы, обзоры, сравнение»</title>
    <style>
        body { font-family: Arial, sans-serif; padding: 20px; line-height: 1.6; }
        a { color: #0066cc; text-decoration: none; }
        a:hover { text-decoration: underline; }
        .item { margin: 8px 0; }
    </style>
</head>
<body>
    <h1>Темы форума ecigtalk.org (раздел f14)</h1>
    {{if .}}
        {{range .}}
            <div class="item">
                <a href="https://www.ecigtalk.org{{.Ref}}" target="_blank">{{.Title}}</a>
            </div>
        {{end}}
    {{else}}
        <p style="color: red;"> Не удалось загрузить темы.</p>
    {{end}}
</body>
</html>
`

var indexTmpl = template.Must(template.New("index").Parse(INDEX_HTML))

func serveClient(w http.ResponseWriter, r *http.Request) {
	log.Info("request received", "method", r.Method, "path", r.URL.Path)

	if r.URL.Path != "/" && r.URL.Path != "/index.html" {
		log.Warn("404 not found", "path", r.URL.Path)
		http.NotFound(w, r)
		return
	}

	items := downloadNews()
	if err := indexTmpl.Execute(w, items); err != nil {
		log.Error("failed to execute template", "error", err)
		http.Error(w, "Internal Server Error", http.StatusInternalServerError)
		return
	}

	log.Info("response sent successfully", "items_count", len(items))
}

func main() {
	http.HandleFunc("/", serveClient)

	log.Info("starting HTTP server", "addr", "http://127.0.0.1:6060")
	err := http.ListenAndServe("127.0.0.1:6060", nil)
	if err != nil {
		log.Error("server stopped with error", "error", err)
	}
}
