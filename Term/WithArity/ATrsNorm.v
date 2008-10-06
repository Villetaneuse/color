(**
CoLoR, a Coq library on rewriting and termination.
See the COPYRIGHTS and LICENSE files.

- Frederic Blanqui, 2008-08-08

1) canonical representation of a rule l -> r:

WE ASSUME: incl (vars r) (vars l).

given the list of variables of l, xs = ATerm.vars l,
a variable of l or r is renamed as its position in xs

2) canonical representation of a list of rules R:

the rules of R are put in their unique representation
and R is sorted wrt the following ordering

(l1,r1) >_rule (l2,r2) if (l1,r1) (>_term)_lex (l2,r2)

f(t1..tn) >_term g(u1..up) if
  (f,(t1..tn)) (>_symb,(>_term)_lex)_lex (g,(u1..up))

f(t1..tn) >_term x

x >_term y if x >_nat y

assuming a total ordering >_symb on symbols
*)

(* $Id: ATrsNorm.v,v 1.2 2008-10-06 03:22:33 blanqui Exp $ *)

Set Implicit Arguments.

Require Export ATrs.
Require Import ListDec.
Require Import ListSort.

Section S.

Variable Sig : Signature.

Notation term := (term Sig). Notation terms := (vector term).

(***********************************************************************)
(** canonical representation of a rule *)

Section norm.

Variable xs : variables.

Fixpoint norm (t : term) {struct t} : term :=
  match t with
    | Var x =>
      match position beq_nat x xs with
        | Some y => Var y
        | None => Var (length xs)
      end
    | Fun f ts =>
      let fix norms n (ts : terms n) {struct ts} : terms n :=
        match ts in vector _ n return terms n with
          | Vnil => Vnil
          | Vcons u p us => Vcons (norm u) (norms p us)
        end
        in Fun f (norms (arity f) ts)
  end.

End norm.

(* ASSUME: incl (vars r) (vars l) *)
Definition mkNormRule l r :=
  let xs := ATerm.vars l in mkRule (norm xs l) (norm xs r).

(***********************************************************************)
(** canonical representation of a list of rules *)

Section term_ordering.

Variable symb_cmp : Sig -> Sig -> comparison.

Require Export OrdDec.

Fixpoint cmp (t u : term) {struct t} : comparison :=
  match t, u with
    | Var x, Var y => nat_cmp x y
    | Var x, _ => Lt
    | _, Var x => Gt
    | Fun f ts, Fun g us =>
      match symb_cmp f g with
        | Eq =>
          let fix cmp_terms n (ts : terms n) p (us : terms p) {struct ts}
            : comparison :=
            match ts, us with
              | Vnil, Vnil => Eq
              | Vnil, _ => Lt
              | _, Vnil => Gt
              | Vcons t _ ts, Vcons u _ us =>
                match cmp t u with
                  | Eq => cmp_terms _ ts _ us
                  | c => c
                end
            end
            in cmp_terms (arity f) ts (arity g) us
        | c => c
      end
  end.

(* ASSUME: rules are in normal form with mkNormRule *)
Definition mkNormRules := sort cmp.

End term_ordering.

End S.
