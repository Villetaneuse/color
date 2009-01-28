Require Import TermsSig.
Require Import Horpo.
Require Import HorpoWf.
Require Import RelExtras.
Require Import Setoid.
Require Import Wf_nat.
Require Import List.

Module BT <: BaseTypes.

  Inductive BaseType_aux :=
  | Star.
  Definition BaseType := BaseType_aux.

  Lemma eq_BaseType_dec : forall A B : BaseType, {A = B} + {A <> B}.

  Proof.
    decide equality.
  Qed.

  Lemma baseTypesNotEmpty : BaseType.
  Proof Star.

End BT.

Module Sig <: Signature.

  Module BT := BT.
  Module ST := SimpleTypes BT.
  Export ST.

  Inductive FunctionSymbol_aux :=
  | a
  | b
  | c.
  Definition FunctionSymbol := FunctionSymbol_aux.

  Lemma eq_FunctionSymbol_dec : forall f g : FunctionSymbol,
    {f = g} + {f <> g}.

  Proof.
    decide equality.
  Qed. 

  Lemma functionSymbolsNotEmpty : FunctionSymbol.
  Proof a.

  Definition f_type (f : FunctionSymbol) :=
    match f with
    | a => #Star
    | b => #Star
    | c => #Star --> #Star
    end.

End Sig.

Module Terms := Terms Sig.

Module P <: Precedence.

  Module S := Sig.
  Import S.

  Module FS <: SetA.
    Definition A := Sig.FunctionSymbol.
  End FS.

  Module FS_eq := Eqset_def FS.
  Import FS_eq.

  Module P <: Poset.

    Definition A := A.

    Module O <: Ord.
      Module S := FS_eq.

      Definition A := A.

      Definition gtA f g := 
        match f, g with
        | a, b => True
        | _, _ => False
        end.

      Definition gtA_eqA_compat := @Eqset_def_gtA_eqA_compat A gtA.
    End O.

    Export O.
    Lemma gtA_so : strict_order gtA.

    Proof.
      split. 
      intros x y z xy yz. destruct x; destruct y; destruct z; try_solve.
      intros x y. destruct x; try_solve.
    Qed.

  End P.

  Import P.

  Lemma Ord_wf : well_founded (transp gtA).

  Proof.
    apply well_founded_lt_compat with (f := fun x => 
      match x with a => 1 | _ => 0 end).
    destruct x; destruct y; try_solve.
  Qed.

  Lemma Ord_dec : forall a b, {gtA a b} + {~gtA a b}.

  Proof.
    intros x y. destruct x; try_solve.
    destruct y; try_solve.
  Defined.

End P.

Module Horpo := HorpoWf Sig P.
Import Horpo.HC.

(* -- Uncomment to verify that the theorem of well-foundedness of horpo 
   does not depend on any axioms. *)
(*Print Assumptions Horpo.horpo_wf.*)

Section HorpoNotTrans.

  Definition t1p := (\#Star => (^c [ %0 ])) @@ ^a.
  Definition t2p := (\#Star => (^c [ %0 ])) @@ ^b.
  Definition t3p := ^c [ ^b ].

  Definition t1 : nil |- t1p := #Star.

  Proof.
    infer_tt.
  Defined.

  Definition t2 : nil |- t2p := #Star.

  Proof.
    infer_tt.
  Defined.

  Definition t3 : nil |- t3p := #Star.

  Proof.
    infer_tt.
  Defined.

  Lemma horpo_not_trans : ~transitive horpo.

  Proof.

    assert (algebraic (buildT t1)).
    apply AlgApp; try_solve.
    intros. destruct H as [M'eq | [M'eq | false]]; try_solve.
    rewrite <- M'eq. apply AlgAbs with I.
    apply AlgFunApp; try_solve. compute. trivial.
    intros. destruct H as [M''eq | false]; try_solve.
    rewrite <- M''eq. apply AlgVar; try_solve.
    rewrite <- M'eq. apply AlgFunApp; try_solve. compute. trivial.

    assert (algebraic (buildT t2)).
    apply AlgApp; try_solve.
    intros. destruct H0 as [M'eq | [M'eq | false]]; try_solve.
    rewrite <- M'eq. apply AlgAbs with I. 
    apply AlgFunApp; try_solve. compute. trivial.
    intros. destruct H0 as [M''eq | false]; try_solve.
    rewrite <- M''eq. apply AlgVar; try_solve.
    rewrite <- M'eq. apply AlgFunApp; try_solve. compute. trivial.

    assert (algebraic (buildT t3)).
    apply AlgFunApp; try_solve. compute. trivial.
    intros. destruct H1 as [M'eq | false]; try_solve.
    rewrite <- M'eq. apply AlgFunApp; try_solve. compute. trivial.

    intro Htr. absurd (buildT t1 >> buildT t3).
    intro t1t3. inversion t1t3.
    inversion H6; try_solve.
    inversion H9; try_solve.
    inversion H12.
    absurd (term (lower (subst (beta_subst (buildT t1) Mapp0 MLabs))
      (beta_lowering (buildT t1) Mapp0 MLabs)) = term (buildT t3)).
    rewrite lower_term. rewrite subst_term. discriminate. 
    rewrite <- H17. trivial.
    apply (Htr (buildT t1) (buildT t2) (buildT t3)).
    assert (@appBodyR (buildT t1) I >> @appBodyR (buildT t2) I).
    constructor; try solve [try_solve | apply AlgFunApp; compute; tauto].
    apply HFun with a b; compute; trivial. apply HArgsNil.
    apply horpo_app_inv with I I. repeat split; intuition. assumption.
    intuition. assumption.
    repeat split. right. left. assumption. right. assumption.
    constructor; try_solve.
    apply HBeta. apply RedStep.  replace (buildT t3) with 
      (lower (subst (beta_subst (buildT t2) I I)) 
      (beta_lowering (buildT t2) I I)). apply Beta.
    apply term_eq. 
    rewrite lower_env. rewrite subst_env. trivial.
    rewrite lower_term. rewrite subst_term. trivial.
  Qed.

End HorpoNotTrans.