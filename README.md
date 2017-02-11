# lispetit
A simple ruby interpreter for a small LISP language

## Features
- Integer and floating point numbers and the basic operations with them
- Strings and some basic operations with them. Literal syntaxis is `"And hiding their tossing manes..."`
- Booleans: **true** & **false**
- **nil**
- Lists, created like this: `(list 1 2.0 "pear")`
- Functions (first-class, with a few exceptions...). Created like this: `(fn (x y) (+ x y))`
- Recursion (no tail-optimisation)
- Macros.
- Higher-order functions

## List of functions:

> +, -, /, <, >, <=, >=, empty?, call, equal?, nil?, list, map, reduce, first, take, drop, upcase, reverse, concat, abs, floor, ceil, round, last, print, numerator, denominator, len, type, range, mod, rest, println, macroexpand, not, quotient, pow, substring, contains?, string?, trim, filter, apply, repeat, let, do, comp, define, fn, macro, quote, if, string->list, string-split, string-join, string-replace

## Examples


```
> (+ 1 2.0)
3.0
```

```
> (define second 2)
2
> (pow 3 second)
9
```

```
> (define sum
          (fn (x y)
              (+ x y)))
<Function 47346991263130>
> (sum 42 1)
43
```

```
> (define fibbonaci
        (fn (n)
            (if (<= n 2)
                1
                (+ (fibbonaci (- n 1))
                   (fibbonaci (- n 2))))))
<Function 47346991263180>
> (map fibbonaci (range 1 10))
(1 1 2 3 5 8 13 21 34 55)

```

And here's an example macro (the actual implementation of `comp`):

```
(define comp
        (macro (& fs)
               (list (quote fn)
                     (list (quote &) (quote args))
                     (let (innermost (list (quote apply)
                                           (last fs)
                                           (quote args)))
                          (reduce (fn (composed f)
                                      (list f composed))
                                  innermost
                                  (drop 1 (reverse fs)))))))
```

