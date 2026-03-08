package main

import (
	"fmt"
	"math/rand"
	"time"
	"bufio"
	"os"
)

const (
	MIN = "\x00"
	MAX = "\xff\xff\xff\xff"
	P = 0.5
)

type AssocArray interface {
    Assign(s string, x int)
    Lookup(s string) (x int, exists bool)
}

type SkipNode struct {
	next, down *SkipNode
	val int
	key string
}

func makeSkipList() AssocArray {
	tail := &SkipNode{
		next: nil,
		down: nil,
		val: 0,
		key: MAX,
	}
	return &SkipNode{
		next: tail,
		down: nil,
		val: 0,
		key: MIN,
	}
}

func (SkipHead *SkipNode) Assign(s string, x int) {
	res := SkipHead.insert(s, x)
	if res != nil && cast() {
		tail := res;
		for ; tail.next != nil; tail = tail.next {}

		head := &SkipNode{
			next: SkipHead.next,
			down: SkipHead.down,
			val: SkipHead.val,
			key: SkipHead.key,
		}

		SkipTail := &SkipNode{
			next: nil,
			down: tail,
			val: 0,
			key: MAX,
		}
		new_node := &SkipNode{
			next: SkipTail,
			down: res,
			val: x,
			key: s,
		}
		SkipHead.next = new_node
		SkipHead.down = head
	}
}

func (SkipEl *SkipNode) insert(s string, x int) *SkipNode {
	el := SkipEl
	for ;el.next != nil && el.next.key < s; el = el.next {}

	if el.next != nil && el.next.key == s {
        el.next.val = x
        return nil
    }
	
	if el.down == nil {
		new_node := &SkipNode{
			next: el.next,
			down: nil,
			val: x,
			key: s,
		}
		el.next = new_node
		return new_node
	} else if res := el.down.insert(s, x); res != nil && cast() {
		new_node := &SkipNode{
			next: el.next,
			down : res,
			val: x,
			key: s,
		}
		el.next = new_node
		return new_node
	}
	return nil
}

func init() {
    rand.Seed(time.Now().UnixNano())
}

func cast() bool {
    return rand.Float64() - P >= 0
}

func (SkipHead *SkipNode) Lookup(s string) (x int, exists bool) {
	el := SkipHead
	for ;el.next != nil && el.next.key < s; el = el.next {}
	
	if el.next.key == s {
			return el.next.val, true
	}

	if el.down == nil {
		return 0, false
	}
	return el.down.Lookup(s)
}

// AVL TREE

type NodeAVL struct {
	key string
	val int
	height int
	left *NodeAVL
	right *NodeAVL
}

type AVLTree struct {
    root *NodeAVL
}

func getBFactor(p *NodeAVL) int {
	hL, hR := -1, -1
	if p.left != nil {
		hL = p.left.height
	}
	if p.right != nil {
		hR = p.right.height
	}
	return hR - hL
}

func setHeight(p *NodeAVL) {
	hL, hR := -1, -1
	if p.left != nil {
		hL = p.left.height
	}
	if p.right != nil {
		hR = p.right.height
	}
	if hL > hR {
		p.height = hL + 1
	} else {
		p.height = hR + 1
	}
}

func simpleRightTurn(p *NodeAVL) *NodeAVL {
	q := p.left
	p.left = q.right
	q.right = p

	setHeight(p)
	setHeight(q)

	return q
}

func simpleLeftTurn(q *NodeAVL) *NodeAVL {
	p := q.right
	q.right = p.left
	p.left = q

	setHeight(q)
	setHeight(p)

	return p
}

func balance(p *NodeAVL) *NodeAVL {
	setHeight(p)

	if getBFactor(p) == 2 {
		if getBFactor(p.right) < 0 {
			p.right = simpleRightTurn(p.right)
		}
		return simpleLeftTurn(p)
	}

	if getBFactor(p) == -2 {
		if getBFactor(p.left) > 0 {
			p.left = simpleLeftTurn(p.left)
		}
		return simpleRightTurn(p)
	}

	return p
}

func (p *NodeAVL) insertAVL(s string, x int) *NodeAVL {
	if p == nil {
		return &NodeAVL{
			key: s,
			val: x,
			height: 1,
			left: nil,
			right: nil,
		}
	}

	if s < p.key {
		p.left = p.left.insertAVL(s, x)
	} else if s > p.key {
		p.right = p.right.insertAVL(s, x)
	} else {
		p.val = x
		return p
	}

	return balance(p)
}

func lookupAVL(node *NodeAVL, s string) (int, bool) {
    if node == nil {
        return 0, false
    }
    if s == node.key {
        return node.val, true
    } else if s < node.key {
        return lookupAVL(node.left, s)
    } else {
        return lookupAVL(node.right, s)
    }
}

func (t *AVLTree) Assign(s string, x int) {
    t.root = t.root.insertAVL(s, x)
}

func (t *AVLTree) Lookup(s string) (int, bool) {
    return lookupAVL(t.root, s)
}

func makeAVL() AssocArray {
    return &AVLTree{}
}

func lex(sentence string, array AssocArray) []int {
	var (
		word string = ""
		cnt int = 1
	)
	rez := make([]int, 0)

	sentence += string(' ')
    for _, el := range sentence {
		if el == ' ' && word != "" {
			if x, exists := array.Lookup(word); exists {
				rez = append(rez, x)
			} else {
				array.Assign(word, cnt)
				rez = append(rez, cnt)
				cnt++
			}

			word = ""
		} else if el != ' ' {
			word += string(el)
		}
	}

	return rez
}

func main() {
	scanner := bufio.NewScanner(os.Stdin)
	scanner.Scan()
	frac_1 := scanner.Text()

	if cast() {
		for _, el := range lex(frac_1, makeSkipList()) {
			fmt.Print(el, " ")
		}
		fmt.Println()
	} else {
		for _, el := range lex(frac_1, makeAVL()) {
			fmt.Print(el, " ")
		}
		fmt.Println()
	}
}
