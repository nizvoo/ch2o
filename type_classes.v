(* Copyright (c) 2012-2014, Robbert Krebbers. *)
(* This file is distributed under the terms of the BSD license. *)
Require Export prelude.

(** Some useful type classes to get nice overloaded notations for the different
kinds of values that we will consider. *)
Class Valid (E A : Type) := valid: E → A → Prop.
Instance: Params (@valid) 4.
Notation "✓{ Γ }" := (valid Γ) (at level 1, format "✓{ Γ }") : C_scope.
Notation "✓{ Γ }*" := (Forall (✓{Γ})) (at level 1, format "✓{ Γ }*") : C_scope.
Notation "✓{ Γ }**" := (Forall (✓{Γ}*))
  (at level 1, format "✓{ Γ }**") : C_scope.
Notation "✓{ Γ }2**" := (Forall (✓{Γ}* ∘ snd))
  (at level 1, format "✓{ Γ }2**") : C_scope.
Notation "✓{ Γ1 , Γ2 , .. , Γ3 }" := (valid (pair .. (Γ1, Γ2) .. Γ3))
  (at level 1, format "✓{ Γ1 , Γ2 , .. , Γ3 }") : C_scope.
Notation "✓{ Γ1 , Γ2 , .. , Γ3 }*" := (Forall (✓{pair .. (Γ1, Γ2) .. Γ3}))
  (at level 1, format "✓{ Γ1 ,  Γ2 , .. , Γ3 }*") : C_scope.
Notation "✓{ Γ1 , Γ2 , .. , Γ3 }**" := (Forall (✓{pair .. (Γ1, Γ2) .. Γ3}*))
  (at level 1, format "✓{ Γ1 ,  Γ2 , .. , Γ3 }**") : C_scope.
Notation "✓{ Γ1 , Γ2 , .. , Γ3 }2**" :=
  (Forall (✓{pair .. (Γ1, Γ2) .. Γ3}* ∘ snd))
  (at level 1, format "✓{ Γ1 ,  Γ2 , .. , Γ3 }2**") : C_scope.
Notation "✓" := (valid ()) (at level 1) : C_scope.
Notation "✓*" := (Forall ✓) : C_scope.

Class Typed (E T V : Type) := typed: E → V → T → Prop.
Notation "Γ ⊢ v : τ" := (typed Γ v τ)
  (at level 74, v at next level, τ at next level) : C_scope.
Notation "Γ ⊢* vs :* τs" := (Forall2 (typed Γ) vs τs)
  (at level 74, vs at next level) : C_scope.
Notation "Γ ⊢1* vs :* τs" := (Forall2 (typed Γ ∘ fst) vs τs)
  (at level 74, vs at next level) : C_scope.
Notation "Γ ⊢* vs : τ" := (Forall (λ v, Γ ⊢ v : τ) vs)
  (at level 74, vs at next level) : C_scope.
Instance: Params (@typed) 4.

Class PathTyped (E T V : Type) := path_typed: E → V → T → T → Prop.
Notation "Γ ⊢ v : τ ↣ σ" := (path_typed Γ v τ σ)
  (at level 74, v at next level, τ at next level, σ at next level) : C_scope.
Instance: Params (@path_typed) 4.

Class TypeCheck (E T V : Type) := type_check: E → V → option T.
Arguments type_check {_ _ _ _} _ !_ / : simpl nomatch.
Class TypeCheckSpec (E T V : Type) (P : E → Prop)
    `{Typed E T V} `{TypeCheck E T V} :=
  type_check_correct Γ x τ : P Γ → type_check Γ x = Some τ ↔ Γ ⊢ x : τ.

Class TypeOf (T V : Type) := type_of: V → T.
Arguments type_of {_ _ _} !_ / : simpl nomatch.
Class TypeOfSpec (E T V : Type) `{Typed E T V, TypeOf T V} :=
  type_of_correct Γ x τ : Γ ⊢ x : τ → type_of x = τ.
Class PathTypeCheckSpec (E T R : Type)
    `{PathTyped E T R, LookupE E R T T} := {
  path_type_check_correct Γ p τ σ : τ !!{Γ} p = Some σ ↔ Γ ⊢ p : τ ↣ σ;
  path_typed_unique_l Γ r τ1 τ2 σ :
    Γ ⊢ r : τ1 ↣ σ → Γ ⊢ r : τ2 ↣ σ → τ1 = τ2
}.

Ltac typed_constructor :=
  intros; match goal with
  | |- typed (Typed:=?H) ?Γ _ _ =>
    let H' := eval hnf in (H Γ) in
    econstructor; change H' with (typed (Typed:=H) Γ)
  | |- path_typed (PathTyped:=?H) ?Γ _ _ _ =>
    let H' := eval hnf in (H Γ) in
    econstructor; change H' with (path_typed (PathTyped:=H) Γ)
  end.

Section typed.
  Context `{Typed E T V}.
  Lemma Forall2_Forall_typed Γ vs τs τ :
    Γ ⊢* vs :* τs → Forall (τ =) τs → Γ ⊢* vs : τ.
  Proof. induction 1; inversion 1; subst; eauto. Qed.
End typed.

Section type_check.
  Context `{TypeCheckSpec E T V P}.
  Lemma type_check_None Γ x τ : P Γ → type_check Γ x = None → ¬Γ ⊢ x : τ.
  Proof. intro. rewrite <-type_check_correct by done. congruence. Qed.
  Lemma type_check_sound Γ x τ : P Γ → type_check Γ x = Some τ → Γ ⊢ x : τ.
  Proof. intro. by rewrite type_check_correct by done. Qed.
  Lemma type_check_complete Γ x τ : P Γ → Γ ⊢ x : τ → type_check Γ x = Some τ.
  Proof. intro. by rewrite type_check_correct by done. Qed.
  Lemma typed_unique Γ x τ1 τ2 : P Γ → Γ ⊢ x : τ1 → Γ ⊢ x : τ2 → τ1 = τ2.
  Proof. intro. rewrite <-!type_check_correct by done. congruence. Qed.
End type_check.

Section type_of.
  Context `{TypeOfSpec E T V}.
  Lemma type_of_typed Γ x τ : Γ ⊢ x : τ → Γ ⊢ x : type_of x.
  Proof. intros. erewrite type_of_correct; eauto. Qed.
  Lemma typed_unique_alt Γ x τ1 τ2 : Γ ⊢ x : τ1 → Γ ⊢ x : τ2 → τ1 = τ2.
  Proof.
    intros Hτ1 Hτ2. apply type_of_correct in Hτ1. apply type_of_correct in Hτ2.
    congruence.
  Qed.
  Lemma fmap_type_of Γ vs τs : Γ ⊢* vs :* τs → type_of <$> vs = τs.
  Proof. induction 1; simpl; f_equal; eauto using type_of_correct. Qed.
End type_of.

Section path_type_check.
  Context `{PathTypeCheckSpec E T R}.
  Lemma path_type_check_None Γ r τ σ : τ !!{Γ} r = None → ¬Γ ⊢ r : τ ↣ σ.
  Proof. rewrite <-path_type_check_correct. congruence. Qed.
  Lemma path_type_check_sound Γ r τ σ : τ !!{Γ} r = Some σ → Γ ⊢ r : τ ↣ σ.
  Proof. by rewrite path_type_check_correct. Qed.
  Lemma path_type_check_complete Γ r τ σ : Γ ⊢ r : τ ↣ σ → τ !!{Γ} r = Some σ.
  Proof. by rewrite path_type_check_correct. Qed.
  Lemma path_typed_unique_r Γ r τ σ1 σ2 :
    Γ ⊢ r : τ ↣ σ1 → Γ ⊢ r : τ ↣ σ2 → σ1 = σ2.
  Proof. rewrite <-!path_type_check_correct. congruence. Qed.
End path_type_check.

Instance typed_dec `{TypeCheckSpec E T V (λ _, True)}
  `{∀ τ1 τ2 : T, Decision (τ1 = τ2)} Γ x τ : Decision (Γ ⊢ x : τ).
Proof.
 refine
  match Some_dec (type_check Γ x) with
  | inleft (τ'↾_) => cast_if (decide (τ = τ'))
  | inright _ => right _
  end; abstract (rewrite <-type_check_correct by done; congruence).
Defined.
Instance path_typed_dec `{PathTypeCheckSpec E T R}
  `{∀ τ1 τ2 : T, Decision (τ1 = τ2)} Γ p τ σ : Decision (Γ ⊢ p : τ ↣ σ).
Proof.
 refine (cast_if (decide (τ !!{Γ} p = Some σ)));
  abstract by rewrite <-path_type_check_correct by done.
Defined.

Ltac simplify_type_equality := repeat
  match goal with
  | _ => progress simplify_equality
  | H : type_check _ _ = Some _ |- _ => rewrite type_check_correct in H by done
  | H : ?Γ ⊢ ?x : ?τ, H2 : context [ type_of ?x ] |- _ =>
    rewrite !(type_of_correct Γ x τ) in H2 by done
  | H : ?Γ ⊢ ?x : ?τ |- context [ type_of ?x ] =>
    rewrite !(type_of_correct Γ x τ) by done
  | H : type_check ?Γ ?x = None, H2 : ?Γ ⊢ ?x : ?τ |- _ =>
    by destruct (type_check_None Γ x τ)
  | H : ?τ !!{?Γ} ?p = None, H2 : _ ⊢ ?p : (?τ,?σ) |- _ =>
    by destruct (path_type_check_None Γ p τ σ)
  | H : _ ⊢ ?x : ?τ1, H2 : _ ⊢ ?x : ?τ2 |- _ =>
    unless (τ2 = τ1) by done; pose proof (typed_unique _ x τ2 τ1 H2 H)
  | H : _ ⊢ ?x : ?τ1, H2 : _ ⊢ ?x : ?τ2 |- _ =>
    unless (τ2 = τ1) by done; pose proof (typed_unique_alt _ x τ2 τ1 H2 H)
  | H : _ ⊢ [] : _ ↣ _ |- _ => inversion H; clear H (* hack *)
  | H : _ ⊢ ?p : ?τ ↣ ?σ1, H2 : _ ⊢ ?p : ?τ ↣ ?σ2 |- _ =>
    unless (σ2 = σ1) by done; pose proof (path_typed_unique_r _ p τ σ2 σ1 H2 H)
  | H : _ ⊢ ?p : ?τ1 ↣ ?σ, H2 : _ ⊢ ?p : ?τ2 ↣ ?σ |- _ =>
    unless (τ2 = τ1) by done; pose proof (path_typed_unique_l _ p τ2 τ1 σ H2 H)
  end.
Ltac simplify_type_equality' :=
  repeat (progress simpl in * || simplify_type_equality).
