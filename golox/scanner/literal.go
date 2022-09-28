package scanner

import "strconv"

type Number = float64

func parseStringLiteral(input string) string {
	return input
}

func parseNumberLiteral(input string) (Number, error) {
	return strconv.ParseFloat(input, 64)
}
