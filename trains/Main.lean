import Trains
import Parser

def main : IO Unit :=
  IO.println s!"Hello, {hello}!"

def NodeId := Int deriving Repr, Inhabited
def NodePair := NodeId × NodeId deriving Repr, Inhabited
def Distance := Int deriving Repr, Inhabited
def Edge := NodePair × Distance deriving Repr, Inhabited
def TrainPos := NodeId × Distance deriving Repr, Inhabited
def TrainSpeed := Int deriving Repr, Inhabited
def Train := TrainPos × TrainSpeed deriving Repr, Inhabited

structure TrainNetwork where
  edges: List Edge
deriving Repr, Inhabited

structure TrainState where
  trains: List Train
deriving Repr, Inhabited

abbrev NetworkConstructorM := StateM TrainNetwork
abbrev TrainStateM := StateM TrainState
abbrev TrainSim := ReaderT TrainNetwork TrainStateM


namespace TrainPos
  instance : Coe NodeId TrainPos where
    coe α := (α, (0 : Int))

end TrainPos

--- Validated that this unifies to a monad with this, then check the message to see the instance
#synth Monad TrainSim
--- This is the instance that does the work.
#check ReaderT.instMonad

def add_train (pos : TrainPos) (speed: TrainSpeed) : TrainStateM Unit := do
  let cur ← get
  let train : Train := (pos, speed)
  set $ { cur with trains := cur.trains.concat train }
  pure ()

inductive IsLte (max: Nat) : Type where
  | gte (n: Nat) : (n ≤ max) → IsLte max

set_option diagnostics true
instance : OfNat (IsLte a) a where
  ofNat := .gte a (by simp)

instance : Inhabited (IsLte a) where
  default := .gte a (by simp)

instance : Coe (IsLte x) (IsLte $ x + 1) where
  coe t := match t with
    | IsLte.gte n a => .gte n $ Nat.le_add_right_of_le a

example : IsLte 24 := .gte 23 (by simp)

abbrev IsLte.IsGte : IsLte a → Nat
  | gte n _ => n

abbrev Hour := IsLte 23
abbrev Minute := IsLte 59

abbrev StringParser := Parser Unit Substring Char
abbrev LteParser (x: Nat) := StringParser $ IsLte x

def zeroParser {t: Type} (p: StringParser t) : LteParser 0 :=
  (Function.const t (IsLte.gte 0 $ by simp)) <$> p

def succParser {t: Type} (sp: StringParser t) (prev: LteParser x): (LteParser $ x + 1) :=
  (prev : LteParser $ x + 1) <|> (Function.const t (IsLte.gte (x + 1) $ by simp)) <$> sp

def optionalPositionParser (p: LteParser x) : LteParser x :=
  p <|> (pure $ IsLte.gte 0 (by simp))

def radixParser (nParser: LteParser n) (baseParser: LteParser b) : LteParser ((n + 1) * (b + 1) - 1) := do
  let (IsLte.gte x hₓ) <- nParser
  let (IsLte.gte a hₐ) <- baseParser
  pure $ .gte (x * b + x + a) $ by
    rw [Nat.right_distrib, Nat.left_distrib, Nat.mul_one, Nat.one_mul, ← Nat.add_assoc, Nat.add_sub_cancel]
    apply Nat.add_le_add
    have h₁ : x * b ≤ n * b := Nat.mul_le_mul_right b hₓ
    exact Nat.add_le_add h₁ hₓ
    exact hₐ

def addToLte (r: Nat) (l: IsLte γ)  : IsLte (γ + r) := match l with
    | IsLte.gte l h => .gte (l + r) (Nat.add_le_add_right h r)

def baseTwoParser : LteParser 1 :=
  succParser (Parser.Char.char '1') $
  zeroParser $ Parser.Char.char '0'

def baseSixParser : LteParser 5 :=
  succParser (Parser.Char.char '5') $
  succParser (Parser.Char.char '4') $
  succParser (Parser.Char.char '3') $
  succParser (Parser.Char.char '2') $
  baseTwoParser

def baseTenParser : LteParser 9 :=
  succParser (Parser.Char.char '9') $
  succParser (Parser.Char.char '8') $
  succParser (Parser.Char.char '7') $
  succParser (Parser.Char.char '6') $
  baseSixParser

def twentyFourParser : LteParser 23 :=
  (radixParser baseTwoParser baseTenParser : LteParser 23) <|>
  (Functor.map  (addToLte 20) $
  succParser (Parser.Char.string "23") $
  succParser (Parser.Char.string "22") $
  succParser (Parser.Char.string "21") $
  zeroParser $ Parser.Char.chars "20")

def sixtyParser : LteParser 59 := radixParser baseSixParser baseTenParser

def timeParser : LteParser 1439 :=
  radixParser twentyFourParser sixtyParser

-- elab "#findCElab " c:command : command => do
--   let macroRes ← Lean.Elab.liftMacroM <| Lean.Elab.expandMacroImpl? (←getEnv) c
--   match macroRes with
--   | some (name, _) => logInfo s!"Next step is a macro: {name.toString}"
--   | none =>
--     let kind := c.raw.getKind
--     let elabs := commandElabAttribute.getEntries (←getEnv) kind
--     match elabs with
--     | [] => logInfo s!"There is no elaborators for your syntax, looks like its bad :("
--     | _ => logInfo s!"Your syntax may be elaborated by: {elabs.map (fun el => el.declName.toString)}"

syntax "time! " str : term
macro_rules
  | `(time! $s:str) => do
    match Parser.run timeParser s.getString with
      | Parser.Result.ok _ (IsLte.gte α h)  =>
        `(IsLte.gte $(Lean.Syntax.mkNatLit α) (by simp))
      | Parser.Result.error _ e => Lean.Macro.throwError s!"Invalid time: {e}"

#check `(IsLte.gte 5 (by simp))

def Time := IsLte 1439
def DepartureArrival := Time × Time

example : Time := time! "1099"
