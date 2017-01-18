# Lox Programming Language

this is my review of [Crafting Interpreters](http://www.craftinginterpreters.com/). 

use Go rather than Java to implement Lox language in the book.

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
