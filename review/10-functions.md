# Functions

## 加入函数调用语法

```plain
unary -> ( "!" | "-" ) unary | call
call -> primary ( "(" arguments? ")" )*
arguments -> expression ( "," expression )*
```

## 加入函数声明语法

```plain
declaration -> funcDecl | varDecl | statement
funcDecl -> "func" function
function -> IDENTIFIER "(" parameters? ")" block
parameters -> IDENTIFIER ( "," IDENTIFIER )*
```

## 加入函数返回语法

```plain
statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt | returnStmt
returnStmt -> "return" expression? ";"
```
