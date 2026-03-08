package main

import (
	"fmt"
	"os"
	"bufio"
	"strings"
)

func Del_Sep(stream *bufio.Reader) {
	for {
		char, err := stream.Peek(1)
		if err != nil || char[0] != ' ' {
			break
		}
		stream.ReadByte()
	}
}

func Parse_Expr(stream *bufio.Reader) int {
	Del_Sep(stream)
	char, err := stream.Peek(1)
	if err != nil {
		panic("неожиданный конец ввода")
	}
	c := char[0]

	if c >= '0' && c <= '9' {
		stream.ReadByte()
		return int(c - '0')
	}

	if c == '(' {
		stream.ReadByte()
		Del_Sep(stream)
		op, err := stream.ReadByte()
		if err != nil {
			panic("неожиданный конец ввода")
		}

		Del_Sep(stream)
		left := Parse_Expr(stream)
		Del_Sep(stream)
		right := Parse_Expr(stream)
		Del_Sep(stream)

		if char, _ := stream.ReadByte(); char != ')' {
			panic("ожидалась закрывающая скобка")
		}

		switch op {
		case '+':
			return left + right
		case '-':
			return left - right
		case '*':
			return left * right
		default:
			panic("неизвестный оператор: " + string(op))
		}
	}

	panic("неожиданный символ: " + string(c))
}

func main() {
	reader := bufio.NewReader(os.Stdin)

	expression, err := reader.ReadString('\n')
	if err != nil {
		panic("ошибка при чтении ввода")
	}

	stream := bufio.NewReader(strings.NewReader(expression))
	result := Parse_Expr(stream)
	fmt.Println(result)
}