---
layout: post
title: "Monoids in Haskell"
categories: haskell
---

Haskell is heavily reliant on common constructs derived from abstract algebra and category theory, branches of advanced mathematics that many programmers, myself included, have very little formal exposure to. This post is designed to make the concept of monoids and their application in Haskell a little less intimidating.

Abstract algebra is a field of mathematics which studies algebraic structures. In addition to the algebra you learn in high school, there are other algebraic structures such as linear algebra (dealing with vectors and matrices and operations on them), Boolean logic, and even Rubik's cubes. Each of these algebraic structures differs in several key ways:

1. They deal with different sets of objects. They could be numbers, matrices, true/false values, or the possible states of a Rubik's cube.
2. The operations are different. With numbers you have addition and multiplication, with matrices you have matrix multiplication, and with Rubik's cubes you have rotations of faces.
3. The operations have different properties. Real multiplication is commutative, meaning `a * b == b * a`, and matrix multiplication is associative, meaning `A * (B * C) == (A * B) * C`.

Abstract algebra generalises the notion of an algebra beyond these examples, into very abstract structures like monoids. Think of them as 'abstract base classes' for maths which allow proofs to be polymorphic, so to speak. Their motivation in maths is to allow proofs about one system to apply to other systems with the same rules, and in Haskell they allow a greater degree of polymorphism. They revolve around a set of objects, some operations that can combine them, and properties of those operations.

## Mathematical Definition

The formal definition of a monoid is an **algebraic structure** which has an **associative binary operation** over a set with an **identity element**.

When we talk about a set, we mean a collection of objects, like real numbers in elementary algebra or matrices in linear algebra. When we translate this into Haskell, we talk about types and not sets. That is, we talk about the type `Int` instead of using a data structure storing all integers, for obvious reasons.

We also have a binary operation. This means we have a function that takes two elements of a type and produces another, like `a -> a -> a`. This implicitly means our operation is closed -- we cannot combine two elements in our set and produce one outside of it. Many operations are not closed, for instance the square root over the reals. However, if a function of type `a -> a -> a` typechecks and cannot throw runtime errors, it is safe to assume it is closed.

Our binary operation must be associative to be a monoid. The Haskell type system is not powerful enough to check associativity, so you should verify yourself that `f(f(a, b),c) == f(a,f(b,c))` or `(a . b) . c == a . (b . c)` for any possible values `a,b,c` of your type. This might seem arbitrary, but it can be immensely useful. When multiplying a chain of matrices for instance, you can reduce the total number of calculations by [optimising the order of multiplications](https://en.wikipedia.org/wiki/Matrix_chain_multiplication).

We also recognise the presence of an identity element. This is an element `e` of the set which satisfies the rule `f(a,e) == f(e,a) == a` or `a . e == e . a == a`. That is, applying the identity element does nothing to the other operand. Under addition over the reals, the identity is 0, as `x + 0 = 0 + x = x`. For multiplication, `e = 1` as `1 * x == x * 1 == x`. For square matrices, the identity matrix is the identity of multiplication.

To summarise, from a mathematical standpoint a monoid is:

- A set (type) equipped with a binary operation/function.
- The binary operation must be closed (its return value is in the same set / of the same type).
- It must be associative, meaning `(a . b) . c == a . (b . c)` for all `a,b,c`.
- There must be an identity element `e` such that `a . e == e . a == a` for all `a`.

Due to the level of abstraction this definition is at, even non-numerical sets and operations can be monoidal. For example, string concatenation (or list concatenation in general) is monoidal, where the empty string (or list) is the identity. Intuitively, `("foo" ++ "bar") ++ "baz" == "foo" ++ ("bar" ++ "baz")` and `"foo" ++ "" == "" ++ "foo" == "foo"`. This is purely to build intuition, naturally this is not sufficient to prove correctness in general.

Some examples of monoids are listed below. To get a better understanding of each of these examples, try verifying that each adheres to the properties summarised above.

- Addition over the integers or reals, with identity 0
- Multiplication over the integers or reals, with identity 1
- String concatentation, with identity `""`
- Square matrix multiplication, with the identity matrix as the identity
- List concatenation, with identity []
- Function composition (`h = f . g` means `h(x) = f (g x)`), with identity `id x = x`.
- Instances of Haskell's [`Alternative` typeclass]({% post_url 2020-8-9-parsing-arithmetic-with-monads %}#the-alternative-typeclass) with operation `<|>` and identity `empty`.

Aside: The union and intersection of sets are also monoidal operations. The identity for union is the empty set $$\emptyset=\{\}$$, and for intersection it is the universal set (that is, the set of all values in the context you are working, such as the set of real numbers). If you wished to describe the intersection as a monoid in Haskell, you would have a hard time if you used a data structure like from `Data.Set` to describe a potentially infinite set. Instead, you could represent a set as a function `Item -> Bool` which tests membership, so you do not need to store every possible value in memory. Using a membership function is isomorphic (structurally equivalent) to using a set data structure. Then intersection is the logical and operator `&&`, and union becomes `||`.

## Representation in Haskell

In Haskell, monoids are represented by a typeclass `Monoid`, which contains the identity element `mempty` and the associative binary operation `mappend`. As we translate sets in maths to types in Haskell, a monoid over the set of integers would be represented as a `Monoid Integer` instance.

You may have noticed by now that you can define several monoids over the same set -- for example, addition and multiplication are both monoids over the real numbers. However, in Haskell you can only instantiate a typeclass once per type. There are ways of working around this which we will touch on later. This is one reason why you will see relatively very few instances provided by default if you type `:info Monoid` in GHCi. It is important to clarify that you can create monoids in Haskell that do not have a `Monoid` instance, and many monoids you encounter will not. Recognising them for what they are either way will make working with them easier, as all monoids behave in very similar ways.

Suppose we want to define a monoid instance for integer addition. We need to define the `mempty` and `mappend` fields. Note that the name `mappend`, short for monoid append, is somewhat of a misnomer biased toward list-like types, which many monoids are not. The syntax for this is as follows.

```hs
instance Monoid Int where
  mempty = 0
  -- equivalently: mappend a b = a + b
  mappend = (+)
```

However, if we try to run this via `ghci monoid.hs`, you will notice the compiler complains we have not defined a `Semigroup` instance. This is because `Monoid` is a subclass of another typeclass called `Semigroup`. In abstract algebra, a semigroup is basically a monoid which does not necessarily have an identity element. That is, all monoids are semigroups, but semigroups are only monoids if they have an identity element. Even though we can easily derive any `Semigroup` instance from a `Monoid` instance as the interface of the latter is sufficient to define the former, we must still manually declare an instance for our program to typecheck. The only function we need to define is `(<>) :: a -> a -> a`, our binary function. So, for any `Monoid` we can define a corresponding `Semigroup` as follows:

```hs
instance Semigroup Int where
  (<>) = mappend
```

Once we combine the two definitions and run `ghci Monoid.hs`, we can enter expressions like `3 <> 5 :: Int` and `mappend mempty 3 :: Int`. We must provide the type annotations to tell Haskell the numbers we are typing are specifically of the `Int` type, and not stand-ins for any type with a `Num` instance.

Notice that if you simply enter `mempty`, it does not show up with 0. This is because `mempty` is a polymorphic variable, and its type is deduced from context. For example, if you run `(2 :: Int) <> mempty`, the compiler will infer you mean `mempty :: Int`. To give it context, try `mempty :: Int`, and you will see 0. Also, notice that if you try setting `mempty` to a non-zero value so the monoid rules do not hold, the compiler will not stop you. This is because the type system is incapable of asserting these rules hold. However, it may result in strange side effects because many library functions assume these laws hold. For this reason, it is always worth ensuring any `Monoid` instances you write adhere to these rules.

Now that we have covered what monoids are and how they work in Haskell, here are some monoids you could try implementing instances for:

1. The `String` type with concatenation and identity `""`
2. Function composition with identity `id`. Can you do this in Haskell's type system? Does it conflict with existing instances?
3. Matrix multiplication. Try defining your own matrix type and implementing a multiplication algorithm. Is it a monoid if matrices are non-square? Can you make it a monoid, for example by wrapping in `Maybe`? Can you override `mconcat`, a function defined by default as `foldr mappend mempty`, which reduces a list of values to one using `mappend`, to minimise the number of multiplication and addition operations by exploiting associativity?

It is also worth mentioning is how to define multiple `Monoid` instances for the same type. Technically, you cannot do this. However, if we use the `newtype` keyword to wrap an existing type, Haskell will make sure we do not mix up our two types, and so it can tell which `Monoid` instance to use. We define an integer multiplication monoid below in this style. Note that to use this, we need to use the `IntMultiply` value constructor to wrap values and the `num` function to unwrap values. This means `4 * 5` becomes `num (IntMultiply 5 <> IntMultiply 4) == 20`. We also need to define a `Num` instance to have access to the `(*)` function, which we can do automatically via the `GeneralizedNewtypeDeriving` extension. Due to the complexity of this approach, it is vary rare to see multiple instances of a typeclass for any one type (one example is `ZipList` in `Control.Applicative`).

```hs
{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- above extension is to automatically derive Num instance

-- we use record syntax to generate a 'num :: IntMultiply -> Int'
-- function that unwraps our values
newtype IntMultiply = IntMultiply { num :: Int }
  deriving (Num, Show, Eq, Ord)

instance Semigroup IntMultiply where
  (<>) = (*)

instance Monoid IntMultiply where
  mempty = 1
  mappend = (<>)
```

## Application of `Monoid`s

Now that we have covered what monoids are and how to define a `Monoid` instance, you may be a little confused about what their purpose is. Aside from simply making it easier to reason about the behaviour of similar algebraic structures, there is a very practical reason to use monoids in Haskell, and that is polymorphism.

Logging is a ubiquitous task in programming. Any large scale service likely has log files stowed away to aid in debugging and monitoring. Writing to a log file is an inherently impure IO action. To maintain purity of a Haskell program which requires logging, the [`Writer` monad](https://kseo.github.io/posts/2017-01-21-writer-monad.html) exists. If you are not comfortable with monads, I have a series about them working from their descendants, [functors]({% post_url 2020-8-4-functors-in-haskell %}) and [applicatives]({% post_url 2020-8-6-applicative-functors %}), to [monads themselves]({% post_url 2020-8-8-understanding-monads-haskell %}) and [using monads in practice]({% post_url 2020-8-9-parsing-arithmetic-with-monads %}).

The `Writer` monad effectively encapsulates the ability to produce a stream of data in addition to the main computations, which can be used for logging. (There are more efficient ways, but this is just an example.) However, different log files may need different formats, so if the `Writer` monad simply used a string, appending newline-separated messages on the end each time, in many situations you would have to create your own version of the `Writer` monad because it is arbitrarily restrictive.

To make the `Writer` monad more polymorphic, it actually uses a `Monoid` you specify to allow you control over how to aggregate data you stream to it. Not only does this mean you can use `Writer` for different log file formats, but you can also change formats trivially. You can also use `Writer` for code generation, maintaining state (although there is also a `State` monad), and numerous other purposes.

This is just one example of where the `Monoid` type class, despite seeming rather contrived, abstract and mathematical, is actually invaluable. Hopefully you now have a solid handle on what monoids are, how they are created and used in Haskell, and crucially, why they are useful.

*Source code for this article: [`Monoid.hs`](/assets/code/Monoid.hs)*
