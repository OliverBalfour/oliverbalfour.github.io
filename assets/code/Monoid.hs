{-# LANGUAGE GeneralizedNewtypeDeriving #-}
-- above extension is to automatically derive Num instance

instance Semigroup Int where
  (<>) = (+)

instance Monoid Int where
  mempty = 0
  mappend = (<>)

-- 1 <> 1 == mappend 1 1 == 2

newtype IntMultiply = IntMultiply { num :: Int }
  deriving (Num, Show, Eq, Ord)

instance Semigroup IntMultiply where
  (<>) = (*)

instance Monoid IntMultiply where
  mempty = 1
  mappend = (<>)

-- num (IntMultiply 5 <> IntMultiply 4) == 20
