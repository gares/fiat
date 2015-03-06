Require Import ADTSynthesis.Common
        ADTSynthesis.ADT.ADTSig ADTSynthesis.ADT.Core ADTSynthesis.ADT.ADTHide
        ADTSynthesis.ADTRefinement.Core.

Lemma RefineHideADT
      extSig'
      oldConstructorIndex oldMethodIndex
      (ConstructorMap : oldConstructorIndex -> ConstructorIndex extSig')
      (MethodMap : oldMethodIndex -> MethodIndex extSig')
      oldADT
: forall newADT newADT',
    refineADT newADT newADT'
    -> arrow (refineADT oldADT (HideADT ConstructorMap MethodMap newADT))
             (refineADT oldADT (HideADT ConstructorMap MethodMap newADT')).
Proof.
  unfold arrow.
  intros ? ? [AbsR ? ?] [AbsR' ? ?].
  destruct_head ADT.
  exists (fun r_o r_n => exists r_n', AbsR' r_o r_n' /\ AbsR r_n' r_n);
    simpl; intros.
  - destruct_ex; intuition.
    rewrite_rev_hyp; try eassumption; [].
    autorewrite with refine_monad; f_equiv.
  - destruct_ex; intuition.
    rewrite_rev_hyp; try eassumption; [].
    autorewrite with refine_monad; f_equiv.
    unfold pointwise_relation; intros;
    intros v Comp_v; computes_to_inv; subst; simpl in *;
    eauto.
Qed.
