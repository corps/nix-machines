import Hakken.Literal

def Escaped := String

inductive NodeTree : Type -> Type where
  | dtd : NodeTree Unit
  | html : dtd -> NodeTree Unit
  | head : html -> NodeTree Unit
  | body : html -> NodeTree Unit
  | title : head -> NodeTree Unit
  | text : NodeTree String -> NodeTree Unit


-- contents <- do
--    text "Hello World"
--    text "This would do"
--    text "The thing to do."
--    text "or the thing?"
--  title
--   cointents <$>
  -- | dtd : NodeTree "HTML" -> NodeTree "DTD"
  -- | html (head: NodeTree "HEAD") : Option (NodeTree "BODY") -> NodeTree "HTML"
  -- | head : List (NodeTree "head-element" ⊕ NodeTree "SCRIPT" ⊕ NodeTree "STYLE") -> NodeTree "HEAD"
  -- | body : List (NodeTree "body-element" ⊕ NodeTree "SCRIPT" ⊕ NodeTree "STYLE") -> NodeTree "BODY"
  -- | httpEquiv : String -> String -> NodeTree "META"
  -- | title : String -> NodeTree "TITLE"
  -- | g : NodeTree.dtd -> NodeTree "TITLE"

-- private inductive Node : (tag: String) -> Type where
-- | html (head: Node "HEAD") (body: Node "BODY") : Node "HTML"
-- | head (contents: List (Node "SCRIPT" ⊕ Node "META" ⊕ Node "LINK")) : Node "HEAD"
-- | body (contents: List (Node "DIV")) : Node "BODY"
-- | text (contents: String) : Node "TEXT"

def escape (s: String) : Escaped :=
  s.replace "&"  "&amp;"
    |> .replace "<" "&lt;"
    |> .replace ">" "&gt;"
    |> .replace "\"" "&quot;"
    |> .replace "'" "&#x27;"
