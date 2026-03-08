package main

import (
	"fmt"
	"log"
	"net/http"
	"strings"

	"github.com/mmcdole/gofeed"
)

func HomeRouterHandler(w http.ResponseWriter, r *http.Request) {
	r.ParseForm()
	/*
		fmt.Println(r.Form)
		fmt.Println("path", r.URL.Path)
		fmt.Println("scheme", r.URL.Scheme)
		fmt.Println(r.Form["url_long"])
	*/
	for k, v := range r.Form {
		fmt.Println("key:", k)
		fmt.Println("val:", strings.Join(v, ""))
	}

	url := "http://www.msk-times.ru/feed.php"

	fp := gofeed.NewParser()

	feed, err := fp.ParseURL(url)
	if err != nil {
		log.Fatal("Ошибка при парсинге rss:", err)
	}

	// заголовок
	w.Header().Set("Content-Type", "text/html; charset=utf-8")

	// наша страница
	fmt.Fprintf(w, "<!DOCTYPE html>")
	fmt.Fprintf(w, "<html>")
	fmt.Fprintf(w, "<body>")

	fmt.Fprintf(w, "<h1>%s</h1>\n", feed.Title)
	fmt.Fprintf(w, "<p>%s</p>\n", feed.Description)
	fmt.Fprintf(w, "<hr>")

	for _, item := range feed.Items {
		fmt.Fprintf(w, "<p><b>%s</b></p>\n", item.Title)

		content := item.Content
		if content == "" {
			content = item.Description
		}

		fmt.Fprintf(w, "<p>%s</p>\n", content)

		fmt.Fprintf(w, "<p><a href='%s'>ПОДРОБНЕЕ</a></p>\n", item.Link)

		fmt.Fprintf(w, "<hr>")
	}

	fmt.Fprintf(w, "</body>")
	fmt.Fprintf(w, "</html>")
}

func main() {
	http.HandleFunc("/", HomeRouterHandler)
	err := http.ListenAndServe(":9000", nil)
	if err != nil {
		log.Fatal("ListenAndServe: ", err)
	}
}
