package main

type Stmt interface {
	Run(env *Env)
}

/*----------  Print Stmt  ----------*/

type StmtPrint struct {
	expr Expr
}

func NewStmtPrint(expr Expr) *StmtPrint {
	return &StmtPrint{expr}
}

/*----------  Expression Stmt  ----------*/

type StmtExpression struct {
	expr Expr
}

func NewStmtExpression(expr Expr) *StmtExpression {
	return &StmtExpression{expr}
}

/*----------  Var Decl Stmt  ----------*/
type StmtVarDecl struct {
	name  *Token
	value Expr
}

func NewStmtVarDecl(name *Token, value Expr) *StmtVarDecl {
	return &StmtVarDecl{name, value}
}

/*----------  Block Stmt  ----------*/
type StmtBlock struct {
	stmts []Stmt
}

func NewStmtBlock(stmts []Stmt) *StmtBlock {
	return &StmtBlock{stmts}
}

/*----------  If Stmt  ----------*/
type StmtIf struct {
	condition   Expr
	trueBranch  Stmt
	falseBranch Stmt
}

func NewStmtIf(condition Expr, trueBranch, falseBranch Stmt) *StmtIf {
	return &StmtIf{condition, trueBranch, falseBranch}
}

/*----------  While Stmt  ----------*/
type StmtWhile struct {
	condition Expr
	body      Stmt
}

func NewStmtWhile(condition Expr, body Stmt) *StmtWhile {
	return &StmtWhile{condition, body}
}

/*----------  Function Declaration Stmt  ----------*/
type StmtFuncDecl struct {
	name       *Token
	parameters []*Token
	body       []Stmt
}

func NewStmtFuncDecl(name *Token, parameters []*Token, body []Stmt) *StmtFuncDecl {
	return &StmtFuncDecl{name, parameters, body}
}
