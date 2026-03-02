---
layout: post
title: "The Road to Monads 2: Applicative Functors"
categories: haskell
---
This is the second article in a series on understanding monads in Haskell. If you have not already, feel free to check out the other posts below:

1. [Functors in Haskell]({% post_url 2020-8-4-functors-in-haskell %})
2. [Applicative Functors]({% post_url 2020-8-6-applicative-functors %})
3. [Understanding Monads]({% post_url 2020-8-8-understanding-monads-haskell %})
4. [Parsing Arithmetic with Monads]({% post_url 2020-8-9-parsing-arithmetic-with-monads %})

In this article, we will build on functors, introduced in part one, to introduce applicative functors. Applicative functors, or applicatives, essentially allow you to `fmap` functions of multiple variables over multiple different values of the same functor instance. For example, they allow you to add two `Maybe` values together. Despite being a superset of monads, applicatives are in my opinion far more difficult to understand. If you can understand applicatives, then monads will be significantly easier to understand in [part three]({% post_url 2020-8-8-understanding-monads-haskell %}).

## An Evolution of `Functor`

Functors in Haskell are wrappers for values of a certain type, with a means to promote normal functions to work on them. Specifically, the function `fmap` in the `Functor` typeclass takes a function of type `a -> b` and produces another of type `f a -> f b` for some functor `f`, which applies the original function to values stored inside. However, functors do not allow us to promote a function of multiple variables (eg of type `a -> b -> c`) to work on a functor. For example, we cannot multiply two `Maybe Int` values with `fmap` alone.

This is where applicative functors come in. Some examples of applicatives include `Maybe`, `[]`, `IO`, and all of the monads. They provide a means for you to apply a function to multiple functorial arguments. The way this works is counterintuitive -- you use `fmap` on a multivariate function and one functor argument to *embed a partially applied function in the functor*, and then use the `<*>` operator for applicatives to *evaluate a functor filled with functions on a functor filled with values*, and you continue this process until all the arguments have been supplied. When you consider we could be working with highly non-trivial functors like trees, it becomes even more difficult -- what does it mean to apply a tree of partially applied functions to a tree of values? Is there even a logically consistent way to do so? We will work through this concept one step at a time with examples aplenty, but it suffices to say applicatives are *very* difficult to understand.

A few notes before we start:
1. Not all functors can become applicatives. Many can, some cannot. Just something to keep in mind. The same goes for monads: not all applicatives can become monads.
2. Not every functor *should* be made an applicative functor. For instance, while the applicative style may make sense for `Maybe` where you can use it to apply binary functions that fail if either argument is `Nothing`, it does not make much sense for `BinaryTree`. What does it mean to apply a tree of functions to a tree of values? Even if it is possible to define an applicative instance that upholds all of the rules, outside of [very specific use cases](https://blog.plover.com/prog/haskell/applicative.html), it is not very practical to do so.
3. There may be multiple ways to define an applicative functor for the same functor, in the same way you can [define multiple monoids]({% post_url 2020-8-2-monoids-in-haskell %}) over the same set. An example we will investigate further is the two list applicative functors, `[]` and `ZipList`.

## The `Applicative` Typeclass

I have included the minimal definition of the `Applicative` typeclass below:

```hs
class Functor f => Applicative f where
  pure :: a -> f a
  (<*>) :: f (a -> b) -> f a -> f b
```

The first thing you will notice is the `Functor` constraint. This means GHC will complain if you define an `Applicative` instance without an accompanying `Functor` instance, even though as we will see you can always define a `Functor` in terms of an `Applicative` via `fmap f a = pure f <*> a`.

The second line has the `pure` function, which 'lifts' a value of any type into the functor. The idea here is that functors provide context, and `pure` allows you to put a value in a functor with minimal/default context. For `Maybe`, that means `pure x` should really be defined as `Just x` and not `Nothing`, because `Just` is the default, in a sense.

Remember that function types `a -> b` are types too, so `pure` can lift a function *inside the functor*. What I mean by this is if we are working with the `Maybe` applicative, `pure (+1)` becomes `Just (+1)` with type `Maybe (a -> a)` (where `a` is numeric of course).

The second function in the `Applicative` typeclass is the more intimidating `<*>` operator. You may notice similarity to the type signature of `fmap`; I have included both below for comparison:

```hs
(<*>) :: f (a -> b) -> f a -> f b
fmap  ::    a -> b  -> f a -> f b
```

The only difference is that for `<*>`, the function we are applying inside our functor is actually *embedded inside our applicative functor*, like `Just (+1)` was above. This is where the idea of lifting a function into our functor via `pure` comes in handy: for `fn :: a -> b`, `pure fn` has type `f (a -> b)`, so `pure fn <*> a` has type `f b`, where `f` is an applicative and `a` is a functorial value. This means that `fmap fn a` is equivalent to `pure fn <*> a`, so you can define the functor instance of any corresponding applicative functor by simply writing:

```hs
-- we have to already have an Applicative instance
-- to use pure and <*>; but this works for all applicatives
instance Functor SomeApplicative where
  fmap f x = pure f <*> x
```

Now, you may be wondering what the point of all this is. If the type of the embedded function is `a -> b`, we can only use it for functions with one parameter, right? Once again, remember that we can hide functions in type variables as functions have concrete types too. By this, I mean in `a -> b`, `b` could actually be the type `c -> d -> e`, depending on context. The reason this is important is that `f (a -> b)` could actually refer to a function of several variables. When we apply `<*>` to our first functorial argument, we produce `f b`. If `b` is a function type, this means we have partially applied one argument to our embedded functions. We now once again have a type `f (a -> b)` if we hide the remaining arguments in our `b` type variable. So in the example given, after applying `<*>` once, `a` is `c`, and `b` is `d -> e`. This means we can apply two more arguments of type `f c` and `f d` using `<*>` to finally get a result of type `f e`.

To illustrate this process, think about the expression `pure (+) <*> Just a <*> Just b`. Note that `<*>` is left-associative, so `a<*>b<*>c == (a<*>b)<*>c`. First, we embed `(+)` in the `Maybe` applicative, getting `(Just (+) <*> Just a) <*> Just b`. Then, we apply the first `<*>`, which means we apply the embedded `(+)` to the embedded `a` and get the partially applied `Just (+a) <*> Just b`. Finally, we apply the second `<*>` and get `Just (a+b)`.

This means that `<*>` *partially applied* the embedded functions with the embedded value. We can repeat this process for functions of more than two variables by adding as many `<*> another_arg` terms as we need. Taking this to the logical extreme, if we have a function that evaluates a quadratic equation $$ax^2+bx+c$$ for some $$a,b,c,x$$, and we are using `Maybe` values, this could be written as follows. Aside: `<$>` is an infix synonym for `fmap`, so `fmap f x == f <$> x == pure f <*> x`. It is often convenient to use `<$>` to apply the first argument and embed the function at the same time, as below.

```hs
quadratic :: Int -> Int -> Int -> Int -> Int
quadratic a b c x = a*x^2 + b*x + c

-- the following are both equivalent to: Just (quadratic 3 4 (-2) 9)
quadratic <$> (Just 3) <*> (Just 4) <*> (Just (-2)) <*> Just (9)
pure quadratic <*> (Just 3) <*> (Just 4) <*> (Just (-2)) <*> Just (9)
```

## Deriving `Applicative Maybe`

As with the `Functor Maybe` instance, we pattern match and return `Nothing` if either operand is `Nothing`, otherwise we return `Just (f x)`. A simple implementation is included below.

```hs
instance Applicative Maybe where
  pure = Just
  (Just f) <*> (Just x) = Just (f x)
  _ <*> _ = Nothing
```

Using this instance we can now write `(+) <$> Just 2 <*> Just 3`, and see `Just 5` pop up in GHCi. Neat!

We will now briefly take a look at the laws for applicatives. Similarly to functors, there are certain rules your implementation must abide by, which the Haskell compiler cannot enforce. These rules, taken directly from the [documentation](https://hackage.haskell.org/package/base-4.14.0.0/docs/Prelude.html#t:Applicative), are listed below. Compared to the `Functor` and `Monad` laws, these are quite involved. I have included a simple proof of the identity law for our `Maybe` instance; the rest are left as an exercise (don't worry, they are not too tricky).

1. Identity: `pure id <*> x == x`. This is equivalent to the identity law for `Functor` instances, `fmap id x == x`, if the `Applicative` instance is correct. This law needs to be verified even if the `Functor` instance is valid.

2. Composition: `pure (.) <*> u <*> v <*> w == u <*> (v <*> w)`. This is difficult to understand, but what it says is that `(u . v) w == u (v w)`, only `u, v` are applicatives with functions embedded in them, and `w` is a normal applicative value. If rule one holds, this is equivalent to `(.) <$> u <*> v <*> w == u <*> (v <*> w)`.

3. Homomorphism: `pure f <*> pure x == pure (f x)`. This is fairly easy to understand and prove. Make sure in the `Maybe` example you verify it works for combinations of `Nothing` values.

4. Interchange: `f <*> pure x == pure ($ x) <*> f`. This is a particularly interesting rule, which is equivalent in the realm of normal values to `f x == ($ x) f`. This is a little tricky at first, but what is happening here is we are partially applying `$`, the function application function, so `$ x` takes a function and applies it to `x`. Once you understand this, this rule is not too difficult to prove.

The following is a simple proof of the identity rule for our `Maybe` instance. Note that `x = Just y`.

```hs
pure id <*> x
Just id <*> x
-- 'y' because we unwrap the Just in the pattern match:
Just (id y)
Just y
x
-- Thus, pure id <*> x == x for all Maybe a values x
```

In practice you may not thoroughly prove all of these rules, however it is good practice to do so, as they can cause strange side effects in very unexpected places if they do not hold. It is because of these rules that some `Functor` instances cannot have a corresponding `Applicative` instance; sometimes it is not possible to define an instance which upholds all of the rules.

A word on `pure`: you may have noticed that it is defined as the default value constructor for `Maybe`, and (correctly) guessed that `pure` for lists is the value constructor `[]` (ie `pure x = [x]`). Many applicatives do define `pure` as their 'default' value constructor, however this is not always the case. For example, in [part four](2020-8-9-parsing-arithmetic-with-monads.md) we define a `Parser` monad and applicative, which is a newtype wrapper for a function. However, the values we embed via `pure` are normal values, so we cannot define pure as a constructor. Rather we define it as a parser which returns that value and returns its input: `pure x = Parser (\cs -> (x, cs))`.

## The List `Applicative` Instances

As I mentioned at the start, in some cases it is possible to define an applicative for the same functor in multiple different ways. Lists are a very good example of this, and in fact the standard library includes both possible `Applicative` instances. The latter uses a `newtype` wrapper because Haskell does not allow multiple typeclass instances for the same type, and is called `ZipList`.

When we have a normal function we would like to apply to a list of values, the obvious approach is to apply the function individually to each item in the list. However, when we delve into applicative territory we need a way to apply a functor containing functions to another functor containing values. In this context, that means applying a list of functions to a list of values.

The obvious way to apply a list of functions `[f, g, h]` to a list of values `[a, b, c]` is to apply them one-by-one, like zipping two lists into a list of tuples. This would give us `[f a, g b, h c]` as a result. To deal with differently sized lists, we could take the approach `zip` takes and terminate when either list runs out (which is why `zip some_list [0..]` works, which is useful for getting `(value, index)` pairs). We could implement this fairly easily:

```hs
instance Applicative [] where
  pure x = [x]
  (f:fs) <*> (x:xs) = f x : (fs <*> xs)
  _ <*> _ = []
  -- or: fs <*> xs = [f x | (f, x) <- zip fs xs]
```

Interestingly, this approach similar to zipping is relegated to a newtype synonym called `ZipList` in the `Control.Applicative` module. This means if you want to add corresponding numbers in two lists for instance, you would have to write:

```hs
import Control.Applicative
main = print (
  let xs = ZipList [0, 1, 3, 2]
      ys = ZipList [3, 5, 2, 7]
      result = (+) <$> xs <*> ys
  in getZipList result)
-- prints [3, 6, 5, 9]
```

Rather, the default `Applicative []` instance takes a different approach -- it applies every function to every value, and flattens the resulting array. That is, `[f, g] <*> [a, b] == [f a, f b, g a, g b]`. Note that you could define yet another applicative instance which returns the transpose `[f a, g a, f b, g b]`, but this is not as useful, and it is simple to convert the output of the former to the latter. The default instance is implemented below:

```hs
instance Applicative [] where
  pure x = [x]
  fs <*> xs = concat [ map f xs | f <- fs ]
```

The reason this is the default implementation is that the list monad instance is derived from this applicative instance, not `Applicative ZipList`, so `ZipList` is relegated to a `newtype` synonym to make using lists as monads easier. It is not actually possible to derive a monad from `ZipList`, for [these reasons](http://haskell.1045720.n5.nabble.com/ZipList-monad-anyone-td3131044.html).

## Takeaways

Once you have your `Applicative` instances set up for the types you are working with, all you need to do to apply functions to them is write `f <$> a <*> b <*> c` instead of `f a b c`. This applies to a normal function `f` and three values of the same applicative `a,b,c`. You can change the number of arguments and use a mix of functorial and normal values using the notes below. Just remember the result will be functorial too.

- If your function is already embedded in your applicative, simply use `<*>` instead of `<$>` for the first argument.
- Note that for one argument, `f <$> a` is equivalent to `fmap f a`, as `<$>` is an infix synonym for `fmap`. For each additional argument just add `<*> arg` to the end.
- If you need to embed something in your functor, just use `pure`. For example, if you want to write `f a b c` where only `a,c` are functorial, and `b` is a normal value, you can write `f <$> a <*> pure b <*> c`.
- If it typechecks and your `Applicative` instance is correct, it probably does what you expect!

In the next part we will finally take a look at monads, represented in Haskell as the `Monad` typeclass with functions `return` and `>>=`. If you want a head start, then `return` is equivalent to `pure`! They are only named differently for historical reasons.

[Part 3: Understanding Monads]({% post_url 2020-8-8-understanding-monads-haskell %})

Source Code: [*`Applicatives.hs`*](/assets/code/Applicatives.hs)
