
import Control.Applicative -- for ZipList

-- Applicative definition
-- class Functor f => Applicative f where
--   pure :: a -> f a
--   (<*>) :: f (a -> b) -> f a -> f b

-- Defining a Functor given an Applicative
-- instance Functor SomeApplicative where
--   fmap f x = pure f <*> x

quadratic :: Int -> Int -> Int -> Int -> Int
quadratic a b c x = a*x^2 + b*x + c

-- the following are both equivalent to: Just (quadratic 3 4 (-2) 9)
-- main = print $ quadratic <$> (Just 3) <*> (Just 4) <*> (Just (-2)) <*> Just (9)
-- main = print $ pure quadratic <*> (Just 3) <*> (Just 4) <*> (Just (-2)) <*> Just (9)

-- instance Applicative Maybe where
--   pure = Just
--   (Just f) <*> (Just x) = Just (f x)
--   _ <*> _ = Nothing

-- Example of ZipList usage
-- main = print (
--   let xs = ZipList [0, 1, 3, 2]
--       ys = ZipList [3, 5, 2, 7]
--       result = (+) <$> xs <*> ys
--   in getZipList result)
-- prints [3, 6, 5, 9]

-- ZipList applicative instance
-- instance Applicative [] where
--   pure x = [x]
--   (f:fs) <*> (x:xs) = f x : (fs <*> xs)
--   _ <*> _ = []

-- normal list applicative instance
-- instance Applicative [] where
--   pure x = [x]
--   -- using map for readability; equiv. to fmap/<$>
--   fs <*> xs = concat [ map f xs | f <- fs ]
