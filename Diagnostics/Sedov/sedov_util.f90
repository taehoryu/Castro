! Process a 1-d sedov problem to produce rho, u, and p as a
! function of r, for comparison to the analytic solution.

subroutine fextract1d(lo, hi, p, plo, phi, nc_p, nbins, dens_bin, &
     vel_bin, pres_bin, e_bin, imask, mask_size, r1,&
     dens_comp, xmom_comp, pres_comp, rhoe_comp) bind(C, name='fextract1d')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: dens_bin(0:nbins-1)
  real(rt), intent(inout) :: vel_bin(0:nbins-1)
  real(rt), intent(inout) :: pres_bin(0:nbins-1)
  real(rt), intent(inout) :: e_bin(0:nbins-1)
  integer, intent(inout) :: imask(0:mask_size-1)
  integer, intent(in), value :: mask_size, r1, dens_comp, xmom_comp, pres_comp, rhoe_comp

  integer :: ii, index

  write(*,*) "imask = ", imask

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  do ii = plo(1), phi(1)

     if ( any(imask(ii*r1:(ii+1)*r1-1) .eq. 1) ) then

        index = ii * r1

        write(*,*) p(ii,1,1,dens_comp)

        dens_bin(index:index+(r1-1)) = p(ii,1,1,dens_comp)

        vel_bin(index:index+(r1-1)) = &
             abs(p(ii,1,1,xmom_comp)) / p(ii,1,1,dens_comp)

        pres_bin(index:index+(r1-1)) = p(ii,1,1,pres_comp)

        e_bin(index:index+(r1-1)) = &
             p(ii,1,1,rhoe_comp)  / p(ii,1,1,dens_comp)

        imask(ii*r1:(ii+1)*r1-1) = 0

     end if

  enddo

end subroutine fextract1d

subroutine fextract2d_cyl(lo, hi, p, plo, phi, nc_p, nbins, dens_bin, &
     vel_bin, pres_bin, e_bin, ncount, imask, mask_size, r1, &
     dens_comp, xmom_comp, ymom_comp, pres_comp, rhoe_comp, dx_fine, dx, rr, &
     xctr, yctr) bind(C, name='fextract2d_cyl')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: dens_bin(0:nbins-1)
  real(rt), intent(inout) :: vel_bin(0:nbins-1)
  real(rt), intent(inout) :: pres_bin(0:nbins-1)
  real(rt), intent(inout) :: e_bin(0:nbins-1)
  integer, intent(inout) :: ncount(0:nbins-1)
  integer, intent(in) :: mask_size(2)
  integer, intent(inout) :: imask(0:mask_size(1)-1,0:mask_size(2)-1)
  integer, intent(in), value :: r1, dens_comp, xmom_comp, ymom_comp, pres_comp, rhoe_comp
  real(rt), intent(in), value :: dx_fine, rr, xctr, yctr
  real(rt), intent(in) :: dx(3)

  integer :: ii, jj, index
  real(rt) :: xx, yy, r_zone

  write(*,*) "imask = ", imask

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  do jj = plo(2), phi(2)
     yy = (jj + HALF)*dx(2)/rr
     do ii = plo(1), phi(1)
        xx = (ii + HALF)*dx(1)/rr

        if ( any(imask(ii*r1:(ii+1)*r1-1, &
             jj*r1:(jj+1)*r1-1) .eq. 1) ) then

           r_zone = sqrt((xx-xctr)**2 + (yy-yctr)**2)

           index = r_zone/dx_fine

           write(*,*) p(ii,1,1,dens_comp)

           dens_bin(index) = dens_bin(index) + &
                p(ii,jj,1,dens_comp)*r1**2

           vel_bin(index) = vel_bin(index) + &
                (sqrt(p(ii,jj,1,xmom_comp)**2 + &
                p(ii,jj,1,ymom_comp)**2)/ &
                p(ii,jj,1,dens_comp))*r1**2

           pres_bin(index) = pres_bin(index) + &
                p(ii,jj,1,pres_comp)*r1**2

           e_bin(index) = e_bin(index) + &
                (p(ii,jj,1,rhoe_comp)/p(ii,jj,1,dens_comp))*r1**2

           ncount(index) = ncount(index) + r1**2

           imask(ii*r1:(ii+1)*r1-1, &
                jj*r1:(jj+1)*r1-1) = 0

        end if

     enddo
  enddo

end subroutine fextract2d_cyl

subroutine fextract2d_sph(lo, hi, p, plo, phi, nc_p, nbins, dens_bin, &
     vel_bin, pres_bin, e_bin, volcount, imask, mask_size, r1,&
     dens_comp, xmom_comp, ymom_comp, pres_comp, rhoe_comp, dx_fine, dx, rr, yctr) &
     bind(C, name='fextract2d_sph')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: dens_bin(0:nbins-1)
  real(rt), intent(inout) :: vel_bin(0:nbins-1)
  real(rt), intent(inout) :: pres_bin(0:nbins-1)
  real(rt), intent(inout) :: e_bin(0:nbins-1)
  integer, intent(inout) :: volcount(0:nbins-1)
  integer, intent(in) :: mask_size(2)
  integer, intent(inout) :: imask(0:mask_size(1)-1,0:mask_size(2)-1)
  integer, intent(in), value :: r1, dens_comp, xmom_comp, ymom_comp, pres_comp, rhoe_comp
  real(rt), intent(in), value :: dx_fine, yctr, rr
  real(rt), intent(in) :: dx(3)

  integer :: ii, jj, index
  real(rt) :: xx, xl, xr, yy, yl, yr, r_zone, vol, vel

  write(*,*) "imask = ", imask

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  do jj = plo(2), phi(2)
     yy = (dble(jj) + HALF)*dx(2)/rr
     yl = (dble(jj))*dx(2)/rr
     yr = (dble(jj) + ONE)*dx(2)/rr

     do ii = plo(1), phi(1)
        xx = (dble(ii) + HALF)*dx(1)/rr
        xl = (dble(ii))*dx(1)/rr
        xr = (dble(ii) + ONE)*dx(1)/rr

        if ( any(imask(ii*r1:(ii+1)*r1-1, &
             jj*r1:(jj+1)*r1-1) .eq. 1) ) then

           r_zone = sqrt((xx)**2 + (yy-yctr)**2)

           index = r_zone/dx_fine

           vol = (xr**2 - xl**2)*(yr - yl)

           write(*,*) p(ii,1,1,dens_comp)

           ! weight the zone's data by its size
           dens_bin(index) = dens_bin(index) + &
                p(ii,jj,1,dens_comp) * vol

           vel = sqrt(p(ii,jj,1,xmom_comp)**2 + &
                p(ii,jj,1,ymom_comp)**2) / &
                p(ii,jj,1,dens_comp)
           vel_bin(index) = vel_bin(index) + vel * vol

           pres_bin(index) = pres_bin(index) + &
                p(ii,jj,1,pres_comp) * vol

           e_bin(index) = e_bin(index) + &
                (p(ii,jj,1,rhoe_comp) / p(ii,jj,1,dens_comp)) * vol

           volcount(index) = volcount(index) + vol

           imask(ii*r1:(ii+1)*r1-1, &
                jj*r1:(jj+1)*r1-1) = 0

        end if

     enddo
  enddo

end subroutine fextract2d_sph


subroutine fextract3d_cyl(lo, hi, p, plo, phi, nc_p, nbins, dens_bin, &
     vel_bin, pres_bin, e_bin, ncount, imask, mask_size, r1, &
     dens_comp, xmom_comp, ymom_comp, zmom_comp, pres_comp, rhoe_comp, dx_fine, dx, rr, &
     xctr, yctr) bind(C, name='fextract3d_cyl')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: dens_bin(0:nbins-1)
  real(rt), intent(inout) :: vel_bin(0:nbins-1)
  real(rt), intent(inout) :: pres_bin(0:nbins-1)
  real(rt), intent(inout) :: e_bin(0:nbins-1)
  integer, intent(inout) :: ncount(0:nbins-1)
  integer, intent(in) :: mask_size(3)
  integer, intent(inout) :: imask(0:mask_size(1)-1,0:mask_size(2)-1,0:mask_size(3)-1)
  integer, intent(in), value :: r1, dens_comp, xmom_comp, ymom_comp, zmom_comp, pres_comp, rhoe_comp
  real(rt), intent(in), value :: dx_fine, rr, xctr, yctr
  real(rt), intent(in) :: dx(3)

  integer :: ii, jj, kk, index
  real(rt) :: xx, yy, zz, r_zone

  write(*,*) "imask = ", imask

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  do kk = plo(3), phi(3)
     zz = (kk + HALF)*dx(3)/rr
     do jj = plo(2), phi(2)
        yy = (jj + HALF)*dx(2)/rr
        do ii = plo(1), phi(1)
           xx = (ii + HALF)*dx(1)/rr

           if ( any(imask(ii*r1:(ii+1)*r1-1, &
                jj*r1:(jj+1)*r1-1, &
                kk*r1:(kk+1)*r1-1) .eq. 1) ) then

              r_zone = sqrt((xx-xctr)**2 + (yy-yctr)**2)

              index = r_zone/dx_fine

              write(*,*) p(ii,1,1,dens_comp)

              dens_bin(index) = dens_bin(index) + &
                   p(ii,jj,kk,dens_comp)*r1**3

              vel_bin(index) = vel_bin(index) + &
                   (sqrt(p(ii,jj,kk,xmom_comp)**2 + &
                   p(ii,jj,kk,ymom_comp)**2 + &
                   p(ii,jj,kk,zmom_comp)**2)/ &
                   p(ii,jj,kk,dens_comp))*r1**3

              pres_bin(index) = pres_bin(index) + &
                   p(ii,jj,kk,pres_comp)*r1**3

              ncount(index) = ncount(index) + r1**3

              imask(ii*r1:(ii+1)*r1-1, &
                   jj*r1:(jj+1)*r1-1, &
                   kk*r1:(kk+1)*r1-1) = 0

           end if

        enddo
     enddo
  enddo

end subroutine fextract3d_cyl

subroutine fextract3d_sph(lo, hi, p, plo, phi, nc_p, nbins, dens_bin, &
     vel_bin, pres_bin, e_bin, ncount, imask, mask_size, r1,&
     dens_comp, xmom_comp, ymom_comp, zmom_comp, pres_comp, rhoe_comp, dx_fine, dx, rr, &
     xctr, yctr, zctr) &
     bind(C, name='fextract3d_sph')

  use amrex_fort_module, only : rt => amrex_real
  use amrex_constants_module

  implicit none

  integer, intent(in) :: lo(3), hi(3)
  integer, intent(in) :: plo(3), phi(3), nc_p
  integer, intent(in), value :: nbins
  real(rt), intent(in) :: p(plo(1):phi(1),plo(2):phi(2),plo(3):phi(3),1:nc_p)
  real(rt), intent(inout) :: dens_bin(0:nbins-1)
  real(rt), intent(inout) :: vel_bin(0:nbins-1)
  real(rt), intent(inout) :: pres_bin(0:nbins-1)
  real(rt), intent(inout) :: e_bin(0:nbins-1)
  integer, intent(inout) :: ncount(0:nbins-1)
  integer, intent(in) :: mask_size(3)
  integer, intent(inout) :: imask(0:mask_size(1)-1,0:mask_size(2)-1,0:mask_size(3)-1)
  integer, intent(in), value :: r1, dens_comp, xmom_comp, ymom_comp, zmom_comp, pres_comp, rhoe_comp
  real(rt), intent(in), value :: dx_fine, xctr, yctr, zctr, rr
  real(rt), intent(in) :: dx(3)

  integer :: ii, jj, kk, index
  real(rt) :: xx, yy, zz, r_zone, vol, vel

  write(*,*) "imask = ", imask

  ! loop over all of the zones in the patch.  Here, we convert
  ! the cell-centered indices at the current level into the
  ! corresponding RANGE on the finest level, and test if we've
  ! stored data in any of those locations.  If we haven't then
  ! we store this level's data and mark that range as filled.
  do kk = plo(3), phi(3)
      zz = (kk + HALF)*dx(3)/rr
     do jj = plo(2), phi(2)
         yy = (jj + HALF)*dx(2)/rr

        do ii = plo(1), phi(1)
           xx = (dble(ii) + HALF)*dx(1)/rr

           if ( any(imask(ii*r1:(ii+1)*r1-1, &
                          jj*r1:(jj+1)*r1-1, &
                          kk*r1:(kk+1)*r1-1) .eq. 1) ) then

              r_zone = sqrt((xx-xctr)**2 + (yy-yctr)**2 + (zz-zctr)**2)

              index = r_zone/dx_fine

              write(*,*) p(ii,1,1,dens_comp)

              ! weight the zone's data by its size
              dens_bin(index) = dens_bin(index) + &
                   p(ii,jj,kk,dens_comp)*r1**3

              vel_bin(index) = vel_bin(index) + &
                   (sqrt(p(ii,jj,kk,xmom_comp)**2 + &
                         p(ii,jj,kk,ymom_comp)**2 + &
                         p(ii,jj,kk,zmom_comp)**2)/ &
                         p(ii,jj,kk,dens_comp))*r1**3

              pres_bin(index) = pres_bin(index) + &
                   p(ii,jj,kk,pres_comp)*r1**3

              e_bin(index) = e_bin(index) + &
                   (p(ii,jj,kk,rhoe_comp)/p(ii,jj,kk,dens_comp))*r1**3

              ncount(index) = ncount(index) + r1**3

              imask(ii*r1:(ii+1)*r1-1, &
                    jj*r1:(jj+1)*r1-1, &
                    kk*r1:(kk+1)*r1-1) = 0

           end if

        enddo
     enddo
  enddo

end subroutine fextract3d_sph
