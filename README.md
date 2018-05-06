<h1 align="center">
  <a href="http://www.craftinginterpreters.com/">
    Crafting Interpreters 
  </a>
</h1>

<p align="center">
  <a href="./spec.md">Lox Spec</a>
</p>

## Setup

```bash
git clone https://github.com/fate-lovely/lox
mkdir -p $GOPATH/src/github.com/fate-lovely
cd lox/golox
ln -s $(pwd) $GOPATH/src/github.com/fate-lovely/golox
cd $GOPATH/src/github.com/fate-lovely/golox
make // install golox binary
golox
```

## Modifications

some modifications to lox.

- make function keyword be `func` rather than `fun`
- handle nested block-comment(`/* /* ... */ */`)

## Notes

### A Map of the Territory

- Lexing (Scanning)
- Parsing
- Static Analysis
- Generate intermediate representation
- Optimization
- Code Generation

### Intermediate Representations

- Control Flow Graph(CFG)
- Static Single-Assignment(SSA)
- Continuation-Passing Style(CPS)
- Three Address Code(TAC)

### Optimization

- Constant Propagation
- Common Subexpression Elimination
- Loop Invariant Code Motion
- Global Value Numbering
- Strength Reduction
- Scalar Replacement of Aggregates
- Dead Code Elimination
- Loop Unrolling

### Single-Pass Compilers

某些编译器混合了`Parsing`,`Analysis`等步骤，在Parsing阶段就直接生成代码，这意味着编译器看到每一个表达式，都需要知道足够的信息去编译它。这对语言有很大的限制，语言用到的每一个东西都需要提前声明（C和Pascal就满足这样的限制）。

`Syntax-Directed Translation`是一种帮助生成Single-Pass Compilers的技术。

### Tree-Walk Interpreters

Tree-walk interpreters指的是生成AST以后通过遍历AST来执行代码。这个技术通常用于小的实验项目中，通用编程语言很少用因为比较慢（Ruby是一个例外，1.9之前的ruby使用的就是这个技术）。

## Reviews

### Charpter 4: Scanning

- scanning阶段扫描出的每一个符号叫做：`lexeme`
- `maximal munch`原则：当两个词法规则都能匹配token的时候，匹配到最多字符的规则胜出。

### Chartper 5: Representing Code

- basic grammer:

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

### Chartper 6: Parsing Expressions

- ambiguity

  第五章的语法实际上是Ambiguous的，因为没有定义操作符的优先级(Precedence)和结合性(Associativity)。

  下表定义了操作符的优先级，由高到低。

  |      Name      |      Operators       | Associativity |
  | :------------: | :------------------: | :-----------: |
  |     Unary      |       `!`, `+`       |     Right     |
  | Multiplication |       `*`, `/`       |     Left      |
  |    Addition    |       `+`, `-`       |     Left      |
  |   Comparison   | `>`, `>=`, `<`, `<=` |     Left      |
  |    Equality    |      `==`, `!=`      |     Left      |

  改进后的无歧义语法如下。

  ```text
  expression -> equality
  equality -> comparison ( ( "!=" | "==" ) comparison )*
  comparison -> addition ( ( ">" | ">=" | "<" | "<=" ) addition )*
  addition -> multiplication ( ( "-" | "+" ) multiplication )*
  multiplication -> unary ( ( "*" | "/" ) unary)*
  unary -> ( "!" | "-" ) unary | primary
  primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")"
  ```

### Chartper 7: Evaluating Expressions

- types

  + `nil` -> `nil`
  + `boolean` -> `bool`
  + `number` -> `float64`
  + `string` -> `string`

### Chartper 8: Statements and State

- 增加Statement语法

  ```plain
  program -> statement* EOF
  statement -> exprStmt | printStmt
  exprStmt -> expression ";"
  printStmt -> "print" expression ";"
  ```

- 增加变量声明语法

  ```plain
  program -> declaration* EOF
  declaration -> varDecl | statement
  varDecl -> "var" IDENTIFIER ("=" expression)? ";"
  ```

- 增加赋值语法，注意，赋值是一个表达式

  ```plain
  expression -> assignment
  assignment -> IDENTIFIER "=" assignment | equality
  ```

- 增加块语法

  ```plain
  statement -> exprStmt | printStmt | block;
  block -> "{" declaration* "}"
  ```

### Chartper 9: Control Flow

- 增加If语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt
  ifStmt -> "if" "(" expression ")" statement ("else" statement)? 
  ```

- 增加逻辑操作符语法

  ```plain
  assignment -> IDENTIFIER "=" assignment | logic_or
  logic_or -> logic_and ( "or" logic_and )*
  logic_and -> equality ( "and" equality )*
  ```

- 增加While语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt | whileStmt
  whileStmt -> "while" "(" expression ")" statement
  ```

- 增加For语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt
  forStmt -> "for" "(" ( varDecl | exprStmt | ";" )
                        expression? ";"
                        expression? ")" statement
  ```

### Chartper 10: Functions

- 加入函数调用语法

  ```plain
  unary -> ( "!" | "-" ) unary | call
  call -> primary ( "(" arguments? ")" )*
  arguments -> expression ( "," expression )*
  ```

- 加入函数声明语法

  ```plain
  declaration -> funcDecl | varDecl | statement
  funcDecl -> "func" function
  function -> IDENTIFIER "(" parameters? ")" block
  parameters -> IDENTIFIER ( "," IDENTIFIER )*
  ```

- 加入函数返回语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt | returnStmt
  returnStmt -> "return" expression? ";"
  ```
