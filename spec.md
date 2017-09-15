# Lox Spec

[Link](http://www.craftinginterpreters.com/the-lox-language.html)

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

## MISC

- 全局变量允许重定义
- 赋值是一个表达式，而不是statement
- 为了和C实现兼容，函数参数个数最多为8个
- 函数隐式返回`nil`

## Dyanmic Typing

## Automatic Memory Management

## Data Types

- Boolean: `true` and `false`
- Number: 数字只支持双精度浮点数
- String: 字符串可以跨行
- Nil

## Expressions

- Arithemetic
- Comparision and Equality
- Logical operators: `and`, `or`, `!`

## Statements

## Variables

使用`var`定义变量，如果没有初始值，默认值为`nil`

## Control Flow

- `if`
- `while`
- `for`

## Functions

- 必须使用括号
- 函数如果没有显示`return`，那么则隐式返回`nil`

## Closures

- 函数是一等对象

## Classes

- 使用`className()`初始化实例
- 对象属性是动态添加的，对对象进行赋值即可添加属性
- 在方法内部，使用`this`访问对象
- 类的`init`方法负责执行初始化
- 使用`<`实现继承
- 使用`super`调用父类方法

## Lexical Grammer

- Identifier: `[a-zA-Z_][a-zA-Z_0-9]*`
- Number: `[0-9]+(\.[0-9]+)?`
