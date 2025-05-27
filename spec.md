# Lox Spec

- [The Lox Language in www.craftinginterpreters.com](http://www.craftinginterpreters.com/the-lox-language.html)

## Overall

- dyanmic typing
- has **statements** and **expressions**, an expression’s main job is to produce a value, a statement’s job is to produce an effect.
- assignment is an expression rather than a statement
- global variables can be redifined
- automatic Memory Management

## Data Types

- boolean: `true` and `false`
- number: only IEEE754 double float
- string: multi line string is allowed
- nil

## Expressions & Statements

- Expressions
  - Arithemetic
  - Comparision and Equality
  - Logical operators: `and`, `or`, `!`
- Statements
  - Statements don’t evaluate to a value, to be useful they have to otherwise change the world in some way
  - An expression followed by a semicolon (;) promotes the expression to statement-hood. This is called (imaginatively enough), an **expression statement**.
  - We can pack multiple statements in a **block**.

## Variables & Control Flow

- use `var` to define a variable, default value is `nil`
- control flow
  - `if`
  - `while`
  - `for`

### Functions && Closures

- functions
  - define function with `fun`
  - call function using `function()`
  - the body of a function is always a block, if no `return` found, `nil` is implicitly returned
  - to be compatible with C, function params must <= 8
- Closures
  - functons are first class

### Classes

- Just like functions, classes are first class in Lox
- class itself is a factory function for instances. Call a class like a function, and it produces a new instance of itself
- Assigning to a field creates it if it doesn’t already exist in the object
- special class method `init` to the initialization
- single inheritance use `<`
- use `super` to call methods in parent class

## Standard Library

- built-in `print` statement
- built-in function `clock`

## Operators

|      Name      |      Operators       | Associativity |
| :------------: | :------------------: | :-----------: |
|     Unary      |       `!`, `+`       |     Right     |
| Multiplication |       `*`, `/`       |     Left      |
|    Addition    |       `+`, `-`       |     Left      |
|   Comparison   | `>`, `>=`, `<`, `<=` |     Left      |
|  Logical And   |        `and`         |     Left      |
|   Logical Or   |         `or`         |     Left      |
|    Equality    |      `==`, `!=`      |     Left      |


## Grammer

- Lexical Rules
  - Identifier: `[a-zA-Z_][a-zA-Z_0-9]*`
  - Number: `[0-9]+(\.[0-9]+)?`

```text
program -> declaration* EOF
declaration -> funcDecl | varDecl | statement
funcDecl -> "func" function
function -> IDENTIFIER "(" arguments? ")" block
parameters -> IDENTIFIER ( "," IDENTIFIER )*
varDecl -> "var" IDENTIFIER ("=" expression)? ";"
statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt
forStmt -> "for" "(" ( varDecl | exprStmt | ";" )
                      expression? ";"
                      expression? ")" statement
whileStmt -> "while" "(" expression ")" statement
ifStmt -> "if" "(" expression ")" statement ( "else" statement )?
block -> "{" declaration* "}"
exprStmt -> expression ";"
printStmt -> "print" expression ";"
expression -> assignment
assignment -> IDENTIFIER "=" assignment | equality
equality -> comparison ( ( "!=" | "==" ) comparison )*
comparison -> addition ( ( ">" | ">=" | "<" | "<=" ) addition )*
addition -> multiplication ( ( "-" | "+" ) multiplication )*
multiplication -> unary ( ( "*" | "/" ) unary)*
unary -> ( "!" | "-" ) unary | call
call -> primary ( "(" arguments? ")" )*
arguments -> expression ( "," expression )*
primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")" | IDENTIFIER
```
