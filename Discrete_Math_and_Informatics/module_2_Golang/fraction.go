package Fraction

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

func addFrac(a, b Fraction) Fraction {

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

func subFrac(a, b Fraction) Fraction {

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

func mulFrac(a, b Fraction) Fraction {

	var rez Fraction = Fraction{
		Numerator:   a.Numerator * b.Numerator,
		Denominator: a.Denominator * b.Denominator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}

func divFrac(a, b Fraction) Fraction {

	var rez Fraction = Fraction{
		Numerator:   a.Numerator * b.Denominator,
		Denominator: a.Denominator * b.Numerator,
	}

	NOD := gcd(rez.Numerator, rez.Denominator)
	rez.Numerator = rez.Numerator / NOD
	rez.Denominator = rez.Denominator / NOD

	return rez
}
