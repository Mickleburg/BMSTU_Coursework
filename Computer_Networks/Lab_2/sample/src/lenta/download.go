package main

import (
	"net/http"
	"strings"

	log "github.com/mgutz/logxi/v1"
	"golang.org/x/net/html"
)

func getAttr(node *html.Node, key string) string {
	for _, attr := range node.Attr {
		if attr.Key == key {
			return attr.Val
		}
	}
	return ""
}

func isElem(node *html.Node, tag string) bool {
	return node != nil && node.Type == html.ElementNode && node.Data == tag
}

func isText(node *html.Node) bool {
	return node != nil && node.Type == html.TextNode
}

func findLinkInNode(n *html.Node) *html.Node {
	if isElem(n, "a") && getAttr(n, "class") == "title" {
		return n
	}
	for c := n.FirstChild; c != nil; c = c.NextSibling {
		if found := findLinkInNode(c); found != nil {
			return found
		}
	}
	return nil
}

func extractText(node *html.Node) string {
	if node == nil {
		return ""
	}
	var result strings.Builder
	var collect func(*html.Node)
	collect = func(n *html.Node) {
		if isText(n) {
			result.WriteString(n.Data)
		}
		for c := n.FirstChild; c != nil; c = c.NextSibling {
			collect(c)
		}
	}
	collect(node)
	return strings.TrimSpace(result.String())
}

type Item struct {
	Ref, Title string
}

func readItem(liNode *html.Node) *Item {
	linkNode := findLinkInNode(liNode)
	if linkNode == nil {
		return nil
	}

	ref := getAttr(linkNode, "href")
	title := extractText(linkNode)

	// Приводим ref к чистому относительному пути
	if strings.HasPrefix(ref, "https://www.ecigtalk.org") {
		ref = strings.TrimPrefix(ref, "https://www.ecigtalk.org")
	}
	if strings.HasPrefix(ref, "http://www.ecigtalk.org") {
		ref = strings.TrimPrefix(ref, "http://www.ecigtalk.org")
	}

	// Убираем возможные дубли слешей в начале
	ref = strings.TrimPrefix(ref, "/")
	ref = "/" + ref

	return &Item{
		Ref:   ref,
		Title: title,
	}
}

func search(node *html.Node) []*Item {
	if isElem(node, "ol") && getAttr(node, "id") == "threads" {
		var items []*Item
		for c := node.FirstChild; c != nil; c = c.NextSibling {
			if isElem(c, "li") && strings.Contains(getAttr(c, "class"), "threadbit") {
				if item := readItem(c); item != nil {
					items = append(items, item)
				}
			}
		}
		return items
	}

	for c := node.FirstChild; c != nil; c = c.NextSibling {
		if items := search(c); items != nil {
			return items
		}
	}
	return nil
}

func downloadNews() []*Item {
	log.Info("sending request to ecigtalk.org")

	client := &http.Client{}
	req, err := http.NewRequest("GET", "https://www.ecigtalk.org/forum/f14/", nil)
	if err != nil {
		log.Error("failed to create request", "error", err)
		return nil
	}
	req.Header.Set("User-Agent", "Mozilla/5.0 (compatible; GoLentaBot/1.0; +https://github.com/username/lenta)")

	resp, err := client.Do(req)
	if err != nil {
		log.Error("request to ecigtalk.org failed", "error", err)
		return nil
	}
	defer resp.Body.Close()

	if resp.StatusCode != http.StatusOK {
		log.Error("unexpected status code", "status", resp.StatusCode)
		return nil
	}

	log.Info("got response from ecigtalk.org", "status", resp.StatusCode)

	doc, err := html.Parse(resp.Body)
	if err != nil {
		log.Error("failed to parse HTML", "error", err)
		return nil
	}

	log.Info("HTML parsed successfully")
	return search(doc)
}
