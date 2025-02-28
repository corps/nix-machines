import Lake
open Lake DSL

package «hakken» where
  -- Settings applied to both builds and interactive editing
  leanOptions := #[
    ⟨`pp.unicode.fun, true⟩ -- pretty-prints `fun a ↦ b`
  ]

require mathlib from git
  "https://github.com/leanprover-community/mathlib4.git"

require plausible from git
  "https://github.com/leanprover-community/plausible.git" @ "main"

lean_lib «Hakken» where
  -- add any library configuration options here
