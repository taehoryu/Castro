
  subroutine ca_ext_src(lo,hi,&
                        old_state,old_state_l1,old_state_l2,old_state_l3, &
                        old_state_h1,old_state_h2,old_state_h3,&
                        new_state,new_state_l1,new_state_l2,new_state_l3, &
                        new_state_h1,new_state_h2,new_state_h3,&
                        src,src_l1,src_l2,src_l3,src_h1,src_h2,src_h3,problo,dx,time,dt)
    ! compute the external sources for all the conservative equations.
    !
    ! This is called twice in the evolution:
    !
    ! first, for the predictor, it is called with (old, old) states
    !
    ! This is also used in the first pass of the conservative update
    ! (adding dt * S there)
    !
    ! Next we correct the source terms in the conservative update to
    ! time-center them.  Here we call ext_src(old, new), and then
    ! in time_center_source_terms we subtract off 1/2 of the first S
    ! and add 1/2 of the new S.
    !
    ! Therefore, to get a properly time-centered source, generally
    ! speaking, you always want to use the "new" state here.  That
    ! will be the time n state in the first call and the n+1 in the
    ! second call.
    !    

    use amrex_constants_module, only: ZERO
    use meth_params_module, only : NVAR

    use amrex_fort_module, only : rt => amrex_real
    implicit none

    integer         ,intent(in   ) :: lo(3),hi(3)
    integer         ,intent(in   ) :: old_state_l1,old_state_l2,old_state_l3, &
         old_state_h1,old_state_h2,old_state_h3
    integer         ,intent(in   ) :: new_state_l1,new_state_l2,new_state_l3, &
         new_state_h1,new_state_h2,new_state_h3
    integer         ,intent(in   ) :: src_l1,src_l2,src_l3,src_h1,src_h2,src_h3
    real(rt)        ,intent(in   ) :: old_state(old_state_l1:old_state_h1, &
         old_state_l2:old_state_h2, &
         old_state_l3:old_state_h3,NVAR)
    real(rt)        ,intent(in   ) :: new_state(new_state_l1:new_state_h1, &
         new_state_l2:new_state_h2, &
         new_state_l3:new_state_h3,NVAR)
    real(rt)        ,intent(  out) :: src(src_l1:src_h1, &
         src_l2:src_h2, &
         src_l3:src_h3,NVAR)
    real(rt)        ,intent(in   ) :: problo(3),dx(3),time,dt

    ! lo and hi specify work region
    src(lo(1):hi(1),lo(2):hi(2),lo(3):hi(3),:) = ZERO ! Fill work region only

  end subroutine ca_ext_src
