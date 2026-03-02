---
layout: post
title: "The Road to Monads 4: Parsing Arithmetic with Haskell Monads"
categories: haskell
---

This is the fourth and final article in a series on understanding monads in Haskell. If you have not already, feel free to check out the other posts below:

1. [Functors in Haskell]({% post_url 2020-8-4-functors-in-haskell %})
2. [Applicative Functors]({% post_url 2020-8-6-applicative-functors %})
3. [Understanding Monads]({% post_url 2020-8-8-understanding-monads-haskell %})
4. [Parsing Arithmetic with Monads]({% post_url 2020-8-9-parsing-arithmetic-with-monads %})

In this article, we will be demonstrating how monads can be used in practice, and proving their value. This article builds on ideas from Hutton & Meijer's seminal 1998 paper [Monadic Parsing in Haskell](https://www.cs.tufts.edu/comp/150FP/archive/graham-hutton/monadic-parsing-jfp.pdf). The end result will be a succinct and elegant ~60 line Haskell program which can parse expressions like `-12 * (4 - 2)^2` using the properties of monads.

## The `Parser` Type

If we want to read an expression like the example above as a string and compute its value, we have to write a program called a parser. We will be working specifically with parser combinators. This means we will start by building small, flexible parsers such as for single characters and digits. Then, we combine them into larger, more useful parsers.

First, we have to define a parser type. A parser will be a function that takes an input string, and parses a section of the string, returning the result of the parser and the rest of the string. For instance, a parser called `digit` may map `"1 + 2"` to `(1, " + 2")`. Note that we can parse to any type -- we will see later that if we return functions, we can use applicative syntax to evaluate expressions as we go, instead of constructing an [abstract syntax tree](https://ruslanspivak.com/lsbasi-part7/) and traversing it to evaluate the answer.

So far we have established a parser is a function of type `String -> (a, String)`. However, we need some way of encapsulating failure or multiple results. For this reason, we will use a list, producing a type `String -> [(a, String)]`. Another option is `Maybe`, however this does not work in certain situations where the grammar is ambiguous. (For example, when you parse the first character of `f(3)` it could be a function or a variable. It is only when subsequent characters are parsed that we can reduce it to one possibility.)

Now, you may see the signature `String -> [(a, String)]` and remember our function `safeRead :: String -> Maybe Double` from [part three]({% post_url 2020-8-8-understanding-monads-haskell %}), which returns `Nothing` for invalid strings. We can see in both cases we map from a normal value to a value with context, implying the return type is wrapped in a monad. It is tempting to thus define a `Parser` type constructor as `newtype Parser a = Parser [(a, String)]`. However, if we are sequencing functions using `>>=`, our functions must have the signature `a -> Parser b` and not `String -> Parser b`, which means our parsers will get the previous parsed value instead of the remainder of the string as input, which is not ideal. To combat this, we will define `Parser` to be a function, as follows. You can verify by checking the type signature of `>>=` and `Parser` that this suits our needs -- this is quite tricky to prove though, as with functions embedded in our monad the type signatures get very complex.

```hs
newtype Parser a = Parser { parse :: String -> [(a, String)] }

-- We used record syntax to generate a function 'parse'
-- which unwraps our parsers. It is equivalent to the following:
newtype Parser a = Parser (String -> [(a, String)])
parse :: Parser a -> (String -> [(a, String)])
parse (Parser f) = f
```

Before we dive in and create a `Monad` instance for our `Parser` type we will demonstrate how to use this `Parser` definition to create the simplest possible parser: `item`. This simply consumes the next character, and will be useful when defining more elaborate parsers. To write a simple parser, we need to wrap the type in the `Parser` type constructor, and the function declaration in the distinct `Parser` value constructor. This gives the following `item` parser:

```hs
item :: Parser Char
item = Parser (\cs -> case cs of
  "" -> []
  (c:cs) -> [(c,cs)])
```

We will also write two more simple parsers for single characters:

1. `char`: Matches a single character of choice.
2. `satisfy`: Similar to `char`, but at a higher level of abstraction. Takes a `Char -> Bool` predicate and the parser it creates only returns the character if the predicate is true.

```hs
satisfy :: (Char -> Bool) -> Parser Char
satisfy predicate = Parser (\cs ->
  case cs of
    (c:cs') ->
      (if predicate c
        then [(c, cs')]
        else [])
    _ -> [])

char :: Char -> Parser Char
char c = satisfy (== c)
```

## The `Functor` and `Applicative` Instances

Now we will define a `Monad` instance for `Parser`. We can do this as the `Parser` type constructor maps normal function types to `Parser` function types, and as it follows the functor, applicative and monad laws. For consistency, we will start with a `Functor` instance and work our way up.

When we `fmap` over a function of type `Parser a`, we want to apply the provided function to the parsed value (the `a` in `(a, String)`) of each possibility. This is a little tricky as the parsers are functions, so `fmap` takes two functions and produces another. To access the list `[(a, String)]` to map the given function over, we unwrap the parser and apply it to the string. We then apply the function to the first value of each tuple. You will find this abides by the rules of functors outlined in [part one]({% post_url 2020-8-4-functors-in-haskell %}).

```hs
instance Functor Parser where
  -- eg fmap (^2) (Parser (\_ -> [(2, "")]))
  -- becomes equivalent to Parser (\_ -> [(4, "")])
  -- this applies p to the remaining string, and maps f
  -- over the first element of each (a, String) tuple
  fmap f (Parser p) = Parser (\cs ->
    map (\(x, cs') -> (f x, cs')) (p cs))
```

With our `Functor` instance finished, we can now write a `digit` parser that instead of producing a `Char` as the result, produces an `Int`. We can write this as follows by applying `fmap read` to the result of our parser. To make sure we only read valid digits and fail gracefully if no digit is found (by returning `Parser (\_ -> [])`), we use `satisfy isDigit` as follows:

```hs
import Data.Char (isDigit)
digit :: Parser Int
digit = fmap (read . toString) (satisfy isDigit)
  where toString c = [c] -- Char -> [Char] (aka String)
```

Now, we move on to our `Applicative` instance. It is very difficult to see what is happening here, because an applicative allows you to embed a function within a functor. In this case, our functor itself contains embedded functions already, so a type `Parser (a -> b)` actually contains a higher order function. Note that we need to apply the function parser first, and then for each value of the function parser we can apply the argument parser on the remaining string. Once again, it is worth verifying that our definition follows the [rules of applicatives](https://hackage.haskell.org/package/base-4.14.0.0/docs/Prelude.html#t:Applicative), as the type system cannot verify these for us.

```hs
instance Applicative Parser where
  pure x = Parser (\cs -> [(x, cs)])
  -- parse f $ cs gives a list of (function, string) pairs.
  -- For each pair, we use fmap to apply the function inside
  -- the second parser, and we call the modified parser with
  -- the remaining string cs'
  -- we then concat/flatten the 2D list to 1D
  f <*> a = Parser (\cs ->
    concat (map
      (\(fn, cs') -> parse (fmap fn a) cs')
      (parse f cs)))
```

Alternatively, we could define `<*>` using list comprehension, which is a little easier to understand. This is similar to set-builder notation in maths, or list comprehension in Python and other languages.

```hs
f <*> a = Parser (\cs ->
  concat [parse (fmap fn a) cs' | (fn, cs') <- parse f cs])
```

This `Applicative` instance is very useful for several reasons. First, we now have access to the `*>` and `<*` functions. `*>` is equivalent to `>>` for `Monad`s, in that it sequences two monadic functions and returns the value of the second. `<*` returns the value of the first. This means we can write parsers like `space *> digit <* space`, which is a `Parser Int` expression that parses a digit surrounded by whitespace which is discarded.

Another reason our `Applicative` instance is useful is we can use `<*>` to evaluate each part of the expression as we go. This means we do not have to generate an abstract syntax tree and traverse it to find our answer. If we want to evaluate an expression like `" * 3 2 "` (where the operator is prefixed, cf. Reverse Polish Notation), we can write the following code:

```hs
-- parse "  *  3 2" into [((*), "  3 2")]
-- this embeds the actual (*) function into the Parser
mul = space *> char '*' *> pure (*) :: Parser (Int -> Int -> Int)

digit' = space *> digit <* space

expr = mul <*> digit' <*> digit'

main =
  let results = parse expr $ " * 3 2 "
  in print (fst (results !! 0))
```

## The `Alternative` Typeclass

However, you may be wondering where the `space` parser was defined. To define it, we will first create an `Alternative` instance for `Parser`. `Alternative` is a subclass of `Applicative` which describes choice out of multiple options, by exposing a binary operation `<|>`. We will define our instance so that `a <|> b` produces the result of the first parser if it succeeded, with the second as a fallback. The `Alternative` typeclass also provides us with the nifty `some` and `many` functions, which will allow us to match the same parser repeated 1+ or 0+ times respectively. We will use `many (satisfy isSpace)` to parse whitespace. An interesting side note is that `Alternative` forms a [monoid]({% post_url 2020-8-2-monoids-in-haskell %}) where `<|>` is our binary operation, `Parser a` is our set, and `empty` is the identity.

```hs
import Control.Applicative
import Data.Char (isSpace)

-- Parsers are alternative so p <|> q applies q only if p fails
-- This lets us try multiple parsers sequentially
instance Alternative Parser where
  empty = Parser (\_ -> [])
  p <|> q = Parser (\cs ->
    let (p', q') = (parse p cs, parse q cs) in
    if length p' > 0 then p' else q')

space :: Parser String
space = many (satisfy isSpace)
```

With that done, we can now run our simple example calculating `" * 3 2 "` above, and you should see `6` print to the screen.

Now, you may be wondering why we have changed tack and parsed prefixed operators and not infix. The reason is that we cannot actually parse infix functions this way with applicatives alone. We need a `Monad` instance so that we can apply our `digit'` parser first, unwrap the result, and then parse the operator. In `do`-notation, this is rendered as `do { a <- digit'; mul <*> pure a <*> digit' }`, which requires `>>=` under the hood, as we cannot change the order of sequencing with applicatives alone.

> Intuitively, the `>>=` of some `Monad` allows the value returned by one computation to influence the choice of another, whereas `<*>` keeps the structure of a computation fixed, just sequencing the effects. (McBride & Paterson, Applicative Programming with Effects)

## The `Monad` Instance

Now we will finally create our `Monad` instance. Using the existing `Applicative` definition, we can simply define `return = pure`. The `>>=` is a little tricker, but it is actually quite similar to `<*>`. We flatten a 2D list created by applying the function `f` to each unwrapped value produced by the preceding parser.

```hs
instance Monad Parser where
  return = pure
  p >>= f = Parser (\cs ->
    concat [parse (f a) cs' | (a, cs') <- parse p cs])
```

We can now parse `"3 * 2"` using the following snippet, which once again will print out `6`.

```hs
expr = do
  a <- digit'
  op <- mul
  b <- digit'
  return (op a b)
-- OR
expr = do
  a <- digit'
  mul <*> pure a <*> digit'
-- OR
expr = digit' >>= (\a -> mul <*> pure a <*> digit')

main =
  let results = parse expr $ "3 * 2"
  in print (fst (results !! 0))
```

We can also now rewrite `satisfy` using `>>=` as `satisfy pred = item >>= (\c -> if pred c then pure c else empty)`, a full 6 lines shorter.

## Arithmetic Parsing

Now that we have all the groundwork in place, we can start parsing larger expressions. In this section we will introduce several new parser combinators, and by the end we will be able to handle order of operations including brackets. First, we will define all of the operations we use, and a parser for integers in general.

```hs
string :: String -> Parser String
string "" = return ""
string (c:cs) = (:) <$> char c <*> string cs

token :: String -> Parser String
token symb = space *> string symb

-- We combine * and / into one operation. Note we use integer division.
mul :: Parser (Int -> Int -> Int)
mul = token "*" *> pure (*) <|> token "/" *> pure div

add :: Parser (Int -> Int -> Int)
add = token "+" *> pure (+) <|> token "-" *> pure (-)

pow :: Parser (Int -> Int -> Int)
pow = (token "^" <|> token "**") *> pure (^)

integer :: Parser Int
integer =
  let positive = fmap read (some (satisfy isDigit))
  in space *> unary_minus positive

-- Unary minus (eg the - in -5) does not conflict with subtraction
-- because the integer parser is only called when an integer is expected,
-- not an operator.
unary_minus :: Parser Int -> Parser Int
unary_minus p = char '-' *> fmap negate p <|> p
```

Now, we need a way of sequencing multiple operations while respecting order of operations. For this, we introduce a parser `chainl1` which parses repeated applications of a parser separated by a parser that produces a binary function. This binary function is applied to each result of the first parser. We assume the operator is left associative (so `a . b . c == (a . b) . c`), which is true for the four fundamental operations. To support exponentiation I have included a `chainr1` function too.

```hs
chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainl1` op = p >>= rest
  where rest a = ((op <*> pure a <*> p) >>= rest)  <|> return a

chainr1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainr1` op = p >>= rest
  where rest a =  (op <*> pure a <*> (p >>= rest)) <|> return a
```

For example, `digit' \`chainl1\` `mul` for `2 * 3 / 4` will compute `div ((\*) 2 3) 4`.

These functions in their compact monadic form are very difficult to understand, especially due to their recursive nature. An expanded `do` form of `chainl1` taken from Hutton & Meijer is as follows (annotations are my own).

```hs
p `chainl1` op = do
  -- Parse first value
  a <- p
  rest a
  where
    -- Parse every subsequent operator and value given the previous
    -- until the value parser fails and defaults to returning the
    -- accumulated result.
    rest a = (do f <- op
      b <- p
      rest (f a b))
      <|> return a
```

These functions may seem complicated and cumbersome, however we can now express a fully functional parser supporting brackets and order of operations in just two more lines of code:

```hs
expr = subexpr `chainr1` pow `chainl1` mul `chainl1` add
subexpr = token "(" *> expr <* token ")" <|> integer
```

If you still had any holdouts about `Monad`s and associated abstractions, these two lines should thoroughly convince you of their elegance. We can write a simple calculator REPL, producing the final program in the source file linked below. If you run this program, you can enter expressions like `-12 * (4 - 2)^2` and see the results appear in realtime. Neat!

That brings us to the end of this fairly lengthy tutorial demonstrating how monads can be used in practice. Hopefully you are now convinced of their value, and feel more comfortable using them having been exposed to them in a practical setting. If you found this project interesting, check out the paper [Monadic Parsing in Haskell](https://www.cs.tufts.edu/comp/150FP/archive/graham-hutton/monadic-parsing-jfp.pdf) which inspired this, and a more [feature-packed version of this calculator](https://github.com/OliverBalfour/ParserCombinatorCalculator) I made supporting trig functions, automatic differentiation, LaTeX math expressions, and much more.

Source Code: [`Arithmetic.hs`](/assets/code/Arithmetic.hs):

Congrats! You made it!
