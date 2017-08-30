# Parsing Expressions

## Ambiguity

第五章的语法实际上是Ambiguous的，因为没有定义操作符的优先级(Precedence)和结合性(Associativity)。

下表定义了操作符的优先级，由高到低。

|      Name      |      Operators       | Associativity |
| :------------: | :------------------: | :-----------: |
|     Unary      |       `!`, `+`       |     Right     |
| Multiplication |       `*`, `/`       |     Left      |
|    Addition    |       `+`, `-`       |     Left      |
|   Comparison   | `>`, `>=`, `<`, `<=` |     Left      |
|    Equality    |      `==`, `!=`      |     Left      |

改进后的语法如下。

```text
expression -> equality
equality -> comparison ( ( "!=" | "==" ) comparison )*
comparison -> addition ( ( ">" | ">=" | "<" | "<=" ) addition )*
addition -> multiplication ( ( "-" | "+" ) multiplication )*
multiplication -> unary ( ( "*" | "/" ) unary)*
unary -> ( "!" | "-" ) unary | primary
primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")"
```
