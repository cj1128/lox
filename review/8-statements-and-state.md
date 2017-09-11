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

## 增加赋值语法，注意，赋值是一个表达式

```plain
expression -> assignment
assignment -> IDENTIFIER "=" assignment | equality
```

## 增加块语法

```plain
statement -> exprStmt | printStmt | block;
block -> "{" declaration* "}"
```
