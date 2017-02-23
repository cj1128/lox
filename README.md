# Lox Programming Language

Implementation of [Crafting Interpreters](http://www.craftinginterpreters.com/)'s Lox language. Use Go rather than Java.

## Install

```bash
git clone https://github.com/fate-lovely/lox
cd lox/golox
make // install golox binary
golox // you can run binary now
```

## Modifications

this is some modifications to lox.

- make function keyword be `func` rather than `fun`
- handle nested block-comment(`/* … */`)
