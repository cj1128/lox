# Crafting Interpreters

##  Part 1

### A Map of the Territory

- Lexing (Scanning)
- Parsing
- Static Analysis
- Generate intermediate representation
- Optimization
- Code Generation

#### Intermediate Representations

- Control Flow Graph(CFG)
- Static Single-Assignment(SSA)
- Continuation-Passing Style(CPS)
- Three Address Code(TAC)

#### Optimization

- Constant Propagation
- Common Subexpression Elimination
- Loop Invariant Code Motion
- Global Value Numbering
- Strength Reduction
- Scalar Replacement of Aggregates
- Dead Code Elimination
- Loop Unrolling

#### Single-Pass Compilers

某些编译器混合了`Parsing`,`Analysis`等步骤，在Parsing阶段就直接生成代码，这意味着编译器看到每一个表达式，都需要知道足够的信息去编译它。这对语言有很大的限制，语言用到的每一个东西都需要提前声明（C和Pascal就满足这样的限制）。

`Syntax-Directed Translation`是一种帮助生成Single-Pass Compilers的技术。

#### Tree-Walk Interpreters

Tree-walk interpreters指的是生成AST以后通过遍历AST来执行代码。这个技术通常用于小的实验项目中，通用编程语言很少用因为比较慢（Ruby是一个例外，1.9之前的ruby使用的就是这个技术）。
