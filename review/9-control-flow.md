# Control Flow

## 增加If语法

```plain
statement -> exprStmt | printStmt | block | ifStmt
ifStmt -> "if" "(" expression ")" statement ("else" statement)? 
```

## 增加逻辑操作符语法

```plain
assignment -> IDENTIFIER "=" assignment | logic_or
logic_or -> logic_and ( "or" logic_and )*
logic_and -> equality ( "and" equality )*
```

## 增加While语法

```plain
statement -> exprStmt | printStmt | block | ifStmt | whileStmt
whileStmt -> "while" "(" expression ")" statement
```

## 增加For语法

```plain
statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt
forStmt -> "for" "(" ( varDecl | exprStmt | ";" )
                      expression? ";"
                      expression? ")" statement
```
