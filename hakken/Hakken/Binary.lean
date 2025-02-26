import Init.Data.ByteArray
import Mathlib
import Init.Classical
import Plausible

open Plausible

def Fin' (n: Nat) := Fin n
def BitFin (x: Nat) := Fin (2 ^ x)
theorem shiftRight_lt_two_pow_sub (a: BitFin α) (p: Nat) (isLe: p <= α) : a.val >>> p < 2 ^ (α - p) := by calc
  _ = a.val / 2 ^ p := Nat.shiftRight_eq_div_pow a.val p
  _ <  2 ^ α / 2 ^ p := Nat.div_lt_div_of_lt_of_dvd (Nat.pow_dvd_pow 2 isLe) a.isLt
  _ = 2 ^ (α - p) := Nat.pow_div isLe (by simp)

def BitFin.divide {l r: Nat} (ab: BitFin (l + r)): BitFin l × BitFin r :=
  (⟨ab.val >>> r, by calc
    _ < 2 ^ (l + r - r) := shiftRight_lt_two_pow_sub ab r (by simp)
    _ = 2 ^ l := by simp [Nat.add_sub_cancel l r]
   ⟩,
   ⟨ab.val % 2 ^ r, Nat.mod_lt ab.val $ Nat.pow_pos (by simp)⟩)

def BitFin.append (a: BitFin α) (b: BitFin β): BitFin (α + β) :=
  ⟨(a.val * 2 ^ β) + b.val, by
    calc
      _ < a.val.succ * 2 ^ β := by
        rw [Nat.mul_comm a.val.succ, Nat.mul_add_one (2 ^ β), Nat.mul_comm (2 ^ β)]
        exact (Nat.add_lt_add_iff_left (k := a.val * 2 ^ β)).mpr b.isLt
      _ <= 2 ^ (α + β) := by
        rw [Nat.pow_add]
        exact (Nat.mul_le_mul_right (2 ^ β)) (Nat.succ_le_of_lt a.isLt)
  ⟩

def BitFin.split {α β: Nat} (a: BitFin α) (dvdh: β ∣ α) : Vector (BitFin β) (α / β) :=
  let rec aux (cnt: Fin' (α / β)) (rem: BitFin (α - β * cnt.val)) (result: Vector (BitFin β) cnt.val) : Vector (BitFin β) (α / β) :=
    if eqh: cnt.val + 1 = α / β then
      Eq.rec (motive := fun n _ => Vector (BitFin β) n) (result.push ⟨0, by simp⟩) eqh
    else
      have h := Nat.mul_le_mul_right β <| Nat.add_one_le_of_lt cnt.isLt
      let rem : BitFin (β + (α - β * (cnt.val + 1))) := (Eq.rec (motive := fun n _ => BitFin n) rem (by
        rw [Nat.left_distrib, Nat.mul_one, Nat.add_comm, Nat.sub_add_eq, Nat.sub_add_cancel]
        rw [Nat.right_distrib, Nat.one_mul, Nat.div_mul_cancel dvdh, Nat.mul_comm, Nat.add_comm] at h
        have := Nat.sub_le_sub_right h (β * cnt.val)
        simp at this
        assumption
      ))
      let (n, rem) := rem.divide (l := β) (r := α - β * (cnt.val + 1))
      aux ⟨cnt.val + 1, (lt_of_le_of_ne (Nat.add_one_le_of_lt cnt.isLt) eqh)⟩ rem (result.push n)

    termination_by α / β - (cnt.val + 1)

  if h: α / β = 0 then
    Eq.rec (motive := fun n _ => Vector (BitFin β) n) #v[] (Eq.symm h)
  else
    aux ⟨0,  Nat.pos_of_ne_zero h⟩ a #v[]

namespace B64
private def map : Vector Char 64 :=
  #v['A', 'B', 'C', 'D', 'E', 'F', 'G', 'H', 'I', 'J', 'K', 'L', 'M', 'N', 'O', 'P',
   'Q', 'R', 'S', 'T', 'U', 'V', 'W', 'X', 'Y', 'Z', 'a', 'b', 'c', 'd', 'e', 'f',
   'g', 'h', 'i', 'j', 'k', 'l', 'm', 'n', 'o', 'p', 'q', 'r', 's', 't', 'u', 'v',
   'w', 'x', 'y', 'z', '0', '1', '2', '3', '4', '5', '6', '7', '8', '9', '+', '/']

instance : Coe (BitFin 6) Char where
    coe fin := map[fin.val]

def encode1 (a: BitVec 8) : BitFin 6 × BitFin 2 := BitFin.divide (l := 6) a.toFin
def encode2 (a: BitVec 8) (b: BitVec 8) : BitFin 6 × BitFin 6 × BitFin 4 :=
  let (l, mid) := BitFin.divide (l := 6) a.toFin
  let (mid', r) := BitFin.divide (l := 4) b.toFin
  (l, mid.append mid', r)
def encode3 (a: BitVec 8) (b: BitVec 8) (c: BitVec 8) : BitFin 6 × BitFin 6 × BitFin 6 × BitFin 6 :=
  let (l, lmid) := BitFin.divide (l := 6) a.toFin
  let (lmid', rmid) := BitFin.divide (l := 4) b.toFin
  let (rmid', r) := BitFin.divide (l := 2) c.toFin
  (l, lmid.append lmid', rmid.append rmid', r)

def encode (data: ByteArray) : String :=
    let r: Std.Range := { start := 0, stop := data.size, step := 3, step_pos := by simp }
    have hstep : r.stop = data.size := by rfl
    Id.run do
        let mut (result : List Char) := []
        for h : i in r do
            if h': data.size - i > 2 then
                let (l, lm, rm, r) := B64.encode3 data[i].toBitVec data[i + 1].toBitVec data[i + 2].toBitVec
                result := result.append [l, lm, rm, r]
            else if h': data.size - i > 1 then
                let (l, m, r) := B64.encode2 data[i].toBitVec data[i + 1].toBitVec
                let r := r.append (⟨0, by simp⟩: BitFin 2)
                result := result.append [l, m, r, '=']
            else
                let (l, r) := B64.encode1 $ data.get i (trans h.upper hstep) |>.toBitVec
                let r := r.append (⟨0, by simp⟩: BitFin 4)
                result := result.append [l, r, '=', '=']
        pure ⟨result⟩

private def examples : List ((Array UInt8) × String) := [
  (#[77], "TQ=="),
  (#[77, 97], "TWE="),
  (#[77, 97, 100], "TWFk"),
]

private abbrev Example : Type := { x : (Array UInt8) × String // x ∈ examples }
instance instReprMem (γ: List α) [Repr α] : Repr (Subtype (Membership.mem γ)) where
  reprPrec st prec := Repr.reprPrec st.val prec
instance instReprExample : Repr Example := instReprMem examples
instance instShrinkableMem (γ : List α) : Shrinkable (Subtype (Membership.mem γ)) where
  shrink _ := []

instance instSampleableExtMem (γ : List α) (ne: γ ≠ []) [Repr α] : SampleableExt (Subtype (Membership.mem γ)) where
  proxy := Subtype (Membership.mem γ)
  proxyRepr := instReprMem γ
  shrink := instShrinkableMem γ
  interp := id
  sample :=
    let rec aux (γ : List α) (ne: γ ≠ []) : Gen (Subtype (Membership.mem γ)) := do
      if h : γ.tail.isEmpty then
        pure $ ⟨γ.head ne, γ.head_mem ne⟩
      else
        let alt <- aux γ.tail (ne_of_apply_ne List.isEmpty h)
        let r <- Gen.chooseNatLt 0 (γ.length + 1) (by simp)
        if r.val = 0 then
          pure $ ⟨γ.head ne, γ.head_mem ne⟩
        else
          -- have h : γ.head ne :: γ.tail = γ := List.head_cons_tail γ ne
          let m : Membership.mem (γ.head ne :: γ.tail) alt.val :=
            List.mem_cons.mpr $ Or.inr alt.property
          let m' : Membership.mem γ alt.val :=
            Eq.rec (motive := fun l _ => Membership.mem l alt.val) m (by simp)
          pure $ ⟨alt.val, m'⟩

      termination_by γ.length
      decreasing_by
        nth_rw 2 [← γ.head_cons_tail ne]
        rw [List.length_cons (γ.head ne) (γ.tail)]
        simp

    aux γ ne

instance instSampleableExample : SampleableExt Example := instSampleableExtMem examples (by decide)


#eval Testable.check $ ∀ ex : Example, B64.encode ⟨ex.val.1⟩ = ex.val.2

instance {α : Type} [Shrinkable α] : Shrinkable (Vector α 0) where
  shrink _ := []

instance {n: Nat} {α : Type} [Shrinkable α] [Shrinkable (Vector α n)] : Shrinkable (Vector α n.succ) where
  shrink vec :=
    let last_shrunk := Shrinkable.shrink vec.back
    let popped : Vector α n := vec.pop
    (Shrinkable.shrink popped).map (·.push vec.back) ++ (last_shrunk.map (popped.push ·))

instance {α : Type} [Repr α] [Shrinkable α] : SampleableExt (Vector α 0) := SampleableExt.mkSelfContained $ pure #v[]
instance {n : Nat} {α : Type} [Repr α] [Shrinkable α] [Shrinkable (Vector α n.succ)] [prev: SampleableExt (Vector α n)] [next: SampleableExt α] : SampleableExt (Vector α n.succ) := SampleableExt.mkSelfContained $ do
  let p <- prev.sample
  let n <- next.sample
  pure $ (prev.interp p).push (next.interp n)

#eval Testable.check $ ∀ a b : Vector UInt8 3,
  B64.encode ⟨a.toArray.append b.toArray⟩ = (B64.encode ⟨a.toArray⟩ |>.append $ B64.encode ⟨b.toArray⟩)

end B64
