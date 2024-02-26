{-# OPTIONS --cubical --safe --lossy-unification #-}

{-This file contains:

-}

module Cubical.Data.CW.Properties where

open import Cubical.Foundations.Prelude
open import Cubical.Foundations.Pointed
open import Cubical.Foundations.Equiv
open import Cubical.Foundations.HLevels
open import Cubical.Foundations.Isomorphism
open import Cubical.Foundations.Univalence
open import Cubical.Foundations.Transport
open import Cubical.Foundations.Function

open import Cubical.Data.Nat renaming (_+_ to _+ℕ_)
open import Cubical.Data.Nat.Order
open import Cubical.Data.Unit
open import Cubical.Data.Fin
open import Cubical.Data.Sigma
open import Cubical.Data.Empty as ⊥
open import Cubical.Data.CW.Base
open import Cubical.Data.Sequence

open import Cubical.HITs.Sn
open import Cubical.HITs.Pushout
open import Cubical.HITs.Susp
open import Cubical.HITs.SequentialColimit
open import Cubical.HITs.SphereBouquet
open import Cubical.HITs.PropositionalTruncation as PT

open import Cubical.Algebra.AbGroup
open import Cubical.Algebra.AbGroup.Instances.FreeAbGroup

open import Cubical.HITs.SequentialColimit
open Sequence

open import Cubical.Relation.Nullary



private
  variable
    ℓ ℓ' : Level

CW₀-empty : (C : CWskel ℓ) → ¬ fst C 0
CW₀-empty C = snd (snd (snd C)) .fst

CW₁-discrete : (C : CWskel ℓ) → fst C 1 ≃ Fin (snd C .fst 0)
CW₁-discrete C = compEquiv (snd C .snd .snd .snd 0) (isoToEquiv main)
  where
  main : Iso (Pushout (fst (snd C .snd) 0) fst) (Fin (snd C .fst 0))
  Iso.fun main (inl x) = ⊥.rec (CW₀-empty C x)
  Iso.fun main (inr x) = x
  Iso.inv main = inr
  Iso.rightInv main x = refl
  Iso.leftInv main (inl x) = ⊥.rec (CW₀-empty C x)
  Iso.leftInv main (inr x) = refl

-- elimination from Cₙ into prop
CWskel→Prop : (C : CWskel ℓ) {A : (n : ℕ) → fst C n → Type ℓ'}
  → ((n : ℕ) (x : _) → isProp (A n x))
  → ((a : _) → A (suc zero) a)
  → ((n : ℕ) (a : _) → (A (suc n) a → A (suc (suc n)) (CW↪ C (suc n) a)))
  → (n : _) (c : fst C n) → A n c
CWskel→Prop C {A = A} pr b eqs zero c = ⊥.rec (CW₀-empty C c)
CWskel→Prop C {A = A} pr b eqs (suc zero) = b
CWskel→Prop C {A = A} pr b eqs (suc (suc n)) c =
  subst (A (suc (suc n)))
        (retEq (snd C .snd .snd .snd (suc n)) c)
        (help (CWskel→Prop C pr b eqs (suc n)) _)
  where
  help : (inder : (c₁ : fst C (suc n)) → A (suc n) c₁)
       → (a : Pushout _ fst)
       → A (suc (suc n)) (invEq (snd C .snd .snd .snd (suc n)) a)
  help inder =
    elimProp _ (λ _ → pr _ _) (λ b → eqs n _ (inder b))
     λ c → subst (A (suc (suc n)))
                  (cong (invEq (snd C .snd .snd .snd (suc n))) (push (c , ptSn n)))
                  (eqs n _ (inder _))

isSet-CW₀ : (C : CWskel ℓ) → isSet (fst C (suc zero))
isSet-CW₀ C =
   isOfHLevelRetractFromIso 2 (equivToIso (CW₁-discrete C))
    isSetFin

-- eliminating from CW complex into prop
CW→Prop : (C : CWskel ℓ) {A : realise C → Type ℓ'}
  → ((x : _) → isProp (A x))
  → ((a : _) → A (incl {n = suc zero} a))
  → (a : _) → A a
CW→Prop C {A = A} pr ind  =
  SeqColim→Prop pr (CWskel→Prop C (λ _ _ → pr _)
    ind
    λ n a → subst A (push a))

-- realisation of finite complex
realiseFin : (n : ℕ) (C : finCWskel ℓ n) → Iso (fst C n) (realise (finCWskel→CWskel n C))
realiseFin n C = converges→ColimIso n (snd C .snd)

-- elimination principles for CW complexes
module _ {ℓ : Level} (C : CWskel ℓ) where
  open CWskel-fields C
  module _ (n : ℕ) {B : fst C (suc n) → Type ℓ'}
         (inler : (x : fst C n) → B (invEq (e n) (inl x)))
         (inrer : (x : A n) → B (invEq (e n) (inr x)))
         (pusher : (x : A n) (y : S⁻ n)
        → PathP (λ i → B (invEq (e n) (push (x , y) i)))
                 (inler (α n (x , y)))
                 (inrer x)) where
    private
      gen : ∀ {ℓ ℓ'} {A B : Type ℓ} (C : A → Type ℓ')
                  (e : A ≃ B)
               → ((x : B) → C (invEq e x))
               → (x : A) → C x
      gen C e h x = subst C (retEq e x) (h (fst e x))

      gen-coh : ∀ {ℓ ℓ'} {A B : Type ℓ} (C : A → Type ℓ')
                  (e : A ≃ B) (h : (x : B) → C (invEq e x))
               → (b : B)
               → gen C e h (invEq e b) ≡ h b
      gen-coh {ℓ' = ℓ'} {A = A} {B = B} C e =
        EquivJ (λ A e → (C : A → Type ℓ') (h : (x : B) → C (invEq e x))
               → (b : B)
               → gen C e h (invEq e b) ≡ h b)
               (λ C h b → transportRefl (h b)) e C

      main : (x : _) → B (invEq (e n) x)
      main (inl x) = inler x
      main (inr x) = inrer x
      main (push (x , y) i) = pusher x y i

    CWskel-elim : (x : _) → B x
    CWskel-elim = gen B (e n) main

    CWskel-elim-inl : (x : _) → CWskel-elim (invEq (e n) (inl x)) ≡ inler x
    CWskel-elim-inl x = gen-coh B (e n) main (inl x)

  module _ (n : ℕ) {B : fst C (suc (suc n)) → Type ℓ'}
           (inler : (x : fst C (suc n))
                  → B (invEq (e (suc n)) (inl x)))
           (ind : ((x : A (suc n)) (y : S₊ n)
           → PathP (λ i → B (invEq (e (suc n))
                                   ((push (x , y) ∙ sym (push (x , ptSn n))) i)))
                   (inler (α (suc n) (x , y)))
                   (inler (α (suc n) (x , ptSn n))))) where
    CWskel-elim' : (x : _) → B x
    CWskel-elim' =
      CWskel-elim (suc n) inler
        (λ x → subst (λ t → B (invEq (e (suc n)) t))
                      (push (x , ptSn n))
                      (inler (α (suc n) (x , ptSn n))))
        λ x y → toPathP (sym (substSubst⁻ (B ∘ invEq (e (suc n)))  _ _)
           ∙ cong (subst (λ t → B (invEq (e (suc n)) t))
                         (push (x , ptSn n)))
                  (sym (substComposite (B ∘ invEq (e (suc n))) _ _ _)
            ∙ fromPathP (ind x y)))

    CWskel-elim'-inl : (x : _)
      → CWskel-elim' (invEq (e (suc n)) (inl x)) ≡ inler x
    CWskel-elim'-inl = CWskel-elim-inl (suc n) {B = B} inler _ _

finCWskel≃ : (n : ℕ) (C : finCWskel ℓ n) (m : ℕ) → n ≤ m → fst C n ≃ fst C m
finCWskel≃ n C m (zero , diff) = substEquiv (λ n → fst C n) diff
finCWskel≃ n C zero (suc x , diff) = ⊥.rec (snotz diff)
finCWskel≃ n C (suc m) (suc x , diff) =
  compEquiv (finCWskel≃ n C m (x , cong predℕ diff))
            (compEquiv (substEquiv (λ n → fst C n) (sym (cong predℕ diff)))
            (compEquiv (_ , snd C .snd x)
            (substEquiv (λ n → fst C n) diff)))
