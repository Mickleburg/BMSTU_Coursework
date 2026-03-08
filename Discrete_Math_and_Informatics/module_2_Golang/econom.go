package main

import (
	"fmt"
)

type Stream struct {
	str []rune
	pos int
}

func NewStream(str string) *Stream{
	return &Stream{
		str: []rune(str),
		pos: 0,
	}
}

func (S *Stream) Peek() (rune, bool) {
	if S.pos >= len(S.str) {
		return 0, false
	}
	return S.str[S.pos], true
}

func (S *Stream) Read() (string, bool) {
	if S.pos >= len(S.str) {
		return "", false
	}
	S.pos++

	return string(S.str[S.pos - 1]), true
}

func check(dict *[]string, str string) bool {
	for _, s := range *dict {
		if s == str {
			return true
		}
	}
	return false
}

func parseFrac(stream *Stream, dict *[]string) (int, string) {
	if c, _ := stream.Peek(); c == '(' {
		stream.Read()

		op, _ := stream.Read()
		cnt_1, left := parseFrac(stream, dict)
		cnt_2, right := parseFrac(stream, dict)
		cnt, exp := cnt_1 + cnt_2, "("+op+left+right+")"

		if ! check(dict, exp) {
			cnt++
			*dict = append(*dict, exp)
		}

		stream.Read()

		return cnt, exp
	}
	c, _ := stream.Read()
	return 0, c
}

func main() {
	var str string
	fmt.Scan(&str)

	dict := make([]string, 1)

	cnt, _ := parseFrac(NewStream(str), &dict)
	fmt.Println(cnt)
}