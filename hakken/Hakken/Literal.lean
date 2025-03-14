import Lean

def Literal {α : Type} (a: α) : Type := { v : α // v = a }
