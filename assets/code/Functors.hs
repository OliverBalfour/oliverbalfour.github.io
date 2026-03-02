import Data.Char (toUpper)

-- Functors in Haskell

squareList :: Num a => [a] -> [a]
squareList [] = []
squareList (x:xs) = x^2 : squareList xs

addMaybes :: Num a => Maybe a -> Maybe a -> Maybe a
addMaybes (Just a) (Just b) = Just (a + b)
addMaybes _ _ = Nothing

fmapList :: (a -> b) -> ([a] -> [b])
fmapList f [] = []
fmapList f (x:xs) = f x : fmapList f xs

squareList' = fmapList (^2)

-- The [] and Maybe functors

-- instance Functor [] where
--   fmap = map

squareMaybe :: Maybe Int -> Maybe Int
squareMaybe (Just x) = Just (x^2)
squareMaybe Nothing = Nothing

fmap' :: (Int -> Int) -> (Maybe Int -> Maybe Int)
fmap' f (Just x) = Just (f x)
fmap' f Nothing = Nothing

squareMaybe' :: Maybe Int -> Maybe Int
squareMaybe' = fmap' (^2)

-- main = print (squareMaybe' (Just 3))
-- prints 3^2==9

fmap'' :: (a -> b) -> Maybe a -> Maybe b
fmap'' f (Just x) = Just (f x)
fmap'' f Nothing = Nothing

sqrtMaybe :: Maybe Int -> Maybe Double
sqrtMaybe = fmap'' (sqrt . fromIntegral)
-- equiv. to: fmap'' (\x -> sqrt (fromIntegral x))

-- main = print (sqrtMaybe (Just 3))
-- prints 1.73...

-- instance Functor Maybe where
--   fmap f (Just x) = Just (f x)
--   fmap _ Nothing = Nothing

-- The IO Functor

stringToUpper :: String -> String
-- remember String is a type alias for [Char]
-- toUpper works on Char, so we map or fmap it
stringToUpper = fmap toUpper

{-
main = do
  -- apply stringToUpper to the value inside getLine
  a <- fmap stringToUpper getLine
  putStrLn a

OR:

main = do
  a <- getLine
  putStrLn (stringToUpper a)

OR:

main = fmap stringToUpper getLine >>= putStrLn
-}

-- BinaryTree functor

data BinaryTree a = Node a (BinaryTree a) (BinaryTree a) | Leaf a

{- Usage: the below tree is: Node 1 (Node 2 (Leaf 3) (Leaf 5)) (Leaf 6)
    1
   / \
  2   6
 / \
3   5   -}

instance Functor BinaryTree where
  fmap f (Node x left right) = Node (f x) (fmap f left) (fmap f right)
  fmap f (Leaf x) = Leaf (f x)


squareAllInFunctor :: (Functor f, Num a) => f a -> f a
squareAllInFunctor = fmap (^2)
-- squareAllInFunctor [1,2,3] == [1,4,9]
-- squareAllInFunctor (Just 3) == Just 9
-- -- two layers of functors (need to fmap twice, ie 'fmap (fmap (^2))')
-- fmap squareAllInFunctor [Just 2, Nothing, Just 5 ]
--                      == [Just 4, Nothing, Just 25]
-- -- our binary tree
-- squareAllInFunctor Node 1 (Node 2 (Leaf 3) (Leaf 5 )) (Leaf 6 )
--                 == Node 1 (Node 4 (Leaf 9) (Leaf 25)) (Leaf 36)
