!
! Copyright (C) 2013 Andrea Dal Corso
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
!-----------------------------------------------------------------------
SUBROUTINE thermo_readin()
  !-----------------------------------------------------------------------
  !
  !  This routine reads the input of pw.x and an additional namelist in which 
  !  we specify the calculations to do, the files where the data are read
  !  and written and the variables of the calculations.
  !
  USE kinds,                ONLY : DP
  USE thermo_mod,           ONLY : what
  USE control_thermo,       ONLY : outdir_thermo, flevdat,    &
                                   flfrc, flfrq, fldos, fltherm,  &
                                   flanhar, filband
  USE thermodynamics,       ONLY : ngeo, tmin, tmax, deltat, ntemp
  USE ifc,                  ONLY : nq1_d, nq2_d, nq3_d, ndos, deltafreq, zasr, &
                                   disp_q, disp_wq, disp_nqs, freqmin_input, &
                                   freqmax_input
  USE input_parameters,     ONLY : outdir
  USE read_input,           ONLY : read_input_file
  USE command_line_options, ONLY : input_file_ 
  USE control_paths,        ONLY : xqaux, wqaux, npk_label, letter, &
                                   label_list, nqaux, q_in_band_form, &
                                   q_in_cryst_coord, q2d, point_label_type, &
                                   nbnd_bands, label_disp_q, letter_path
  USE control_gnuplot,      ONLY : flgnuplot, flpsband, flpsdisp, &
                                   flpsdos, flpstherm, flpsanhar 
  USE control_bands,        ONLY : flpband, emin_input, emax_input
  USE mp_world,             ONLY : world_comm
  USE mp_images,            ONLY : nimage, my_image_id, root_image
  USE parser,               ONLY : read_line
  USE io_global,            ONLY : meta_ionode, meta_ionode_id
  USE mp,                   ONLY : mp_bcast
  !
  IMPLICIT NONE
  INTEGER :: ios
  CHARACTER(LEN=6) :: int_to_char
  CHARACTER(LEN=512) :: dummy
  CHARACTER(LEN=256), ALLOCATABLE :: input(:)
  INTEGER, ALLOCATABLE :: iun_image(:)
  INTEGER :: image
  INTEGER :: iq, ipol, i, j, k

  INTEGER            :: nch
  LOGICAL :: tend, terr, read_paths
  CHARACTER(LEN=256) :: input_line, buffer
  !
  NAMELIST / input_thermo / what, ngeo, zasr,             &
                            flfrc, flfrq, fldos, fltherm, &
                            flanhar, filband,             &
                            nq1_d, nq2_d, nq3_d,          &
                            tmin, tmax, deltat, ntemp,    &
                            freqmin_input, freqmax_input, &
                            ndos, deltafreq,              &
                            q2d, q_in_band_form,          &
                            q_in_cryst_coord,             &
                            point_label_type,             &
                            nbnd_bands,                   &
                            flevdat,                      &
                            flpband,                      &
                            flgnuplot, flpsband,          &
                            flpsdisp, flpsdos, flpstherm, &
                            flpsanhar,                    &
                            emin_input, emax_input
  !
  !  First read the input of thermo. Only one node reads
  !
  what=' '
  ngeo=0

  filband='output_band.dat'
  flpband='output_pband.dat'
  flfrc='output_frc.dat'
  flfrq='output_frq.dat'
  fldos='output_dos.dat'
  fltherm='output_therm.dat'
  flanhar='output_anhar.dat'
  flevdat='output_ev.dat'

  nq1_d=16
  nq2_d=16
  nq3_d=16
  zasr='simple'
  freqmin_input=0.0_DP
  freqmax_input=0.0_DP
  deltafreq=1.0_DP
  ndos=1

  tmin=1.0_DP
  tmax=800.0_DP
  deltat=2.0_DP
  ntemp=1

  nbnd_bands=0
  emin_input=0.0_DP
  emax_input=0.0_DP

  flgnuplot='gnuplot.tmp'
  flpsband='output_band.ps'
  flpsdisp='output_disp.ps'
  flpsdos='output_dos.ps'
  flpstherm='output_therm.ps'
  flpsanhar='output_anhar.ps'


  q2d=.FALSE.
  q_in_band_form=.TRUE.
  q_in_cryst_coord=.FALSE.
  point_label_type='SC'

  IF (meta_ionode) READ( 5, input_thermo, IOSTAT = ios )
  CALL mp_bcast(ios, meta_ionode_id, world_comm )
  CALL errore( 'thermo_readin', 'reading input_thermo namelist', ABS( ios ) )
  !
  CALL bcast_thermo_input()
  !
  read_paths=( what=='scf_bands' .OR. what=='scf_disp' .OR. &
               what=='mur_lc_bands' .OR. what=='mur_lc_disp' .OR. &
               what=='mur_lc_t')

  IF ( ngeo==0 ) THEN
     IF (what(1:4) == 'scf_') ngeo=1
     IF (what(1:6) == 'mur_lc') ngeo=9
  END IF

  nqaux=0
  IF ( read_paths ) THEN

     IF (meta_ionode) READ (5, *, iostat = ios) nqaux

     CALL mp_bcast(ios, meta_ionode_id, world_comm )
     CALL errore ('thermo_readin', 'reading the number of q points', ABS (ios) )
     CALL mp_bcast(nqaux, meta_ionode_id, world_comm )

     ALLOCATE(xqaux(3,nqaux))
     ALLOCATE(wqaux(nqaux))
     ALLOCATE(letter(nqaux))
     ALLOCATE(letter_path(nqaux))
     ALLOCATE(label_list(nqaux))
     ALLOCATE(label_disp_q(nqaux))

     npk_label=0
     letter_path='   '
     DO iq=1, nqaux
        IF (my_image_id==root_image) &
           CALL read_line( input_line, end_of_file = tend, error = terr )
        CALL mp_bcast(input_line, meta_ionode_id, world_comm)
        CALL mp_bcast(tend, meta_ionode_id, world_comm)
        CALL mp_bcast(terr,meta_ionode_id, world_comm)
        IF (tend) CALL errore('thermo_readin','Missing lines',1)
        IF (terr) CALL errore('thermo_readin','Error reading q points',1)
        DO j=1,256   ! loop over all characters of input_line
           IF ( (ICHAR(input_line(j:j)) < 58 .AND. &   ! a digit
                 ICHAR(input_line(j:j)) > 47)      &
             .OR.ICHAR(input_line(j:j)) == 43 .OR. &   ! the + sign
                 ICHAR(input_line(j:j)) == 45 .OR. &   ! the - sign
                 ICHAR(input_line(j:j)) == 46 ) THEN   ! a dot .
!
!   This is a digit, therefore this line contains the coordinates of the
!   k point. We read it and exit from the loop on characters
!
              READ(input_line,*) xqaux(1,iq), xqaux(2,iq), &
                                 xqaux(3,iq), wqaux(iq)
!
!   search for a possible optional letter
!
              DO k=j,256
                 IF (ICHAR(input_line(k:k)) == 39) THEN
                    letter_path(iq)(1:1) = input_line(k+1:k+1)
                    IF (ICHAR(input_line(k+2:k+2)) /= 39) &
                          letter_path(iq)(2:2) = input_line(k+2:k+2)
                    IF (ICHAR(input_line(k+3:k+3)) /= 39) &
                          letter_path(iq)(3:3) = input_line(k+3:k+3)
                    EXIT
                 ENDIF
              ENDDO
              EXIT
           ELSEIF ((ICHAR(input_line(j:j)) < 123 .AND. &
                    ICHAR(input_line(j:j)) > 64))  THEN
!
!   This is a letter, not a space character. We read the next three 
!   characters and save them in the letter array, save also which q point
!   it is
!
              npk_label=npk_label+1
              READ(input_line(j:),'(a3)') letter(npk_label)
              label_list(npk_label)=iq
              letter_path(iq)=letter(npk_label)
!
!  now we remove the letters from input_line and read the number of points
!  of the line. The next two line should account for the case in which
!  there is only one space between the letter and the number of points.
!
              nch=3
              IF ( ICHAR(input_line(j+1:j+1))==32 .OR. &
                   ICHAR(input_line(j+2:j+2))==32 ) nch=2
              buffer=input_line(j+nch:)
              READ(buffer,*,err=50,iostat=ios) wqaux(iq)
50            IF (ios /=0) CALL errore('thermo_readin',&
                                     'problem reading number of points',1)
              EXIT
           ENDIF
        ENDDO
     ENDDO
  END IF
  !
  !  Then open an input for each image and copy the input file
  !
  ALLOCATE(input(nimage))
  ALLOCATE(iun_image(nimage))

  DO image=1,nimage
     input(image)='_temporary_'//TRIM(int_to_char(image))
     iun_image(image)=100+image
  END DO

  IF (meta_ionode) THEN
     DO image=1,nimage
        OPEN(UNIT=iun_image(image),FILE=TRIM(input(image)),STATUS='UNKNOWN', &
             FORM='FORMATTED', ERR=30, IOSTAT=ios )
     ENDDO
     dummy=' '
     DO WHILE ( .TRUE. )
        READ (5,fmt='(A512)',END=20) dummy
        DO image=1,nimage
           WRITE (iun_image(image),'(A)') TRIM(dummy)
        ENDDO
     END DO
     !
20   DO image=1,nimage 
        CLOSE ( UNIT=iun_image(image), STATUS='keep' )
     END DO
  END IF 
30  CALL mp_bcast(ios, meta_ionode_id, world_comm)
  !
  !  Read the input of pw.x and copy the result in the pw.x variables
  !  Note that each image reads its input file
  !
  CALL read_input_file('PW',TRIM(input(my_image_id+1)))
  outdir_thermo=outdir
  CALL iosys()
  input_file_=input(my_image_id+1)
  DEALLOCATE(input)
  DEALLOCATE(iun_image)

  RETURN
END SUBROUTINE thermo_readin

!-----------------------------------------------------------------------
SUBROUTINE thermo_ph_readin()
  !-----------------------------------------------------------------------
  !
  !  This routine reads the input of the ph.x code when the calculation
  !  requires the use of the phonon routines.
  !
  USE thermo_mod, ONLY : what
  USE mp_world,   ONLY : world_comm
  USE io_global,  ONLY : meta_ionode, meta_ionode_id
  USE io_files,   ONLY : outdir_in_ph => outdir
  USE mp,         ONLY : mp_bcast
  USE output, ONLY : fildyn
  USE command_line_options, ONLY : input_file_ 
  USE input_parameters, ONLY : outdir
  !
  IMPLICIT NONE
  INTEGER :: ios
  CHARACTER(LEN=512) :: dummy
  !
  !  Only the meta_io_node reads the input and sends it to all images
  !  the input is read from file input_file_. This routine searches the
  !  string '---'. It is assumed that the input of the ph.x code is
  !  written after this string.
  !
  IF ( what == 'scf_ph' .OR. what== 'scf_disp' .OR. what == 'mur_lc_ph' &
     .OR. what== 'mur_lc_disp' .OR. what == 'mur_lc_t') THEN

     IF (meta_ionode) OPEN(unit=5, FILE=TRIM(input_file_), STATUS='OLD', &
                 FORM='FORMATTED', ERR=20, IOSTAT=ios )
20   CALL mp_bcast(ios, meta_ionode_id, world_comm)
     CALL errore('thermo_ph_readin','error opening file'//TRIM(input_file_),&
                                                                     ABS(ios))
     IF (meta_ionode) REWIND(5)
     dummy=' '
     IF (meta_ionode) THEN
        DO WHILE( TRIM(dummy) /= '---' )
           READ(5, '(A512)', END=40, IOSTAT=ios) dummy
        ENDDO
     END IF
40   CALL mp_bcast(ios, meta_ionode_id, world_comm)
     CALL errore('thermo_readin', 'phonon input not found', ios)
!
!    be sure that pw variables are completely deallocated
!
     CALL clean_pw(.TRUE.)
!
!    save the outdir. NB phq_readin can change the outdir, and it is
!    the responsability of the user to give the correct directory. Ideally
!    outdir should not be given in the input of thermo_pw.
!
     outdir_in_ph=TRIM(outdir)
     CALL phq_readin()
     IF (meta_ionode) CLOSE(5,STATUS='KEEP')
     !
  ENDIF
  !
  RETURN
  !
END SUBROUTINE thermo_ph_readin
