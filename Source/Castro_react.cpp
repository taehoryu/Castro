#include <winstd.H>

#include "Castro.H"
#include "Castro_F.H"

using std::string;

#ifdef REACTIONS
void
#ifdef TAU
Castro::react_first_half_dt(FArrayBox& S_old, FArrayBox& React_Fab, FArrayBox& tau_diff, Real time, Real dt) 
#else
Castro::react_first_half_dt(FArrayBox& S_old, FArrayBox& React_Fab, Real time, Real dt) 
#endif
{
    BL_PROFILE(BL_PROFILE_THIS_NAME() + "::strang_chem(MultiFab&,...");
    const Real strt_time = ParallelDescriptor::second();

    if (do_react == 1)
    {

       // Note that here we react on the valid region *and* the ghost cells (i.e. the whole FAB)
       const Box& bx   = S_old.box();
#ifdef TAU
            reactState(S_old, S_old, React_Fab, tau_diff, bx, time, 0.5*dt);
#else
            reactState(S_old, S_old, React_Fab, bx, time, 0.5*dt);
#endif

        reset_internal_energy(S_old);
    }

    if (verbose > 1)
    {
        const int IOProc   = ParallelDescriptor::IOProcessorNumber();
        Real      run_time = ParallelDescriptor::second() - strt_time;

        ParallelDescriptor::ReduceRealMax(run_time,IOProc);

       if (ParallelDescriptor::IOProcessor()) 
          std::cout << "strang_chem time = " << run_time << '\n';
    }
}

void
#ifdef TAU
Castro::react_second_half_dt(MultiFab& S_new, MultiFab& tau_diff, Real cur_time, Real dt) 
#else
Castro::react_second_half_dt(MultiFab& S_new, Real cur_time, Real dt) 
#endif
{
    BL_PROFILE(BL_PROFILE_THIS_NAME() + "::strang_chem(MultiFab&,...");
    const Real strt_time = ParallelDescriptor::second();

    // Note that here we only react on the valid region of the MultiFab
    if (do_react == 1) 
    {
        MultiFab& ReactMF = get_new_data(Reactions_Type);
        for (MFIter Smfi(S_new); Smfi.isValid(); ++Smfi)
        {
            const Box& bx   = Smfi.validbox();
#ifdef TAU
            reactState(Smfi(), Smfi(), ReactMF[Smfi], tau_diff[Smfi], bx, time, 0.5*dt);
#else
            reactState(Smfi(), Smfi(), ReactMF[Smfi], bx, time, 0.5*dt);
#endif
        }
        ReactMF.mult(1.0/dt);
        reset_internal_energy(S_new);
    }

    if (verbose > 1)
    {
        const int IOProc   = ParallelDescriptor::IOProcessorNumber();
        Real      run_time = ParallelDescriptor::second() - strt_time;

        ParallelDescriptor::ReduceRealMax(run_time,IOProc);

       if (ParallelDescriptor::IOProcessor()) 
          std::cout << "reactState time = " << run_time << '\n';
    }
}

void
Castro::reactState(FArrayBox&        Snew,
                   FArrayBox&        Sold,
                   FArrayBox&        ReactionTerms,
#ifdef TAU
                   FArrayBox&        tau,
#endif
                   const Box&        box,
                   Real              time,
                   Real              dt_react)
{
    BL_FORT_PROC_CALL(CA_REACT_STATE,ca_react_state)
                     (box.loVect(), box.hiVect(), 
                     BL_TO_FORTRAN(Sold),
                     BL_TO_FORTRAN(Snew),
                     BL_TO_FORTRAN(ReactionTerms),
#ifdef TAU
                     BL_TO_FORTRAN(tau),
#endif
                     time,dt_react);
}
#endif
