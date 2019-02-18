! Process a 2-d gaussian radiation pulse
subroutine fgaussian_pulse(lo, hi, p, plo, phi, nc_p, nbins, rad_bin, &
     ncount, imask, mask_size, r1,&
     rad_comp, dx, dx_fine, xctr, yctr) bind(C, name='fgaussian_pulse')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: rad_bin(0:nbins-1)
  integer, intent(inout) :: ncount(0:nbins-1)
  integer, intent(inout) :: imask(0:mask_size-1,0:mask_size-1)
  integer, intent(in), value :: mask_size, r1, rad_comp
  real(rt), intent(in), value :: dx_fine, xctr, yctr
  real(rt), intent(in) :: dx(3)

  integer :: ii, jj, k, index
  real(rt) :: xx, yy, r_zone

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  k = lo(3)
  do jj = lo(2), hi(2)
     do ii = lo(1), hi(1)

        if ( any(imask(ii*r1:(ii+1)*r1-1, &
             jj*r1:(jj+1)*r1-1) .eq. 1) ) then

           r_zone = sqrt((xx-xctr)**2 + (yy-yctr)**2)

           index = r_zone/dx_fine

           ! weight the zone's data by its size
           rad_bin(index) = rad_bin(index) + &
                p(ii,jj,1,rad_comp)*r1**2

           ncount(index) = ncount(index) + r1**2

           imask(ii*r1:(ii+1)*r1-1, &
                jj*r1:(jj+1)*r1-1) = 0

        end if

     enddo
  enddo

end subroutine fgaussian_pulse
