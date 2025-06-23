<h1 align="center">
  <a href="http://www.craftinginterpreters.com/">
    Crafting Interpreters
  </a>
</h1>

- [Lox Implementations](https://github.com/munificent/craftinginterpreters/wiki/Lox-implementations)
- [Lox Spec](./lox-spec.md)

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

[Lox Spec](./lox-spec.md)

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
  - Add support to Lox’s scanner for C-style /_ ... _/ block comments. Make sure to handle newlines in them. Consider allowing them to nest. Is adding support for nesting more work than you expected? Why?
    - trivial to add support for nesting, just need a counter to store current nesting level

## Chapter 5: Representing Code

- Context-Free Grammars
  - regular languages aren’t powerful enough to handle expressions which can nest arbitrarily deeply.
- A Grammar for Lox expressions
  - CAPITALIZE terminals are a single lexeme whose text representation may vary, e.g. NUMBER is any number literal
  ```ebnf
  expression = literal
              | unary
              | binary
              | grouping ;
  literal = NUMBER | STRING | "true" | "false" | "nil" ;
  grouping  = "(" expresson ")" ;
  unary  = ( "-" | "!" ) expression ;
  binary  = expression operator expression ;
  operator  = "==" | "!=" | "<" | ">" | "<=" | ">=" | "+" | "-" | "*" | "/" ;
  ```
- Challenges: SKIP

## Chapter 6: Parsing Expressions

- The grammar defined in last chapter is actually **ambiguous**, because we don't define operator **Precedence** and **Associativity**
  - Precedence determines which operator is evaluated first in an expression containing a mixture of different operators.
  - Associativity determines which operator is evaluated first in a series of the same operator.
- Associativity determines which operator is evaluated first in a series of the same operator.
  ```js
  console.log(0.1 * (0.2 * 0.3))
  console.log(0.1 * 0.2 * 0.3)
  ```
- Lox has the same precedence rules as C, below table is going from lowest to highest.
  | Name | Operators | Associativity |
  | :------------: | :------------------: | :-----------: |
  | Equality | `==`, `!=` | Left |
  | Comparison | `>`, `>=`, `<`, `<=` | Left |
  | Term | `+`, `-` | Left |
  | Factor | `*`, `/` | Left |
  | Unary | `!`, `-` | Right |
- There are many grammars you can define that match the same language. The choice for how to model a particular language is partially a matter of taste and partially a pragmatic one.
- Enahnced expression grammar without ambiguity
  ```ebnf
  expression  = equality ;
  equality  = comparison ( ( "!=" | "==" ) comparison )* ;
  comparison  = term ( ( ">" | ">=" | "<" | "<=" ) term )* ;
  term  = factor ( ( "-" | "+" ) factor )* ;
  factor = unary ( ( "*" | "/" ) unary)* ;
  unary  = ( "!" | "-" ) unary | primary ;
  primary = NUMBER | STRING | "false" | "true" | "nil" | "(" expression ")" ;
  ```
- Recursive Descent Parsing
  - Recursive descent is the simplest way to build a parser, and doesn’t require using complex parser generator tools like Yacc, Bison or ANTLR.
  - Don’t be fooled by its simplicity, though. Recursive descent parsers are **fast**, **robust**, and can **support sophisticated error handling**. In fact, GCC, V8 (the JavaScript VM in Chrome), Roslyn (the C# compiler written in C#) and many other heavyweight production language implementations use recursive descent. It rocks.
  - A recursive descent parser is a literal translation of the grammar’s rules straight into imperative code. Each rule becomes a function.
- A parser really has two jobs:
  - Given a valid sequence of tokens, produce a corresponding syntax tree.
  - Given an invalid sequence of tokens, detect any errors and tell the user about their mistakes.
- Challenges:
  - Add support for comman expression
    ```ebnf
    expression  = comma ;
    comma  = equality ("," equality)* ;
    ```
  - Add support for ternary operator
    ```ebnf
    expression = comma ;
    comma = ternary ("," ternary)* ;
    ternary = equality ("?" ternary ":" ternary)?
    ```
  - Add error productions to handle each binary operator appearing without a left-hand operand
    ```ebnf
    primary =
      NUMBER | STRING | "false" | "true" | "nil"
      | "(" expression ")"
      (* error productions... *)
      | ( "!=" | "==" ) equality
      | ( ">" | ">=" | "<" | "<=" ) comparison
      | ( "+" ) term
      | ( "/" | "*" ) factor
    ```

## Chapter 7: Evaluating Expressions

- Lox follows Ruby's simple rule: false and nil are falsey, and everything else is truthy.
- The equality operators support operands of any type, even mixed ones.
- Challenges:

## Chapter 8: Statements and State

- An expression statement lets you place an expression where a statement is expected.
- A print statement evaluates an expression and displays the result to the user
- Updated grammar
  ```ebnf
  program = statement* EOF ;
  statement = exprStmt | printStmt ;
  exprStmt = expression ";" ;
  printStmt = "print" expression ";" ;
  ```
- Variable declarations are statements, but they are different from other statements, and we’re going to split the statement grammar in two to handle them
  - It’s as if there are two levels of “precedence” for statements. Some places where a statement is allowed—like inside a block or at the top level—allow any kind of statement, including declarations. Others allow only the “higher” precedence statements that don’t declare names.
  ```ebnf
  program = declaration* EOF ;
  declaration = varDecl | statement ;
  varDecl = "var" IDENTIFIER ("=" expression)? ";" ;
  ```
- Need to update grammar for variable access
  ```ebnf
  primary = "true" | "false" | "nil"
    | NUMBER | STRING
    | "(" expression ")"
    | IDENTIFIER ;
  ```
- Environments
  - evalute a undefined variable will got a runtime error
  - allow variable redefinition
- Assignments
  - assignment is an expression and not a statement, as in C, it is the lowest precedence expression form
  - assignment is not allowed to create a new variable, it's a runtime error if variable does not exist.
  ```ebnf
  expression = assignment
  assignment -> IDENTIFIER "=" assignment | equality
  ```
- Scope
  - **Lexical scope** (or the less commonly heard static scope) is a specific style of scoping where the text of the program itself shows where a scope begins and ends. In Lox, as in most modern languages, variables are lexically scoped.
  - In a C-ish syntax like Lox’s, scope is controlled by curly-braced blocks. (That’s why we call it block scope.)
  - Add block syntax
  ```ebnf
  program = declaration* EOF ;
  declaration = varDecl | statement ;
  statement = exprStmt | printStmt | block ;
  block = "{" declaration* "}" ;
  ```
- Challenges
  - 1: fairly simple to do, if no semicolon found I will put the parser into expression mode.

## Chapter 9: Control Flow

- `if` statement
  - dangling else problem
    - `if (first) if (second) whenTrue(); else whenFalse();`
  - It is possible to define a context-free grammar that avoids the ambiguity directly, but it requires splitting most of the statement rules into pairs, one that allows an if with an else and one that doesn’t. It’s annoying.
  - Instead, most languages and parsers avoid the problem in an ad hoc way. No matter what hack they use to get themselves out of the trouble, they always choose the same interpretation—the else is bound to the nearest if that precedes it.
  ```ebnf
  statement = exprStmt | printStmt | block | ifStmt ;
  ifStmt = "if" "(" expression ")" statement ("else" statement)? ;
  ```
- Logical operators, they are **short-circuit**
  ```ebnf
  ternary = logic_or ("?" assignment : assignment)? ;
  logic_or = logic_and ( "or" logic_and )*
  logic_and = equality ( "and" equality )*
  ```
- `while` loop, its grammar is the same as in C
  ```ebnf
  statement = exprStmt | printStmt | block | ifStmt | whileStmt
  whileStmt = "while" "(" expression ")" statement
  ```
- `for` loop
  - We're going to desugar for loops to the while loops and other statements the interpreter already handles.
  ```ebnf
  statement = exprStmt | printStmt | block | ifStmt | whileStmt | forStmt
  forStmt = "for" "(" ( varDecl | exprStmt | ";" )
                        expression? ";"
                        expression? ")" statement
  ```

## Chapter 10: Functions

- function calls

  - function call "operator" has higher precedence than any other operator, even the unary ones
  - syntax change
    ```ebnf
    unary = ( "!" | "-" ) unary | call ;
    call = primary ( "(" arguments? ")" )* ;
    arguments = expression ( "," expression )* ;
    ```
  - having a maximum number of arguments will simplify our bytecode interpreter later, so we will add a max 255 limit
  - for Lox, we’ll take Python’s approach. Before invoking the callable, we check to see if the argument list’s length matches the callable’s arity.

- native functions

  - `clock()` a native function that returns the number of seconds that have passed since some fixed point in time

  - aa

- function declarations

  ```ebnf
  declaration = funDecl | varDecl | statement ;
  funDecl = "fun" function ;
  function = IDENTIFIER "(" parameters? ")" block ;
  parameters = IDENTIFIER ( "," IDENTIFIER )* ;
  ```

- function object

  - function is a top-class value just like numbers, strings

- return statements
  - syntax change
    ```ebnf
    statement = exprStmt | printStmt | block | ifStmt | whileStmt | forStmt | returnStmt ;
    returnStmt = "return" expression? ";" ;
    ```
  - Every Lox function must return something, even if it contains no return statements at all. We use nil for this.
- Local Functions and Closures
  - Closures have been around since the early Lisp days, and language hackers have come up with all manner of ways to implement them. For jlox, we’ll do the simplest thing that works.
  - We use a `closure` to store surrounding environment

## Chapter 11: Resolving and Binding

- Static scope
  - Lox, like most modern languages, uses **lexical scoping**. This means that you can figure out which declaration a variable name refers to just by reading the text of the program.
  - The scope rules are part of the static semantics of the language, which is why they’re also called **static scope**.
  - The function should capture a frozen snapshot of the environment as it existed at the moment the function was declared.
  - static scope means that a variable usage always resolves to the same declaration
- Semantic analysis
  - Write a chunk of code that inspects the user’s program, finds every variable mentioned, and figures out which declaration each refers to. This process is an example of a **semantic analysis**.
  - If we could ensure a variable lookup always walked the same number of links in the environment chain, that would ensure that it found the same variable in the same scope every time.
  - After the parser produces the syntax tree, but before the interpreter starts executing it, we’ll do a single walk over the tree to resolve all of the variables it contains.
- Resolver
  - Make it an error to reference a variable in its initializer.
  - We do allow declaring multiple variables with the same name in the global scope, but doing so in a local scope is probably a mistake
  - Detect top level return statement
