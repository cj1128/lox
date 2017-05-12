# Representing Code

## Basic Grammer

```text
expression -> literal 
            | unary
            | binary
            | grouping
literal -> NUMBER | STRING | "true" | "false" | "nil"
grouping -> "(" expresson ")"
unary -> ( "-" | "!" ) expression
binary -> expression operator expression
operator -> "==" | "!=" | "<" | ">" | "<=" | ">=" | "+" | "-" | "*" | "/"
```
