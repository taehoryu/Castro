subroutine amrex_probinit(init,name,namlen,problo,probhi) bind(c)

  use amrex_constants_module
  use amrex_error_module
  use probdata_module
  use prob_params_module, only: center
  use eos_module
  use eos_type_module
  use model_parser_module

  use network, only : nspec
  use amrex_fort_module, only : rt => amrex_real
  implicit none

  integer, intent(in) :: init, namlen
  integer, intent(in) :: name(namlen)

  real(rt), intent(in) :: problo(3), probhi(3)

  type (eos_t) :: eos_state

  integer :: untin, i

  namelist /fortin/ &
       model_name,  &
       heating_time, heating_rad, heating_peak, heating_sigma, &
       prob_type

  !
  !     Build "probin" filename -- the name of file containing fortin namelist.
  !
  integer   :: ipos
  integer, parameter :: maxlen=127
  character probin*(maxlen)
  character (len=256) :: header_line

  if (namlen > maxlen) then
     call amrex_error("probin file name too long")
  end if

  do i = 1, namlen
     probin(i:i) = char(name(i))
  end do

  ! set namelist defaults

  heating_time = 0.5e0_rt
  heating_rad = 0.0e0_rt
  heating_peak = 1.e16_rt
  heating_sigma = 1.e7_rt
  prob_type = 1


  ! Read namelists in probin file
  open(newunit=untin, file=probin(1:namlen), form='formatted', status='old')
  read(untin,fortin)
  close(unit=untin)

  ! Read in the initial model

  call read_model_file(model_name)

  ! Save some of the data locally

  allocate(hse_r(npts_model),hse_rho(npts_model), &
           hse_t(npts_model),hse_p(npts_model))
  allocate(hse_s(nspec,npts_model))

  hse_r   = model_r(:)
  hse_rho = model_state(:,idens_model)
  hse_t   = model_state(:,itemp_model)
  hse_p   = model_state(:,ipres_model)
  do i = 1, nspec
     hse_s(i,:) = model_state(:,ispec_model+i-1)
  enddo

#if AMREX_SPACEDIM == 1
  ! 1-d assumes spherical, with center at origin
  center(1) = ZERO
  center(2) = ZERO
  center(3) = ZERO
#elif AMREX_SPACEDIM == 2
  ! 2-d assumes axisymmetric
  center(1) = ZERO
  center(2) = HALF*(problo(2) + probhi(2))
  center(3) = ZERO
#else
  center(1) = HALF*(problo(1) + probhi(1))
  center(2) = HALF*(problo(2) + probhi(2))
  center(3) = HALF*(problo(3) + probhi(3))
#endif

#if AMREX_SPACEDIM == 1
  xmin = problo(1)
  xmax = probhi(1)

  if (xmin /= 0.e0_rt) then
     call amrex_error("ERROR: xmin should be 0!")
  endif

  ymin = ZERO
  ymax = ZERO
  zmin = ZERO
  zmax = ZERO

#elif AMREX_SPACEDIM == 2
  xmin = problo(1)
  if (xmin /= 0.e0_rt) then
     call amrex_error("ERROR: xmin should be 0!")
  endif

  xmax = probhi(1)

  ymin = problo(2)
  ymax = probhi(2)

  zmin = ZERO
  zmax = ZERO

#else
  xmin = problo(1)
  xmax = probhi(1)

  ymin = problo(2)
  ymax = probhi(2)

  zmin = problo(3)
  zmax = probhi(3)
#endif

  ! store the state at the very top of the model for the boundary
  ! conditions
  allocate (hse_X_top(nspec))

  hse_rho_top  = hse_rho(npts_model)
  hse_t_top    = hse_t(npts_model)
  hse_X_top(:) = hse_s(:,npts_model)

  ! set hse_eint_top and hse_p_top via the EOS
  eos_state%rho   = hse_rho_top
  eos_state%T     = hse_T_top
  eos_state%xn(:) = hse_X_top

  call eos(eos_input_rt, eos_state)

  hse_eint_top = eos_state%e
  hse_p_top = eos_state%p

end subroutine amrex_probinit

! ::: -----------------------------------------------------------
! ::: This routine is called at problem setup time and is used
! ::: to initialize data on each grid.
! :::
! ::: NOTE:  all arrays have one cell of ghost zones surrounding
! :::        the grid interior.  Values in these cells need not
! :::        be set here.
! :::
! ::: INPUTS/OUTPUTS:
! :::
! ::: level     => amr level of grid
! ::: time      => time at which to init data
! ::: lo,hi     => index limits of grid interior (cell centered)
! ::: nstate    => number of state components.  You should know
! :::		   this already!
! ::: state     <=  Scalar array
! ::: delta     => cell size
! ::: xlo,xhi   => physical locations of lower left and upper
! :::              right hand corner of grid.  (does not include
! :::		   ghost region).
! ::: -----------------------------------------------------------
subroutine ca_initdata(level, time, lo, hi, nscal, &
                       state, state_lo, state_hi, delta, xlo, xhi)

  use amrex_constants_module
  use probdata_module
  use eos_module
  use eos_type_module
  use network, only : nspec
  use interpolate_module
  use model_parser_module, only: npts_model
  use meth_params_module, only : NVAR, URHO, UMX, UMY, UMZ, UTEMP, UEDEN, UEINT, UFS
  use prob_params_module, only : center
  use amrex_fort_module, only : rt => amrex_real
  implicit none

  integer, intent(in) :: level, nscal
  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: state_lo(3), state_hi(3)
  real(rt), intent(inout) :: state(state_lo(1):state_hi(1),state_lo(2):state_hi(2),state_lo(3):state_hi(3),NVAR)
  real(rt), intent(in) :: time, delta(3)
  real(rt), intent(in) :: xlo(3), xhi(3)

  real(rt) :: x, y, z, dist
  integer :: i, j, k, n

  type (eos_t) :: eos_state

  ! Interpolate rho, T and X
  do k = lo(3), hi(3)
     z = zmin + (dble(k) + HALF)*delta(3) - center(3)

     do j = lo(2), hi(2)
        y = ymin + (dble(j) + HALF)*delta(2) - center(2)

        do i = lo(1), hi(1)
           x = xmin + (dble(i) + HALF)*delta(1) - center(1)

#if AMREX_SPACEDIM == 1
           dist = x
#elif AMREX_SPACEDIM == 2
           dist = sqrt(x*x + y*y)
#else
           dist = sqrt(x*x + y*y + z*z)
#endif

           state(i,j,k,URHO ) = interpolate(dist, npts_model, hse_r, hse_rho)
           state(i,j,k,UTEMP) = interpolate(dist, npts_model, hse_r, hse_t)

           do n= 1, nspec
              state(i,j,k,UFS+n-1) = interpolate(dist, npts_model, hse_r, hse_s(n,:))
           end do

        end do
     end do
  end do

  ! Compute energy from rho,T and X
  do k = lo(3), hi(3)
     do j = lo(2), hi(2)
        do i = lo(1), hi(1)
           eos_state%rho = state(i,j,k,URHO)
           eos_state%T = state(i,j,k,UTEMP)
           eos_state%xn = state(i,j,k,UFS:UFS+nspec-1)

           call eos(eos_input_rt, eos_state)

           ! we'll add the density weighting shortly
           state(i,j,k,UEINT) = eos_state%e

           state(i,j,k,UMX:UMZ) = ZERO
           state(i,j,k,UEINT) = state(i,j,k,URHO) * state(i,j,k,UEINT)
           state(i,j,k,UEDEN) = state(i,j,k,UEINT)
           state(i,j,k,UFS:UFS+nspec-1) = state(i,j,k,URHO) * state(i,j,k,UFS:UFS+nspec-1)
        end do
     end do
  end do

end subroutine ca_initdata

