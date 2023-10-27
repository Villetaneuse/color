(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Sebastien Hinderer, 2004-04-28
- Frederic Blanqui, 2005-01-28

terms whose variable indexes are bounded
*)

Set Implicit Arguments.

From CoLoR Require Import ATerm VecUtil AInterpretation LogicUtil NatUtil.

Section S.

Variable Sig : Signature.

Notation term := (term Sig). Notation terms := (vector term).

Section bterm.

Variable k : nat.

(*COQ: we do not use the induction principle generated by Coq since it
     is not good because the argument of Fun is a vector *)

Unset Elimination Schemes.

Inductive bterm : Type :=
  | BVar : forall x : nat, x<=k -> bterm
  | BFun : forall f : Sig, vector bterm (arity f) -> bterm.

Set Elimination Schemes.

(***********************************************************************)
(** induction principles *)

Notation bterms := (vector bterm).

Section bterm_rect_def.

Variables
  (P : bterm -> Type)
  (Q : forall n : nat, bterms n -> Type).

Hypotheses
  (H1 : forall x (h : x<=k), P (BVar h))
  (H2 : forall (f : Sig) (v : bterms (arity f)), Q v -> P (BFun f v))
  (H3 : Q Vnil)
  (H4 : forall (t : bterm) n (v : bterms n), P t -> Q v -> Q (Vcons t v)).

Fixpoint bterm_rect (t : bterm) : P t :=
  match t as t return P t with
    | BVar h => H1 h
    | BFun f v =>
      let fix bterms_rect n (v : bterms n) : Q v :=
        match v as v return Q v with
          | Vnil => H3
          | Vcons t' v' => H4 (bterm_rect t') (bterms_rect _ v')
        end
	in H2 f (bterms_rect (arity f) v)
  end.

End bterm_rect_def.

Definition bterm_ind (P : bterm -> Prop) (Q : forall n, bterms n -> Prop) :=
  bterm_rect P Q.

(***********************************************************************)
(** injection of bterm into term *)

Fixpoint term_of_bterm (bt : bterm) : term :=
  match bt with
    | @BVar v _ => Var v
    | BFun f bts => Fun f (Vmap term_of_bterm bts)
  end.

(***********************************************************************)
(** injection of term into bterm *)

Notation max_le := (maxvar_le k).

Fixpoint inject_term (t : term) : max_le t -> bterm :=
  match t as t0 return max_le t0 -> bterm with
    | Var x => fun H => BVar (maxvar_var H)
    | Fun f ts => fun H =>
      let fix inject_terms n (ts : terms n) : 
        Vforall max_le ts -> bterms n :=
	match ts as v in vector _ n0
	  return Vforall max_le v -> bterms n0 with
          | Vnil => fun _ => Vnil
          | Vcons t' ts' => fun H =>
	    Vcons (inject_term (proj1 H)) (inject_terms _ ts' (proj2 H))
	end
      in BFun f (inject_terms (arity f) ts (maxvar_le_fun H))
  end.

Fixpoint inject_terms (n : nat) (ts : terms n) : 
  Vforall max_le ts -> bterms n :=
  match ts as v in vector _ n0
    return Vforall max_le v -> bterms n0 with
    | Vnil => fun _ => Vnil
    | Vcons t' ts' => fun H =>
      Vcons (inject_term (proj1 H)) (inject_terms ts' (proj2 H))
  end.

Arguments inject_terms [n ts] _.

Lemma inject_term_eq : forall f ts (H : max_le (Fun f ts)),
  inject_term H = BFun f (inject_terms (maxvar_le_fun H)).

Proof.
intros. simpl. auto.
Qed.

Lemma inject_terms_nth : forall i n (ts : terms n) (H : Vforall max_le ts)
  (ip : i < n), Vnth (inject_terms H) ip = inject_term (Vforall_nth ip H).

Proof.
  induction i; intros.
  destruct ts. lia. simpl. 
  match goal with |- inject_term ?Hl = inject_term ?Hr =>
    rewrite (le_unique Hl Hr) end. refl.
  destruct ts. lia.
  simpl. rewrite IHi.
  match goal with |- inject_term ?Hl = inject_term ?Hr =>
    rewrite (le_unique Hl Hr) end. refl.
Qed.

(***********************************************************************)
(** interpretation of bterm's *)

Variables (I : interpretation Sig) (xint : valuation I).

Notation D := (domain I).
Notation fint := (fint I).

Fixpoint bterm_int (t : bterm) { struct t } : D :=
  match t with
    | @BVar x _ => xint x
    | BFun f v => fint f (Vmap bterm_int v)
  end.

End bterm.

Arguments inject_terms [k n ts] _.

(***********************************************************************)
(** relation between bterm_int and term_int *)

Section term_int.

Variables (I : interpretation Sig) (xint : valuation I).

Notation D := (domain I).

Let P (t : term) := forall (k : nat) (H : maxvar_le k t),
  bterm_int xint (inject_term H) = term_int xint t.

Let Q (n1 : nat) (ts : terms n1) :=
  forall (k : nat) (H : Vforall (maxvar_le k) ts),
    Vmap (bterm_int xint) (inject_terms H) = Vmap (term_int xint) ts.

Lemma term_int_eq_bterm_int : forall t, P t.

Proof.
intro t. apply (term_ind P Q).
 intro x. unfold P. simpl. intros. refl.

 intros f ts. unfold Q. intro H. unfold P.
 intros n Hn.
 rewrite inject_term_eq. simpl.
 f_equal.
 gen (maxvar_le_fun Hn). intro H0.
 gen (H _ H0). intro H1. hyp.

 unfold Q, P. simpl. auto.

 intros t' n' v'. unfold P, Q. intros H1 H2. intros n H3.
 simpl in H3. gen H3. clear H3.
 intro H3.
 gen (H1 _ (proj1 H3)). clear H1. intro H1.
 gen (H2 _ (proj2 H3)). clear H2. intro H2.
 simpl. rewrite <-H1, <-H2. refl.
Qed.
 
End term_int.

Arguments inject_terms [k n ts] _.

(***********************************************************************)
(** lemmas about bterm *)

Fixpoint bterm_le k (bt : bterm k) l (h0 : k <= l) : bterm l :=
  match bt with
    | BVar h => BVar (Nat.le_trans h h0)
    | BFun f bts => BFun f (Vmap (fun bt => @bterm_le k bt l h0) bts)
  end.

Fixpoint bterms_le k n (bts : vector (bterm k) n) l (h0 : k <= l)
  : vector (bterm l) n :=
  match bts in vector _ n return vector (bterm l) n with
    | Vnil => Vnil
    | Vcons bt bts' => Vcons (bterm_le bt h0) (bterms_le bts' h0)
  end.

Definition bterm_plus k bt l := bterm_le bt (Nat.le_add_l k l).

Definition bterms_plus k n (bts : vector (bterm k) n) l
  := bterms_le bts (Nat.le_add_l k l).

End S.

Arguments BVar [Sig k x] _.
Arguments BFun [Sig k] _ _.
Arguments inject_terms [Sig k n ts] _.
