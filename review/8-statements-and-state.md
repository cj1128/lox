# Statements and State

## 增加Statement语法

```plain
program -> statement* EOF
statement -> exprStmt | printStmt
exprStmt -> expression ";"
printStmt -> "print" expression ";"
```

## 增加变量声明语法

```plain
program -> declaration* EOF
declaration -> varDecl | statement
varDecl -> "var" IDENTIFIER ("=" expression)? ";"
```

## 增加赋值语法

```plain
expression -> assignment
assignment -> IDENTIFIER "=" assignment | equality
```
