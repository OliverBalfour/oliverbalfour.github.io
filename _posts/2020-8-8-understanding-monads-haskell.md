---
layout: post
title: "The Road to Monads 3: Understanding Monads in Haskell"
categories: haskell
---

This is the third article in a series about monads in Haskell. The others are available here:

1. [Functors in Haskell]({% post_url 2020-8-4-functors-in-haskell %})
2. [Applicative Functors]({% post_url 2020-8-6-applicative-functors %})
3. [Understanding Monads]({% post_url 2020-8-8-understanding-monads-haskell %})
4. [Parsing Arithmetic with Monads]({% post_url 2020-8-9-parsing-arithmetic-with-monads %})


In this article, we will finally introduce monads themselves. I highly recommend reading parts one and two first to develop a solid grasp of functors and applicatives, as it will make it far easier to think at a high level of abstraction. Monads are actually quite a simple concept, but they are incredibly abstract and analogies can only go so far. Do not expect them to come easily!

First we approach a limitation of functors and applicatives in three different ways and show they all reduce to the same concept, a monad. Then, we walk through an example deriving the `Maybe` monad and show it adheres to the monad laws. Finally, we take a closer look at the list monad, `do`-notation, and the `IO` monad. Part four then walks through a hands-on example of using a monad to parse arithmetic expressions.

In essence, monads allow composition of functions which produce values embedded inside a functor. This allows us to, for example, sequence functions which take normal values and produce `Maybe a` values, so that if any computation fails and produces `Nothing`, all subsequent computations do the same. This means we can write and sequence functions of type `a -> Maybe b` instead of using `Maybe a -> Maybe b` and manually checking in every function whether the previous returned a `Nothing` before proceeding. This monadic composition allows us to abstract away implementation details and side effects and write very concise, expressive code.

We saw in part one that a functor allows us to 'promote' a function to work in the context of a function. This means we can perform operations on values stored inside of a functor, like below:

```hs
fmap (+1) (Just 1) -- => Just 2
```

We also saw in part two that with a few additions, we can define applicative functors, which allow us to use multivariate functions on functorial values. This works by first using `fmap` (or the infix `<$>` alias) on a function of multiple parameters and the first parameter. This embeds partially applied functions within the applicative. Then, we can use the `<*>` operator to apply these embedded functions to additional arguments, as follows:

```hs
-- embed partially applied function in Maybe applicative functor
(+) <$> Just 3            -- => Just (+3)
pure (+) <*> (Just 3)     -- => Just (+3)
-- use <*> to apply the embedded function on more functorial values
(+) <$> Just 3 <*> Just 4 -- => Just 7
```

However, there is still one problem. What if we have two functions which take a normal value and produce a functorial value, which we need to apply one after another? That is, sequencing functions of type `a -> f b` and `b -> f c` to produce a value of type `f c`. We use the `m` type variable to refer to monads. A monadic value is a value of type `m a`, and a monadic function is a function of type `a -> m b`. We take three approaches in this article to not just show how monads are used, but motivate the way they are defined.

1. Flattening monadic values. If we try `fmap` on a function of type `a -> f b`, we get a function of type `f a -> f (f b)`. In the `Maybe` functor, that means we get `Maybe (Maybe b)`, which is not ideal. In a sense, we need to 'flatten' the two layers of functor into one, which neither functors nor applicatives can help us with.
2. Composing monadic functions. If we have two functions of type `a -> f b` and `b -> f c`, we could write a function `>=>` which composes the two into a function of type `a -> f c`.
3. Sequencing monadic computations. If we have a functorial value of type `f a`, and a function of type `a -> f b`, we could write a function `>>=` which applies the value inside of our monadic value to our function.

## Flattening Monadic Values

Suppose we are writing some mathematical functions using `Maybe` to encapsulate undefined values. For $$1\div x$$, we return `Nothing` for 0. For $$\sqrt x$$, we return `Nothing` for negative values. This is exactly what the `Maybe` type constructor is for: it encapsulates the possibility of failure in a computation into the type system.

```hs
safeInverse :: Double -> Maybe Double
safeInverse 0 = Nothing
safeInverse x = Just (1 / x)

safeSqrt :: Double -> Maybe Double
-- signum is -1 for negatives, 0 for 0 and 1 for positives
safeSqrt x = case signum x of
  (-1) -> Nothing
  _ -> Just (sqrt x)
```

The issue with this code is that to integrate this into a larger program, we suddenly need to start passing `Maybe` values around everywhere. Every function needs to pattern-match the `Maybe` to make sure the argument is not `Nothing` before proceeding. In cases where we are returning normal values (`a -> b` instead of `a -> f b`) we can use `fmap` to reduce boilerplate.

However, suppose we want to compose these functions to compute $$1\div \sqrt x$$. If either operation results in a `Nothing` value, we wish to propagate that and say the whole expression is undefined. Based on this, we will now define an operation which allows us to abstract away the pattern matching, similarly to how we defined `fmap` to avoid excess pattern matching in part one.

So, we want to evaluate our `safeInverse` function, which takes a normal value, on the result of `safeSqrt`, which produces a functorial value. We can try using `fmap` to promote our `safeInverse` function to accept `Maybe Double`s,  however this has type `Maybe Double -> Maybe (Maybe Double)`.

To work around this, we can write a function we call `join`, which flattens our two layers of functor into one. In fact, if we can write a `join` function, we actually have a monad. Neat!

```hs
join :: Maybe (Maybe a) -> Maybe a
join (Just x) = x
join Nothing = Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse = join $ fmap safeInverse (safeSqrt x)

-- more generally:
join :: Monad m => m (m a) -> m a
```

We have just discovered the function `join` for monads, which removes a level of monadic structure. Now we can evaluate $$1\div \sqrt x$$ as `join $ fmap safeInverse (safeSqrt x)`. However, as we will soon see the way of creating a `Monad` instance requires defining a slightly different function.

## Composing Monadic Functions

Another way we could approach the $$1\div \sqrt x$$ example is to consider a form of function composition. We compose two functions that take normal values and return functorial values. This is called Kleisli composition, and we denote it using the `>=>` operator (pronounced 'fish'). We can show this is equivalent to defining the `join` function, so once again we have a monad. This abstraction will allow us to write functions like `a -> Maybe b` and sequence them without having to pattern match all the time.

For the above example, we need to write an implementation of `>=>` such that `f >=> g` is of type `a -> m c` where `f :: a -> m b` and `g :: b -> m c`.

```hs
(>=>) :: (a -> Maybe b) -> (b -> Maybe c) -> (a -> Maybe c)
f >=> g = \x -> case f x of
  Just x -> g x
  Nothing -> Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse = safeSqrt >=> safeInverse

-- more generally:
(>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c
```

This approach provides the same end result, however it is slightly cleaner than the `fmap` and `join` approach above.

However, suppose we have a monadic value (`m a`) we wish to pass to a function (`a -> m b`). To use our fish operator, we have to define a function which returns a constant value, and call it on a dud value. Something like `(const (Just 4) >=> (\x -> Just (x+1))) ()`, where `const a b = a` and `()` is 'unit' (the empty tuple, useful as a dud value). This is immensely confusing. The next approach differs by allowing us to supply a monadic value to a function, instead of allowing us to compose two monadic functions.

## Sequencing Monadic Computations

Another way we could accomplish the same task is by defining a function which takes a monadic value `m a` and a monadic function `a -> m b` and produces a monadic value `m b`. We will call this `>>=` (bind). This effectively unwraps our input monadic value and lets us apply it to a function which takes a normal value.

Piecing together the fragments above, the complete type signature of this function is `m a -> (a -> m b) -> m b`. For `Maybe` we can define it as follows:

```hs
(>>=) :: Maybe a -> (a -> Maybe b) -> Maybe b
x >>= f = case x of
  (Just x') -> f x'
  Nothing -> Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse x = safeSqrt x >>= safeInverse
```

In practice, we can use this like `Just 3 >>= (\x -> Just (x+1))`, which produces `Just 4`.

If we wish to compose two monadic functions like the fish operator above does, we can simply apply the first function to get a value and use bind on the result. The `sqrtInverse` definition above does exactly that to compose two monadic functions. Using `>>=` is neat whether the first argument is a value or a function, so this is the approach taken by the Haskell standard library in the `Monad` class definition.

Using `>>=` is far more ubiquitous than `join` or `>=>`, even in situations where the latter two make more sense. However, understanding that the three approaches all work is very useful for understanding what a monad actually tries to accomplish, rather than memorising and taking for granted the type signature of `>>=`.

Once you have a `Monad` instance, you can always use `join` and `>=>` where appropriate, as they are defined in terms of `>>=` in the standard library in `Control.Monad`. In fact, all three can be defined in terms of each other (below), so each notion of a monad is equally powerful.

```
join x = x >>= id
join x = const x >=> id
f >=> g = \x -> f x >>= g
f >=> g = \x -> join (f . g $ x)
x >>= f = join (f <$> x)
x >>= f = (const x >=> f) ()
```

This simple example is just scratching the surface of what can be accomplished with monads. When you need to sequence a number of operations which could fail (`Maybe`), which are impure (`IO`), which maintain state between them (`State`), and in many other circumstances, the monad abstraction allows you to write incredibly terse code which abstracts away all of the boilerplate. [Part four]({% post_url 2020-8-9-parsing-arithmetic-with-monads %}) gives a real-world example of using monads for parsing arithmetic, culminating in an elegant ~60 line Haskell program which can evaluate expressions like `-12 * (4 - 2)^2`.

## Deriving the `Maybe` Monad

Now we introduce the definition of the `Monad` typeclass. The `Monad` typeclass is a subset of applicative functors which has two member functions: `return`, and `>>=`.

```hs
class Applicative m => Monad m where
  return :: a -> m a
  (>>=) :: m a -> (a -> m b) -> m b
```

`return` is a function which embeds a normal value in the monad without any context. If you read part two about [applicative functors]({% post_url 2020-8-6-applicative-functors %}), you may remember I mentioned at the end `pure` and `return` are equivalent. In fact, `return` is only a separate entity for historical reasons. For `Maybe`, `return x = Just x`, and for lists, `return x = [x]`. If you write an applicative instance, you can simply take advantage of it by writing `return = pure`.

The second function is our `>>=` function from above. It takes a monadic value, and a function from a normal value to a monadic value. It unwraps the values inside the monad and applies the function to each value, producing a monadic value. An equivalent notion is using `fmap` to promote the function to accept monadic values, and then using our `join` function to flatten the doubly nested monadic return value into a normal monadic type. This is the trickiest part of understanding monads, and we will see several examples of how this function is used.

We can write a `Monad` instance for the `Maybe` typeclass fairly easily. I have omitted the corresponding `Functor` and `Applicative` instances, but they are in this post's [source code](/assets/code/Monads.hs) (also linked to at the end).
```hs
data Maybe a = Just a | Nothing
instance Monad Maybe where
  -- (>>=) :: Maybe a -> (a -> Maybe b) -> Maybe b
  -- note we don't use Just (f x) as f returns a 'Maybe b' already
  (Just x) >>= f = f x
  Nothing >>= f = Nothing
  -- return :: a -> Maybe a
  return x = Just x
```

## The Monad Laws

Similarly to functors and applicatives, there are some laws which our `Monad` instance should abide by to act predictably. Once again, these are not enforced by the type system, so be careful!

1. Left identity:

`return x >>= f == f x` (`x :: a`, `f :: a -> m b`)

This should make intuitive sense, as `return` embeds a value in the monad, and then `>>= f` takes the value out of the monad and applies `f` to it. For our `Maybe` monad instance, we can substitute the definitions to trivially prove this identity holds:

```hs
return x >>= f
(Just x) >>= f -- substitute definition of return
f x            -- substitute definition of >>=
```

<ol start="2"><li>Right identity:</li></ol>
`x >>= return == x` (`m :: m a`)

In this identity, `x` must already be emdedded in the `Maybe` monad to typecheck. The following proof shows our implementation respects this identity.

```hs
x >>= return
-- Case 1: x = Nothing
Nothing >>= return
Nothing  -- apply definition of >>=, where f = return
x        -- apply definition of x
-- Case 2: x = Just x'
Just x' >>= return
return x' -- apply definition of >>=
Just x'   -- apply definition of return
x         -- apply definition of x
```

<ol start="3"><li>Associativity:</li></ol>
`m >>= (\x -> k x >>= h) == (m >>= k) >>= h`

This law is a little trickier to understand, but what it is saying is that `>>=` is (sort of) associative. Associativity means you can move the brackets around without affecting the result, that is: `a . (b . c) == (a . b) . c`, where `.` is a function. This is equivalent to saying `m >=> (k >=> h) == (m >=> k) >=> h`. The proof for our `Maybe` instance is not too tricky requiring only simple substitutions, however it is quite long, so it is left as an exercise to the reader.

If you have read my article on [monoids in Haskell]({% post_url 2020-8-2-monoids-in-haskell %}), you may now recognise that a monad is a monoid where the operation is `>=>`, the identity is `return`, and the set is the type `a -> m b`. This is related to the oft quoted phrase "a monad is just a monoid in the category of endofunctors". Haskell functors, and thus monads, are also [endofunctors in the category **Hask**]({% post_url 2020-8-4-functors-in-haskell %}#mathematical-background).

## The List Monad

We have touched on the `Maybe` monad, and now we will take a closer look at `[]`, and crucially, `IO`.

The list type constructor is a monad. It may seem strange at first, but remember that monads provide a context. For `Maybe`, this was the context in which functions can fail. Lists can be thought of as a context for non-deterministic computations, or computations with multiple results. If we want to sequence several functions `a -> [a]`, we can use the list monad. Going back to the type signature of `>>=`, if we supply a list of values, and a function from one value to a list, we can use `>>=` to sequence them by applying our function to each element in the list individually and aggregating the results.

Say we want to model a form of one dimensional [Brownian motion](https://en.wikipedia.org/wiki/Brownian_motion). We want the probability of arriving at a specific destination after `n` iterations, where each iteration we can move one position left or right, and we start at position zero. Yes, we could model it using math, and yes, the method below is $$\mathcal{O} (2^n)$$, but this is for demonstration purposes only.

We define a function `brownian` as follows, we get a function `a -> [a]`. It takes one state and gives all possible subsequent states.

```hs
brownian :: Int -> [Int]
brownian n = [n - 1, n + 1]
```

If we want to sequence this operation and get the list of possible states 2 iterations from now, we can use `>>=`. This applies our function to every value in our list, and concatenates the results into one list. This is because the return of `>>=` is `[b]`, not `[[b]]` like if we used `fmap brownian (brownian 0)`.

```hs
brownian 0 >>= brownian >>= brownian
-- => [-3,-1,-1,1,-1,1,1,3]
```

Then, we can iterate through this resultant list and find the probabilities we were after trivially. (Challenge: implement a function `nth_iteration_brownian :: Int -> [Int]` which computes `brownian 0 >>= brownian >>= ... >>= brownian` a total of `n` times.)

## Understanding `do` Notation

If you are trying to understand monads, you are probably already familiar with `do`-notation. This is syntactic sugar for monadic computations. In this section we will quickly recap `do`-notation and demonstrate how `do`-notation is translated into monadic code.

Here is a quick `do`-notation crash course:

- A `do` expression has the following syntax: `do { expression; another; etc }`. You can remove the braces and semicolons and put each expression on a newline for clarity.
- You can use `let` to define variables like `do { let x = 2; print x }`.
- Each expression other than `let` expressions must be monadic (type `m a`, not `a` or `a -> m b`.) Examples: `getLine`, `putStrLn x` (with argument), `safeSqrt`, `brownian`.
- You can unwrap variables from a monadic context. This means if you have for example an `IO String` returned from `getLine`, you can choose to pull the `String` part out like so: `do { string <- getLine; do_stuff_with_string }`.
- The value of the `do` expression is the last expression listed: `do {a;b;c}` returns `c`, assuming `c` is a monadic value.
- To return a non-monadic value, you can use `return`: `do {a' <- a; b' <- b; return a'}`.

The below snippet demonstrates unwrapping and variable declaration. Note that `putStrLn` does not need a meaningful return value, so it returns `IO ()`, where `()` (unit) is a type with only one possible value. This corresponds with the `IO ()` type of `main`.

```hs
main :: IO ()
main = do
  putStrLn "What is your name?"
  name <- getLine
  let greeting = "Hello, "++name
  putStrLn greeting
```

There are a few reasons to avoid `do`-notation in some cases. Although it improves readability, it obscures what is actually happening, leading to incomprehensible error messages. It is also overused; often a single line of concise monadic code can replace a multiline `do` expression.

There are also circumstances where `do` notation actually hinders readability. If you rewrote our Brownian motion code above to use `do` notation, what does it mean to extract values from a list monad? Effectively, every line after unwrapping a list runs once per item in the list. This means consecutive `new_state <- brownian old_state` expressions cause subsequent lines to be run exponentially more times than the last, which is not obvious at first glance.

It is important to make it clear that `do`-notation can only be used with monads. Additionally, it can only be used with one monad at a time. If you try unwrapping a `Maybe` value in an `do` block for `IO` actions, your program will not typecheck because of a type variable mismatch when implicitly using `>>=` behind the syntactic sugar. Aside: [Monad transformers](https://en.wikibooks.org/wiki/Haskell/Monad_transformers) allow you to combine monads and use multiple effects at once.

```hs
main = do
  putStrLn "What is your name?"
  let x = Just "Hello, "
  x' <- x -- Error: Couldn't match type ‘Maybe’ with ‘IO’
  name <- getLine
  putStrLn (x' ++ name)
```

Now, we will explore how `do`-notation is translated into code in terms of `>>=` and other monadic operators.

When you write an operation that does not extract a value, it is equivalent to using the `>>` operator. The `>>` operator runs two monadic functions, and 'chooses' the result of the second. There is an equivalent operator for applicatives, `*>`, which is only differently named because applicatives used to be unrelated to monads in Haskell. The following four lines are equivalent:

```hs
a >> b
do {a; b}
a *> b
a >>= (\_ -> b)
```

When you write an operation that does extract a value, you can use that value freely as a variable in the rest of the `do` expression. You should recall that `>>=` allows us to sequence a monadic operation by exposing the unwrapped value(s) in the function we bind. That is, `xs >>= (\x -> f x)` applies the function `f` to each unwrapped value from `xs`, thereby 'exposing' the values hidden inside our monad. This means that `do {x <- xs; f x}`is equivalent to `xs >>= (\x -> f x)`.

If you write code which repeatedly extracts values from monads, the addition of a function each time quickly spirals into spaghetti territory. Below is a side-by-side comparison:

```hs
do
  a' <- a
  b' <- b
  c' <- c
  d a' b' c'
-- translates to
a >>= (\a' -> (b >>= (\b' -> (c >>= (\c' -> d a' b' c')))))
```

However, often using monadic functions directly makes code more concise. Below is a translation of the original `do` notation example for comparison. This example is probably better written using `do`-notation, as although each step is simple there are a fair few consecutive actions.

```hs
main :: IO ()
main = putStrLn "What is your name?" >> fmap ("Hello, "++) getLine >>= putStrLn
-- or, a hybrid:
main = do
  putStrLn "What is your name?"
  fmap ("Hello, "++) getLine >>= putStrLn
```

The crux is that `do` notation is effectively just syntactic sugar for `>>` and `>>=`. Whenever you execute a monadic action without extracting a value in a `do` expression, that is equivalent to adding `>> ...` after. If you do extract a value, it is equivalent to writing `>>= (\value -> ...)` afterwards.

## The `IO` Monad

The implementation of `IO` as a monad is the main reason you need to be comfortable with monads to be an effective Haskell programmer. After all, even Hello World programs use monads under the hood.

The issue with pure functional programming is that input and output actions are side effects, and so a truly pure functional language is simply a glorified space heater. One of the main benefits of functional programming is its predictability -- you know when you call a pure function that it cannot break anything else. This means that the number of possible bugs scales linearly with respect to the size of your codebase, whereas in imperative programming languages, the number of bugs scales quadratically at best.

In order to maintain this predictability, the designers of Haskell decided to encode the possibility for side effects into the type system, so that pure functions cannot unintentionally cause side effects. The result was the `IO` monad. (In a sense, Haskell is a pure functional language, as the `main` function simply sequences `IO` values which the compiler replaces with impure actions on behalf of the programmer.)

The `IO` monad is actually one of the simplest monads to understand, as it wraps a single value. It is even simpler than `Maybe` in that respect. The complexity arises in that the values represent side effects.

Aside: while making `IO` type safe is all very well, sometimes you really need to print something in a pure function for debugging purposes. Instead of forcing you to propagate monadic values through a chain of pure functions up to `main` just to test one function, Haskell does provide an escape hatch to perform arbitrary `IO` actions. This is called `unsafePerformIO :: IO a -> a`, and can be used like `unsafePerformIO (putStrLn "test")`. Due to lazy evaluation it can sometimes be tricky to force the `IO` action to be performed. An example using the `BangPatterns` language extension to force strictness is in this article's corresponding source file. General advice: *do not use `unsafePerformIO` outside of debugging unless you know what you're doing*. You can introduce some very subtle bugs, so resist the temptation where possible.

By now, you should have a basic understanding of how to use monads, how to define them, and what their motivation is -- sometimes it is to abstract away boilerplate, other times it is to encapsulate impurity in a type-safe way.

If you still find the concept of a monad elusive, I fully empathise with you -- it is a very abstract concept where analogies can only go so far. At the end of the day you will have to learn the type signature of `>>=` one way or another.

If by now you are not convinced of how useful they are, [part four on monadic parsing]({% post_url 2020-8-9-parsing-arithmetic-with-monads %}) works through a concrete example which will thoroughly dispel any reservations.

[Part 4: Parsing Arithmetic with Monads]({% post_url 2020-8-9-parsing-arithmetic-with-monads %})

Source Code: [*`Monads.hs`*](/assets/code/Monads.hs)
