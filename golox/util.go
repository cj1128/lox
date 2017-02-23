/*
* @Author: CJ Ting
* @Date: 2017-02-23 16:06:28
* @Email: fatelovely1128@gmail.com
 */

package main

func isDigit(r rune) bool {
	return r >= '0' && r <= '9'
}

func isAlpha(c rune) bool {
	return (c >= 'a' && c <= 'z') ||
		(c >= 'A' && c <= 'Z') ||
		c == '_'
}

func isAlphaNumeric(c rune) bool {
	return isAlpha(c) || isDigit(c)
}
