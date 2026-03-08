package main

import (
	"fmt"
	"log"

	"github.com/mmcdole/gofeed"
)

func main() {
	url := "http://www.msk-times.ru/feed.php"

	fp := gofeed.NewParser()

	feed, err := fp.ParseURL(url)
	if err != nil {
		log.Fatal("Ошибка при парсинге rss:", err)
	}

	fmt.Println("<!DOCTYPE html>")
	fmt.Println("<html>")
	fmt.Println("<body>")

	fmt.Printf("<h1>%s</h1>\n", feed.Title)
	fmt.Printf("<p>%s</p>\n", feed.Description)
	fmt.Printf("<p>Последнее обновление: %s</p>\n", feed.Updated)
	fmt.Println("<hr>")

	for _, item := range feed.Items {
		fmt.Printf("<p><b>%s</b></p>\n", item.Title)

		fmt.Printf("<p>Дата: %s</p>\n", item.Published)

		content := item.Content
		if content == "" {
			content = item.Description
		}

		if len(content) > 200 {
			content = content[:200] + "..."
		}
		fmt.Printf("<p>%s</p>\n", content)

		fmt.Printf("<p><a href='%s'>ПОДРОБНЕЕ</a></p>\n", item.Link)

		fmt.Println("<hr>")
	}

	fmt.Println("</body>")
	fmt.Println("</html>")
}
