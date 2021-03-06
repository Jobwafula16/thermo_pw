!
! Copyright (C) 2009 Quantum ESPRESSO group
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
SUBROUTINE run_nscf_tpw(do_band, iq)
  !-----------------------------------------------------------------------
  !
  ! ... This is the main driver of the pwscf program called from the
  ! ... phonon code.
  !
  !
  USE control_flags,   ONLY : conv_ions, twfcollect
  USE basis,           ONLY : starting_wfc, starting_pot, startingconfig
  USE io_files,        ONLY : prefix, tmp_dir, wfc_dir, seqopn
  USE lsda_mod,        ONLY : nspin
  USE control_flags,   ONLY : restart, lscf
  USE check_stop,      ONLY : check_stop_now
  USE fft_base,        ONLY : dffts, dfftp
  !!!
  USE fft_types, ONLY: fft_type_allocate
  USE cell_base, ONLY: at, bg
  USE gvect,     ONLY: gcutm
  USE gvecs,     ONLY: gcutms
  USE klist,     ONLY : qnorm
  !!!
  USE disp,            ONLY : lgamma_iq
  USE control_ph,      ONLY : reduce_io, recover, tmp_dir_phq, &
                              ext_restart, bands_computed, newgrid, qplot, &
                              only_wfc
  USE io_global,       ONLY : stdout
  !!!
  USE grid_irr_iq,     ONLY : done_bands
  USE acfdtest,        ONLY : acfdt_is_active, acfdt_num_der, ir_point, delta_vrs
  USE scf,             ONLY : vrs
  USE force_mod,       ONLY : lforce, lstres

  USE lr_symm_base,    ONLY : minus_q, nsymq, invsymq
  USE qpoint,          ONLY : xq
  USE noncollin_module,ONLY : noncolin
  USE spin_orb,        ONLY : domag
  USE mp_bands,        ONLY : intra_bgrp_comm, nyfft
  USE mp_pools,        ONLY : kunit
  USE el_phon,         ONLY : elph_mat
 !
  IMPLICIT NONE
  !
  LOGICAL, INTENT(IN) :: do_band
  INTEGER, INTENT(IN) :: iq
  !
  LOGICAL :: exst
  !
  CALL start_clock( 'PWSCF' )
  !
  IF (done_bands(iq)) THEN
     WRITE (stdout,'(/,5x,"Bands found: reading from ",a)') TRIM(tmp_dir_phq)
     CALL clean_pw( .TRUE. )
     CALL close_files(.true.)
     wfc_dir=tmp_dir_phq
     tmp_dir=tmp_dir_phq
     kunit=2
     IF (lgamma_iq(iq)) kunit=1
     IF ((noncolin.AND.domag)) THEN
        kunit=4
        IF (lgamma_iq(iq)) kunit=2
     ENDIF
     qnorm = SQRT(xq(1)**2+xq(2)**2+xq(3)**2)
     CALL read_file()
     CALL set_small_group_of_q_tpw(nsymq,invsymq,minus_q)
     RETURN
  ENDIF
  !
  CALL clean_pw( .FALSE. )
  !
  CALL close_files(.true.)
  !
  ! From now on, work only on the _ph virtual directory
  !
  wfc_dir=tmp_dir_phq
  tmp_dir=tmp_dir_phq
  ! ... Setting the values for the nscf run
  !
  startingconfig    = 'input'
  starting_pot      = 'file'
  starting_wfc      = 'atomic'
  lscf              = .FALSE.
  lforce            = .FALSE.
  lstres            = .FALSE.
  restart = ext_restart
  conv_ions=.true.
  !
  !!!
  CALL fft_type_allocate ( dfftp, at, bg, gcutm, intra_bgrp_comm, nyfft=nyfft )
  CALL fft_type_allocate ( dffts, at, bg, gcutms, intra_bgrp_comm, nyfft=nyfft)
  !!!
  CALL setup_nscf_tpw ( newgrid, xq, elph_mat )
  CALL init_run()
!!!!!!!!!!!!!!!!!!!!!!!! ACFDT TEST !!!!!!!!!!!!!!!!
  IF (acfdt_is_active) THEN
    ! ACFDT mumerical derivative test: modify the potential
    IF (acfdt_num_der) vrs(ir_point,1)=vrs(ir_point,1) + delta_vrs
  ENDIF
!!!!!!!!!!!!!!!!!!!!!!!!END OF ACFDT TEST !!!!!!!!!!!!!!!!
!
  IF (do_band) CALL non_scf_tpw ( )


  IF ( check_stop_now() ) THEN
!
!  In this case the code stops inside the band calculation. Save the
!  files and stop the pwscf run
!
     CALL punch( 'config' )
     CALL stop_run( -1 )
     CALL do_stop( 1 )
  ENDIF

  !
  IF (.NOT.reduce_io.and.do_band) THEN
!
!  If only_wfc flag is true, we use the same twfcollect as in the pw.x
!  calculation.
!
     IF (.NOT. only_wfc) twfcollect=.FALSE.
     CALL punch( 'all' )
  ENDIF
  !
  CALL seqopn( 4, 'restart', 'UNFORMATTED', exst )
  CLOSE( UNIT = 4, STATUS = 'DELETE' )
  ext_restart=.FALSE.
  !
  CALL close_files(.true.)
  !

  bands_computed=.TRUE.
  !
  CALL stop_clock( 'PWSCF' )
  !
  RETURN
END SUBROUTINE run_nscf_tpw
