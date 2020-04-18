Require Import Fiat.ADT Fiat.ADTNotation.

Require Import Coq.Sets.Ensembles.
Require Import Coq.Lists.List.

Import ListNotations.

(** Support for inducting over ADTs *)

Fixpoint fromConstructor
         {rep : Type}
         {dom : list Type}
         (const : constructorType rep dom)
         (r : rep) : Prop :=
  match dom return constructorType rep dom -> rep -> Prop with
  | [ ] => fun const r => computes_to const r
  | D :: dom' => fun const r =>
                   exists (d : D), fromConstructor (const d) r
  end const r.

Fixpoint fromMethod' {rep : Type} {dom : list Type} :
  forall {cod : option Type}, methodType' rep dom cod -> rep -> Prop :=
  match dom return
        forall {cod : option Type},
          methodType' rep dom cod -> rep -> Prop with
  | [ ] =>
    fun cod =>
      match cod return methodType' rep [ ] cod -> rep -> Prop with
      | None   => fun meth r => computes_to meth r
      | Some C => fun meth r => exists c : C, computes_to meth (r, c)
      end
  | D :: dom' =>
    fun cod meth r => exists d, fromMethod' (meth d) r
  end.

Definition fromMethod
           {rep : Type}
           {dom : list Type}
           {cod : option Type}
           (meth : methodType rep dom cod)
           (r : rep) : rep -> Prop :=
  fromMethod' (meth r).

Inductive fromADT {sig} (adt : ADT sig) : Rep adt -> Prop :=
  | fromADTConstructor :
      forall (cidx : ConstructorIndex sig) (r : Rep adt),
        fromConstructor (Constructors adt cidx) r
        -> fromADT adt r
  | fromADTMethod :
      forall (midx : MethodIndex sig) (r r' : Rep adt),
        fromADT adt r
        -> fromMethod (Methods adt midx) r r'
        -> fromADT adt r'.

Require Import Fiat.Common.IterateBoundedIndex.

Tactic Notation "ADT" "induction" ident(r) :=
  match goal with
  | [ ADT : fromADT ?A r |- _ ] =>
    generalize dependent r;
    let cidx := fresh "cidx" in
    let midx := fresh "midx" in
    let r' := fresh "r'" in
    let H := fresh "H" in
    let H0 := fresh "H0" in
    let IHfromADT := fresh "IHfromADT" in
    let induction_tac := (fun offset => induction offset as [cidx r H|midx r r' H IHfromADT H0]) in
    match goal with
    | [ |- forall r : Rep _, fromADT _ r -> _ ] => induction_tac 1
    | [ |- forall r : Rep _, _ -> fromADT _ r -> _ ] => induction_tac 2
    | [ |- forall r : Rep _, _ -> _ -> fromADT _ r -> _ ] => induction_tac 3
    | [ |- forall r : Rep _, _ -> _ -> _ -> fromADT _ r -> _ ] => induction_tac 4
    end;
    [ revert r H | revert r r' H H0 IHfromADT ];
    match goal with
    | [ cidx : ConstructorIndex _ |- _ ] => pattern cidx
    | [ midx : MethodIndex _      |- _ ] => pattern midx
    end;
    apply Iterate_Ensemble_equiv';
    repeat apply Build_prim_and;
    try solve [constructor ] ;
    simpl; intros;
    match goal with
    | [ H : fromMethod _ _ _ |- _ ] =>
      unfold fromMethod in H; simpl in H
    | _ => idtac
    end;
    destruct_ex;
    try computes_to_inv;
    try injections;
    subst;
    eauto;
    match goal with
    | [ cidx : ConstructorIndex _ |- _ ] => clear cidx
    | [ midx : MethodIndex _      |- _ ] => clear midx
    end
  end.

Lemma ADT_ind {sig} (adt : ADT sig) :
  forall (P : Ensemble (Rep adt))
         (PC : forall cidx r, fromConstructor (Constructors adt cidx) r -> P r)
         (PM : forall midx r r', fromMethod' (Methods adt midx r) r' -> P r'),
         forall r : Rep adt, fromADT adt r -> P r.
Proof.
  intros.
  induction H.
    eapply PC.
    exact H.
  eapply PM.
  exact H0.
Qed.

Definition ARep {sig} (adt : ADT sig) := { r : Rep adt | fromADT adt r }.
