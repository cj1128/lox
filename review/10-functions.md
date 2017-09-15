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
