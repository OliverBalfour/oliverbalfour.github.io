
import Data.Char (isDigit, isSpace)
import Control.Applicative

newtype Parser a = Parser { parse :: String -> [(a, String)] }

item :: Parser Char
item = Parser (\cs -> case cs of
  "" -> []
  (c:cs) -> [(c,cs)])

satisfy :: (Char -> Bool) -> Parser Char
satisfy pred = item >>= (\c -> if pred c then pure c else empty)

char :: Char -> Parser Char
char c = satisfy (== c)

instance Functor Parser where
  fmap f (Parser p) = Parser (\cs ->
    map (\(x, cs') -> (f x, cs')) (p cs))

digit :: Parser Int
digit = fmap (read . (:[])) (satisfy isDigit)

instance Applicative Parser where
  pure x = Parser (\cs -> [(x, cs)])
  f <*> a = Parser (\cs ->
    concat [parse (fmap fn a) cs' | (fn, cs') <- parse f cs])

instance Monad Parser where
  return = pure
  p >>= f = Parser (\cs ->
    concat [parse (f a) cs' | (a, cs') <- parse p cs])

instance Alternative Parser where
  empty = Parser (\_ -> [])
  p <|> q = Parser (\cs ->
    let (p', q') = (parse p cs, parse q cs) in
    if length p' > 0 then p' else q')

space :: Parser String
space = many (satisfy isSpace)

string :: String -> Parser String
string "" = return ""
string (c:cs) = (:) <$> char c <*> string cs

token :: String -> Parser String
token symb = space *> string symb

mul :: Parser (Int -> Int -> Int)
mul = token "*" *> pure (*) <|> token "/" *> pure div

add :: Parser (Int -> Int -> Int)
add = token "+" *> pure (+) <|> token "-" *> pure (-)

pow :: Parser (Int -> Int -> Int)
pow = (token "^" <|> token "**") *> pure (^)

integer :: Parser Int
integer = let positive = fmap read (some (satisfy isDigit))
          in space *> unary_minus positive

unary_minus :: Parser Int -> Parser Int
unary_minus p = char '-' *> fmap negate p <|> p

chainl1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainl1` op = p >>= rest
  where rest a = ((op <*> pure a <*> p) >>= rest)  <|> return a

chainr1 :: Parser a -> Parser (a -> a -> a) -> Parser a
p `chainr1` op = p >>= rest
  where rest a =  (op <*> pure a <*> (p >>= rest)) <|> return a

expr = subexpr `chainr1` pow `chainl1` mul `chainl1` add
subexpr = token "(" *> expr <* token ")" <|> integer

repl :: String -> String
repl cs = let results = parse expr cs in
  case results of
    [] -> "Invalid expression"
    ((num, _):_) -> show num

main :: IO ()
main = interact (unlines . map repl . lines)
