{-# LANGUAGE BangPatterns #-}
import Data.Char (toUpper)
import System.IO.Unsafe

safeInverse :: Double -> Maybe Double
safeInverse 0 = Nothing
safeInverse x = Just (1 / x)

safeSqrt :: Double -> Maybe Double
-- signum is -1 for negatives, 0 for 0 and 1 for positives
safeSqrt x = case signum x of
  (-1) -> Nothing
  _ -> Just (sqrt x)

-- Approach #1: join (flatten two layers of monad into one)

join :: Maybe (Maybe a) -> Maybe a
join (Just x) = x
join Nothing = Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse = join $ fmap safeInverse (safeSqrt x)

-- more generally:
-- join :: Monad m => m (m a) -> m a

-- Approach #2: fish (Kleisli composition)
--
(>=>) :: (a -> Maybe b) -> (b -> Maybe c) -> (a -> Maybe c)
f >=> g = \x -> case f x of
  Just x -> g x
  Nothing -> Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse = safeSqrt >=> safeInverse

-- more generally:
-- (>=>) :: Monad m => (a -> m b) -> (b -> m c) -> a -> m c

Approach #3: bind (apply monadic value to monadic function)

(>>=) :: Maybe a -> (a -> Maybe b) -> Maybe b
x >>= f = case x of
  (Just x') -> f x'
  Nothing -> Nothing

sqrtInverse :: Double -> Maybe Double
sqrtInverse x = safeSqrt x >>= safeInverse

-- Mappings between three approaches

join x = x >>= id
join x = const x >=> id
f >=> g = \x -> f x >>= g
f >=> g = \x -> join (f . g $ x)
x >>= f = join (f <$> x)
x >>= f = (const x >=> f) ()

-- Maybe Monad

data Maybe a = Just a | Nothing

instance Monad Maybe where
  (Just x) >>= f = f x
  Nothing >>= f = Nothing
  return = Just

instance Applicative Maybe where
  pure = return
  -- (<*>) :: Maybe (a -> b) -> Maybe a -> Maybe b
  (Just f) <*> (Just x) = Just (f x)
  _ <*> _ = Nothing

instance Functor Maybe where
  fmap f (Just x) = Just (f x)
  fmap f Nothing = Nothing

-- do notation

main :: IO ()
main = do
  putStrLn "What is your name?"
  name <- getLine
  let greeting = "Hello, "++name
  putStrLn greeting
-- equivalent to
main = putStrLn "What is your name?" >> fmap ("Hello, "++) getLine >>= putStrLn

-- unsafePerformIO (BE CAREFUL!)
-- {-# LANGUAGE BangPatterns #-}
-- import Data.Char (toUpper)
-- import System.IO.Unsafe
purefunc :: String -> String
purefunc cs = let !_ = unsafePerformIO (putStrLn "test") in map toUpper cs
main = getLine >>= (\cs -> putStrLn (purefunc cs))

-- -- or:
-- purefunc cs = unsafePerformIO $ do
--   putStrLn "test"
--   return (map toUpper cs)
