package main

import (
	"fmt"
	"math"
)

type Fraction struct {
	Numerator   int
	Denominator int
}

func gcd(a, b int) int {
	if b == 0 {
		return a
	}
	return gcd(b, a%b)
}

func get_standard_view(a Fraction) Fraction {
	if a.Numerator * a.Denominator >= 0 {
		return Fraction{
			Numerator: int(math.Abs(float64(a.Numerator))),
			Denominator: int(math.Abs(float64(a.Denominator))),
		}
	}
	return Fraction{
		Numerator: -int(math.Abs(float64(a.Numerator))),
		Denominator: int(math.Abs(float64(a.Denominator))),
	}
}

func (a Fraction) Add(b Fraction) Fraction {

	if a.Denominator == b.Denominator {
		return Fraction{
			Numerator:   a.Numerator + b.Numerator,
			Denominator: a.Denominator,
		}
	}

	var rez Fraction = Fraction{
		Numerator:   a.Numerator*b.Denominator + b.Numerator*a.Denominator,
		Denominator: a.Denominator * b.Denominator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}

func (a Fraction) Sub(b Fraction) Fraction {

	if a.Denominator == b.Denominator {
		return Fraction{
			Numerator:   a.Numerator - b.Numerator,
			Denominator: a.Denominator,
		}
	}

	var rez Fraction = Fraction{
		Numerator:   a.Numerator*b.Denominator - b.Numerator*a.Denominator,
		Denominator: a.Denominator * b.Denominator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}

func (a Fraction) Mul(b Fraction) Fraction {

	var rez Fraction = Fraction{
		Numerator:   a.Numerator * b.Numerator,
		Denominator: a.Denominator * b.Denominator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}

func (a Fraction) Div(b Fraction) Fraction {

	var rez Fraction = Fraction{
		Numerator:   a.Numerator * b.Denominator,
		Denominator: a.Denominator * b.Numerator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}

func (a Fraction) Simplify() Fraction {

	NOD := gcd(a.Numerator, a.Denominator)
	a.Numerator = a.Denominator / NOD
	a.Denominator = a.Numerator / NOD

	return a
}

func (a Fraction) Get_Str() string {
	return fmt.Sprintf("%d / %d", a.Numerator, a.Denominator)
}

func Get_Str(a Fraction) string {
	a = get_standard_view(a)

	return fmt.Sprintf("%d/%d", a.Numerator, a.Denominator)
}

func Not_Null(a Fraction) bool {
	return a.Numerator != 0
}

func Part_Zero(row []Fraction, ind int) bool {
	for i := 0; i < ind; i++ {
		if Not_Null(row[i]) {
			return false
		}
	}
	return true
}

func Reset_El(sample, modify []Fraction, ind, N int) []Fraction {
	var factor Fraction = modify[ind].Div(sample[ind])
	for i := ind; i < N+1; i++ {
		modify[i] = modify[i].Sub(sample[i].Mul(factor))
	}
	return modify
}

func main() {
	//Ввод матрицы
	var N int
	fmt.Scan(&N)

	matrix := make([][]Fraction, N)
	for i := 0; i < N; i++ {

		matrix[i] = make([]Fraction, N+1)

		for j := 0; j < N+1; j++ {
			var Num int
			fmt.Scan(&Num)

			matrix[i][j] = Fraction{
				Numerator:   Num,
				Denominator: 1,
			}
		}
	}

	//Сведение матрицы к диагональному виду

	for j := 0; j < N; j++ {
		for i := 0; i < N; i++ {

			//Наш эл-т не нулевой, а перед ним все нули => подходит
			if Not_Null(matrix[i][j]) && Part_Zero(matrix[i], j) {

				//fmt.Println("IF", matrix[i], matrix[i][j], i, j)

				//Теперь зануляем эл-ты из других строк с того же столбца
				for iw := 0; iw < N; iw++ {
					if iw != i {
						//fmt.Println("IW", iw, i, matrix[iw])
						matrix[iw] = Reset_El(matrix[i], matrix[iw], j, N)
					}
				}

				//все получилось - идем к след. столбцу
				break
			}
		}
	}

	solution := true

	//Если есть нулевая строка с ненулевым свободным членом - решений нет
	for i := 0; i < N; i++ {
		if Not_Null(matrix[i][N]) && Part_Zero(matrix[i], N) {
			solution = false
		}
	}

	//Проходим по матрице и поочерёдно выдаем решение
	for j := 0; j < N; j++ {
		for i := 0; i < N; i++ {
			if Not_Null(matrix[i][j]) && solution {
				solution = true
				fmt.Println(Get_Str(matrix[i][N].Div(matrix[i][j])))
				break
			}
		}
	}

	if ! solution {
		fmt.Println("No solution")
	}
}
