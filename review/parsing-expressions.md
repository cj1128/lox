# Parsing Expressions



## Precedence and Associativity

|    Name     |     Operators     | Associates |
| :---------: | :---------------: | :--------: |
|    Unary    |      `!` `-`      |   Right    |
|   Factor    |      `/` `*`      |    Left    |
|    Term     |      `-` `+`      |    Left    |
| Comparision | `>` `>=` `<` `<=` |    Left    |
|  Equality   |     `==` `!=`     |    Left    |

## Unambiguous Grammer 

```text
primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")"
unary -> ( "!" | "-" ) unary | primary
factor -> unary ( ( "/" | "*" ) unary )*
term -> factor ( ( "-" | "+" ) factor )*
comparision -> term ( ( ">" | ">=" | "<" | "<=" ) term )*
equality -> comparision ( ( "==" | "!=" ) comparision )*
expression -> equality
```
