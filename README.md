<h1 align="center">
  <a href="http://www.craftinginterpreters.com/">
    Crafting Interpreters
  </a>
</h1>

- [Lox Implementations](https://github.com/munificent/craftinginterpreters/wiki/Lox-implementations)
- [Lox Spec](./spec.md)

## Chapter 1 Introduction

- Compiler-compiler
  - `Yacc` is a tool that takes in a grammar file and produces a source file for a compiler, so it’s sort of like a "compiler-compiler".
  - A later similar tool is `Bison`, named as a pun on the pronunciation of Yacc like "yak".
- A compiler reads files in one language, translates them, and outputs files in another language. You can implement a compiler in any language, including the same language it compiles, a process called **self-hosting**.

## Chapter 2 A Map of the Territory

- The Parts of a Language
  - Lexing (Scanning), lexical analysis
  - Parsing
  - Static Analysis
  - Generate intermediate representation
  - Optimization
  - Code Generation
- IR Intermediate Representations
  - Control Flow Graph (CFG)
  - Static Single-Assignment (SSA)
  - Continuation-Passing Style (CPS)
  - Three Address Code (TAC)
- Optimization keywords
  - Constant Propagation
  - Common Subexpression Elimination
  - Loop Invariant Code Motion
  - Global Value Numbering
  - Strength Reduction
  - Scalar Replacement of Aggregates
  - Dead Code Elimination
  - Loop Unrolling
- Single-Pass Compilers
  - 某些编译器混合了 `Parsing`, `Analysis` 等步骤，在 Parsing 阶段就直接生成代码，这意味着编译器看到每一个表达式，都需要知道足够的信息去编译它。这对语言有很大的限制，语言用到的每一个东西都需要提前声明（C 和 Pascal 就满足这样的限制）。
  - `Syntax-Directed Translation` 是一种帮助生成 Single-Pass Compilers 的技术。
- Tree-Walk Interpreters
  - Tree-walk interpreters 指的是生成 AST 以后通过遍历 AST 来执行代码。这个技术通常用于小的实验项目中，通用编程语言很少用因为比较慢（Ruby 是一个例外，1.9 之前的 Ruby 使用的就是这个技术）。
- Transpilers: a source-to-source compiler

## Chapter 3: The Lox Language

[Lox Spec](./spec.md)

## Chapter 4: Scanning

- `lexeme` is a raw substrings of the source code, produced by the scanner
- The rules that determine how a particular language groups characters into lexemes are called its **lexical grammar**.
- In Lox, as in most programming languages, the rules of that grammar are simple enough for the language to be classified a **regular language**. That’s the same “regular” as in regular expressions.
- Tools like Lex or Flex are designed expressly to let you do this—throw a handful of regexes at them, and they give you a complete scanner back
- `maximal munch` principle: When two lexical grammar rules can both match a chunk of code that the scanner is looking at, whichever one **matches the most characters wins**.
- Challenges
  - The lexical grammars of Python and Haskell are not regular. What does that mean, and why aren’t they?
    - Their tokenization rules cannot be fully expressed by regular languages, which means cannot be implemented using just regular expressions or finite automata.
    - Their syntax is indentation-based, need to **remember** current indentation level
  - Aside from separating tokens—distinguishing print foo from printfoo—spaces aren’t used for much in most languages. However, in a couple of dark corners, a space does affect how code is parsed in CoffeeScript, Ruby, and the C preprocessor. Where and what effect does it have in each of those languages?
    ```coffeescript
    # coffeescript
    console.log +1 # console.log(+1);
    console.log+1 # console.log + 1;
    ```
    ```ruby
    # ruby
    def f():
      100
    end

    f -1 # passes -1 as an argument to f
    f-1 # calls f and then minus 1
    ```
    ```c
    // C preprocessor
    #define FOO(x) x+1
    #define FOO (x) x+1
    ```
  - Our scanner here, like most, discards comments and whitespace since those aren’t needed by the parser. Why might you want to write a scanner that does not discard those? What would it be useful for?
    - documentation generation
  - Add support to Lox’s scanner for C-style /* ... */ block comments. Make sure to handle newlines in them. Consider allowing them to nest. Is adding support for nesting more work than you expected? Why?
    - trivial to add support for nesting, just need a counter to store current nesting level

## Chapter 5: Representing Code

- Context-Free Grammars
  - regular languages aren’t powerful enough to handle expressions which can nest arbitrarily deeply.
- A Grammar for Lox expressions
  - CAPITALIZE terminals are a single lexeme whose text representation may vary, e.g. NUMBER is any number literal
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
- Challenges: SKIP

## Chapter 6: Parsing Expressions

- The grammar defined in last chapter is actually **ambiguous**, because we don't define operator **Precedence** and **Associativity**
  - Precedence determines which operator is evaluated first in an expression containing a mixture of different operators.
  - Associativity determines which operator is evaluated first in a series of the same operator.
- Associativity determines which operator is evaluated first in a series of the same operator.
  ```js
  console.log(0.1 * (0.2 * 0.3))
  console.log((0.1 * 0.2) * 0.3)
  ```
- Lox has the same precedence rules as C, below table is going from lowest to highest.
  |      Name      |      Operators       | Associativity |
  | :------------: | :------------------: | :-----------: |
  |    Equality    |      `==`, `!=`      |     Left      |
  |   Comparison   | `>`, `>=`, `<`, `<=` |     Left      |
  |      Term      |       `+`, `-`       |     Left      |
  |     Factor     |       `*`, `/`       |     Left      |
  |     Unary      |       `!`, `-`       |     Right     |
- There are many grammars you can define that match the same language. The choice for how to model a particular language is partially a matter of taste and partially a pragmatic one.
- Enahnced grammar without ambiguity
  ```text
  expression -> equality
  equality -> comparison ( ( "!=" | "==" ) comparison )*
  comparison -> term ( ( ">" | ">=" | "<" | "<=" ) term )*
  term -> factor ( ( "-" | "+" ) factor )*
  factor -> unary ( ( "*" | "/" ) unary)*
  unary -> ( "!" | "-" ) unary | primary
  primary -> NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")"
  ```
- Recursive Descent Parsing
  - Recursive descent is the simplest way to build a parser, and doesn’t require using complex parser generator tools like Yacc, Bison or ANTLR.
  - Don’t be fooled by its simplicity, though. Recursive descent parsers are **fast**, **robust**, and can **support sophisticated error handling**. In fact, GCC, V8 (the JavaScript VM in Chrome), Roslyn (the C# compiler written in C#) and many other heavyweight production language implementations use recursive descent. It rocks.
  - A recursive descent parser is a literal translation of the grammar’s rules straight into imperative code. Each rule becomes a function.
- A parser really has two jobs:
  - Given a valid sequence of tokens, produce a corresponding syntax tree.
  - Given an invalid sequence of tokens, detect any errors and tell the user about their mistakes.

## Chapter 7: Evaluating Expressions

- types

  - `nil` -> `nil`
  - `boolean` -> `bool`
  - `number` -> `float64`
  - `string` -> `string`

## Chapter 8: Statements and State

- 增加 Statement 语法

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

### Chapter 9: Control Flow

- 增加 If 语法

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

- 增加 While 语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt | whileStmt
  whileStmt -> "while" "(" expression ")" statement
  ```

- 增加 For 语法

  ```plain
  statement -> exprStmt | printStmt | block | ifStmt | whileStmt | forStmt
  forStmt -> "for" "(" ( varDecl | exprStmt | ";" )
                        expression? ";"
                        expression? ")" statement
  ```

### Chapter 10: Functions

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
