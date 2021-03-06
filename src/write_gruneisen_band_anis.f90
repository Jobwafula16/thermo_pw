!
! Copyright (C) 2015 Andrea Dal Corso 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
SUBROUTINE write_gruneisen_band_anis(file_disp, file_vec)
  !
  ! reads data files produced by write_ph_dispersions for ngeo geometries, 
  ! interpolates them with a quadratic polynomial, computes an writes 
  ! several files with the Gruneisen parameters: the derivatives of the 
  ! logarithm of the phonon frequencies with respect to the logarithm of
  ! the relevant celldm parameters.
  ! This is calculated at the celldm given in input or at the celldm
  ! that corresponds to the temperature given in input.
  ! 
  USE kinds,          ONLY : DP
  USE ions_base,      ONLY : nat, ntyp => nsp
  USE cell_base,      ONLY : celldm
  USE data_files,     ONLY : flgrun
  USE control_paths,  ONLY : nqaux, disp_q, disp_nqs
  USE equilibrium_conf, ONLY : celldm0
  USE thermo_mod,     ONLY : celldm_geo, no_ph, in_degree, reduced_grid, red_central_geo
  USE anharmonic,     ONLY : celldm_t
  USE ph_freq_anharmonic,  ONLY : celldmf_t
  USE grun_anharmonic, ONLY : poly_order
  USE control_grun,   ONLY : temp_ph, celldm_ph
  USE initial_conf,   ONLY : ibrav_save, amass_save, ityp_save
  USE control_thermo, ONLY : ltherm_dos, ltherm_freq, set_internal_path
  USE freq_interpolate, ONLY : interp_freq_anis_eigen, interp_freq_eigen, &
                             compute_polynomial, compute_polynomial_der
  USE temperature,    ONLY : temp, ntemp
  USE quadratic_surfaces, ONLY : evaluate_fit_quadratic, &
                                 evaluate_fit_grad_quadratic, quadratic_var
  USE lattices,       ONLY : compress_celldm, crystal_parameters
  USE io_bands,       ONLY : read_bands, read_parameters, write_bands
  USE mp,             ONLY : mp_bcast
  USE io_global,      ONLY : stdout, ionode, ionode_id
  USE mp_images,      ONLY : intra_image_comm, root_image, my_image_id

  IMPLICIT NONE

  CHARACTER(LEN=256), INTENT(IN) :: file_disp, file_vec

  REAL(DP), ALLOCATABLE :: freq_geo(:,:,:), k(:,:), frequency_geo(:,:), &
                           x_data(:,:), poly_grun(:,:), frequency(:,:), &
                           gruneisen(:,:,:), grad(:), x(:), xd(:)
  COMPLEX(DP), ALLOCATABLE :: displa_geo(:,:,:,:), displa(:,:,:)
  INTEGER :: nks, nmodes, cgeo_eff, central_geo, imode, ios, n, igeo, &
             nwork, idata, ndata, iumode, nvar, degree, icrys
  INTEGER :: find_free_unit, compute_nwork
  REAL(DP) :: cm(6), f, g
  LOGICAL, ALLOCATABLE :: is_gamma(:)
  LOGICAL :: copy_before, allocated_variables
  CHARACTER(LEN=256) :: filename, filedata, filegrun, filefreq
  CHARACTER(LEN=6), EXTERNAL :: int_to_char

  IF ( my_image_id /= root_image ) RETURN
  IF (flgrun == ' ') RETURN

  IF (ionode) iumode=find_free_unit()
  nwork=compute_nwork()
!
!  Part one: Reads the frequencies and the displacements from file.
!
  allocated_variables=.FALSE.
  DO igeo = 1, nwork
     
     IF (no_ph(igeo)) CYCLE
     filedata = 'phdisp_files/'//TRIM(file_disp)//'.g'//TRIM(int_to_char(igeo))
     CALL read_parameters(nks, nmodes, filedata)
     !
     IF (nks <= 0 .or. nmodes <= 0) THEN
        CALL errore('write_gruneisen_band_anis','reading plot namelist',&
                                                                 ABS(ios))
     ELSE
        WRITE(stdout, '(5x, "Reading ",i4," dispersions at ",i6," k-points for&
                       & geometry",i4)') nmodes, nks, igeo
     ENDIF

     IF (.NOT.allocated_variables) THEN
        ALLOCATE (freq_geo(nmodes,nks,nwork))
        ALLOCATE (displa_geo(nmodes,nmodes,nwork,nks))
        ALLOCATE (k(3,nks))
        allocated_variables=.TRUE.
     ENDIF
     CALL read_bands(nks, nmodes, k, freq_geo(1,1,igeo), filedata)

     filename='phdisp_files/'//TRIM(file_vec)//".g"//TRIM(int_to_char(igeo))
     IF (ionode) OPEN(UNIT=iumode, FILE=TRIM(filename), FORM='formatted', &
                   STATUS='old', ERR=200, IOSTAT=ios)
200  CALL mp_bcast(ios, ionode_id, intra_image_comm)
     CALL errore('write_gruneisen_band_anis','modes are needed',ABS(ios))
     !
     IF (ionode) THEN
!
!  readmodes reads a file with the displacements, but writes in displa_geo
!  the normalized eigenvectors of the dynamical matrix
!
        CALL readmodes(nat,nks,k,displa_geo,nwork,igeo,ntyp,ityp_save, &
                                       amass_save, iumode)
        CLOSE(UNIT=iumode, STATUS='KEEP')
     ENDIF
  ENDDO
  CALL mp_bcast(displa_geo, ionode_id, intra_image_comm)
  ALLOCATE (is_gamma(nks))
  DO n=1,nks
     is_gamma(n) = (( k(1,n)**2 + k(2,n)**2 + k(3,n)**2) < 1.d-12)
  ENDDO
!
!  Part two: Compute the Gruneisen parameters
!
  degree=crystal_parameters(ibrav_save)
  IF (reduced_grid) THEN
     nvar=poly_order
  ELSE
     nvar=quadratic_var(degree)
  ENDIF
!
!  find the central geometry in this list of phonons. Prepare also the
!  x data for the computed geometries
!
  CALL find_central_geo(nwork,no_ph,central_geo)
  ALLOCATE(x_data(degree,nwork))
  ndata=0
  DO idata=1, nwork
     IF (no_ph(idata)) CYCLE
     ndata=ndata+1
     IF (central_geo==idata) cgeo_eff=ndata
     IF (reduced_grid) THEN
        CALL compress_celldm(celldm_geo(1,idata),x_data(1,idata),degree, &
                                                                ibrav_save)
     ELSE
        CALL compress_celldm(celldm_geo(1,idata),x_data(1,ndata),degree, &
                                                                ibrav_save)
     ENDIF
  ENDDO 
!
!  find the celldm at which we compute the Gruneisen parameters and compress it
!
  ALLOCATE(x(degree))
  IF (celldm_ph(1)==0.0_DP) THEN
     IF (ltherm_freq) THEN
        CALL evaluate_celldm(temp_ph, cm, ntemp, temp, celldmf_t)
     ELSEIF(ltherm_dos) THEN
        CALL evaluate_celldm(temp_ph, cm, ntemp, temp, celldm_t)
     ELSE
        cm(:)=celldm0(:)
     ENDIF
  ELSE
     cm=celldm_ph(:)
  ENDIF
  CALL compress_celldm(cm,x,degree,ibrav_save)
!
!  calculate the BZ path that corresponds to the cm parameters
!
  celldm(:)=cm(:)
  IF (set_internal_path) CALL set_bz_path()
  IF (nqaux > 0) CALL set_paths_disp()
  IF (disp_nqs /= nks) &
     CALL errore('write_gruneisen_band_anis','Problem with the path',1)

  WRITE(stdout,'(/,5x,"Plotting Gruneisen parameters at celldm:")') 
  WRITE(stdout,'(5x,6f12.7)') cm 
  IF (celldm_ph(1)==0.0_DP.AND.(ltherm_freq.OR.ltherm_dos)) &
            WRITE(stdout,'(5x,"Corresponding to T=",f17.8)') temp_ph
!
! Now allocate space to save the frequencies to interpolate and the
! coeffieints of the polynomial. Allocate also space to save the
! interpolated frequencies and the gruneisen parameters
!
  ALLOCATE(frequency_geo(nmodes,ndata))
  ALLOCATE(displa(nmodes,nmodes,ndata))
  ALLOCATE(poly_grun(nvar,nmodes))
  ALLOCATE(frequency(nmodes,nks))
  ALLOCATE(gruneisen(nmodes,nks,degree))
  ALLOCATE(xd(ndata))
  ALLOCATE(grad(degree))
!
!  then intepolates and computes the derivatives of the polynomial.
!  At the gamma point the gruneisen parameters are not defined, so
!  we copy those of the previous or the next point
!
  copy_before=.FALSE.
  frequency(:,:)= 0.0_DP
  gruneisen(:,:,:)= 0.0_DP
  DO n = 1,nks
     IF (is_gamma(n)) THEN
!
!    In the gamma point the Gruneisen parameters are not defined.
!    In order to have a continuous plot we take the same parameters
!    of the previous point, if this point exists and is not gamma.
!    Otherwise at the next point we copy the parameters in the present one
!
        copy_before=.FALSE.
        IF (n==1) THEN
           copy_before=.TRUE.
        ELSEIF(is_gamma(n-1)) THEN
           copy_before=.TRUE.
        ELSE
           DO imode=1,nmodes
              gruneisen(imode,n,:)=gruneisen(imode,n-1,:)
              frequency(imode,n)=frequency(imode,n-1)
           END DO
!
!  At the gamma point the first three frequencies vanish
!
           DO imode=1,3
              frequency(imode,n)=0.0_DP
           END DO
        ENDIF
     ELSE
        IF (reduced_grid) THEN
!
!  with reduced grid each degree of freedom is calculated separately
!
           DO icrys=1, degree
              ndata=0
              cgeo_eff=0
              DO idata=1,nwork
                 IF (in_degree(idata)==icrys.OR.idata==red_central_geo) THEN
                    ndata=ndata+1
                    xd(ndata)=x_data(icrys,idata)
                    frequency_geo(1:nmodes,ndata)=freq_geo(1:nmodes,n,idata)
                    displa(1:nmodes,1:nmodes,ndata)=&
                                   displa_geo(1:nmodes,1:nmodes,idata,n)
                    IF (idata==red_central_geo) cgeo_eff=ndata
                 ENDIF
              ENDDO
              IF (cgeo_eff==0) cgeo_eff=ndata/2
              CALL interp_freq_eigen(ndata, frequency_geo, xd, cgeo_eff, &
                                  displa, poly_order, poly_grun)
              DO imode=1,nmodes
                 CALL compute_polynomial(x(icrys), poly_order, poly_grun(:,imode),f)
!
!  this function gives the derivative with respect to x(i) multiplied by x(i)
!
                 CALL compute_polynomial_der(x(icrys), poly_order, &
                                                   poly_grun(:,imode),g)
                 frequency(imode,n) = f
                 gruneisen(imode,n,icrys) = -g
                 IF (frequency(imode,n) > 0.0_DP ) THEN
                    gruneisen(imode,n,icrys) = gruneisen(imode,n,icrys)/frequency(imode,n)
                 ELSE
                    gruneisen(imode,n,icrys) = 0.0_DP
                 ENDIF
              ENDDO
           ENDDO
        ELSE
!
!  In this case the frequencies are fitted with a multidimensional polynomial
!
           ndata=0
           DO idata=1,nwork
              IF (no_ph(idata)) CYCLE
              ndata=ndata+1
              frequency_geo(1:nmodes,ndata)=freq_geo(1:nmodes,n,idata)
              displa(1:nmodes,1:nmodes,ndata)=displa_geo(1:nmodes,1:nmodes,idata,n)
           ENDDO
           CALL interp_freq_anis_eigen(nwork, frequency_geo, x_data, cgeo_eff, &
                                    displa, degree, nvar, poly_grun)
!
!  frequencies and gruneisen parameters are calculated at the chosen volume
!
           DO imode=1, nmodes
              CALL evaluate_fit_quadratic(degree,nvar,x,f,poly_grun(1,imode))
              CALL evaluate_fit_grad_quadratic(degree,nvar,x,grad, &
                                                        poly_grun(1,imode))
              frequency(imode,n) = f 
              gruneisen(imode,n,:) = -grad(:)
              IF (frequency(imode,n) > 0.0_DP ) THEN
                 DO icrys=1,degree
                    gruneisen(imode,n,icrys) = x(icrys) * gruneisen(imode,n,icrys) /  &
                                                 frequency(imode,n)
                 END DO
              ELSE
                 gruneisen(imode,n,:) = 0.0_DP
              ENDIF
           ENDDO
        ENDIF
        IF (copy_before) THEN
           gruneisen(1:nmodes,n-1,1:degree) = gruneisen(1:nmodes,n,1:degree)
           frequency(1:nmodes,n-1) = frequency(1:nmodes,n)
        ENDIF
        copy_before=.FALSE.
!
!  At the gamma point the first three frequencies vanish
!
        IF (n>1.AND.is_gamma(n-1)) THEN
           DO imode=1,3
              frequency(imode,n-1)=0.0_DP
           ENDDO
        ENDIF
     ENDIF
  ENDDO
!
!  Writes Gruneisen parameters on file
!
  DO icrys=1, degree
     filegrun='anhar_files/'//TRIM(flgrun)//'_'//TRIM(INT_TO_CHAR(icrys))
     CALL write_bands(nks, nmodes, disp_q, gruneisen(1,1,icrys), 1.0_DP, filegrun)
  END DO
!
!  writes frequencies at the chosen geometry on file
!
  filefreq='anhar_files/'//TRIM(flgrun)//'_freq'
  CALL write_bands(nks, nmodes, disp_q, frequency, 1.0_DP, filefreq)

  DEALLOCATE( grad )
  DEALLOCATE( gruneisen )
  DEALLOCATE( frequency )
  DEALLOCATE( poly_grun )
  DEALLOCATE( displa )
  DEALLOCATE( frequency_geo )
  DEALLOCATE( xd )
  DEALLOCATE( x )
  DEALLOCATE( x_data )
  DEALLOCATE( is_gamma )
  DEALLOCATE( k ) 
  DEALLOCATE( displa_geo )
  DEALLOCATE( freq_geo )

RETURN
END SUBROUTINE write_gruneisen_band_anis

SUBROUTINE evaluate_celldm(temp_ph, cm, ntemp, temp, celldmf_t)

USE kinds, ONLY : DP
USE io_global, ONLY : stdout
IMPLICIT NONE
INTEGER, INTENT(IN) :: ntemp
REAL(DP), INTENT(IN) :: temp(ntemp), celldmf_t(6,ntemp)
REAL(DP), INTENT(INOUT) :: temp_ph, cm(6)

INTEGER :: itemp0, itemp1, itemp

itemp0=1
DO itemp=1,ntemp
   IF (temp(itemp) < temp_ph) itemp0=itemp
ENDDO

IF (itemp0 == ntemp) THEN
   WRITE(stdout,'(5x,"temp_ph too large setting to",f15.8 )') temp(ntemp-1)
   temp_ph=temp(ntemp-1)
   cm(:)=celldmf_t(:,ntemp-1)
   RETURN
ENDIF

IF (itemp0 == 1) THEN
   WRITE(stdout,'(5x,"temp_ph too small setting to",f15.8 )') temp(2)
   temp_ph=temp(2)
   cm(:)=celldmf_t(:,2)
   RETURN
ENDIF

itemp1=itemp0+1

cm(:) = celldmf_t(:,itemp0) + (temp_ph - temp(itemp0)) *           &
                       (celldmf_t(:,itemp1)-celldmf_t(:,itemp0)) / &
                       (temp(itemp1)-temp(itemp0))

RETURN
END SUBROUTINE evaluate_celldm

