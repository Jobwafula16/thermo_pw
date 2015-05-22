!
! Copyright (C) 2015 Andrea Dal Corso 
! This file is distributed under the terms of the
! GNU General Public License. See the file `License'
! in the root directory of the present distribution,
! or http://www.gnu.org/copyleft/gpl.txt .
!
SUBROUTINE plot_gruneisen_band_anis(flinput)
!
!  This is a driver to plot the gruneisen parameters of anisotropic
!  solid. This routine knows only how many Gruneisen parameter files 
!  there are, depending on the Bravais lattice. It generates the names
!  of the postscript files and of the file that contains the Gruneisen
!  parameters and call the routine that makes the plot.
!
USE kinds,           ONLY : DP
USE control_gnuplot, ONLY : flgnuplot
USE postscript_files, ONLY : flpsgrun
USE data_files,      ONLY : flgrun, flpgrun
USE control_pwrun,   ONLY : ibrav_save
USE mp_images,       ONLY : root_image, my_image_id

IMPLICIT NONE

CHARACTER(LEN=256), INTENT(IN) :: flinput
CHARACTER(LEN=256) :: filename, save_flpsgrun, save_flgrun, save_flgnuplot, &
                      save_flpgrun
CHARACTER(LEN=6), EXTERNAL :: int_to_char
INTEGER :: degree, nvar, icrys

IF ( my_image_id /= root_image ) RETURN

CALL compute_degree(ibrav_save, degree, nvar)

save_flgrun=flgrun
save_flpgrun=flpgrun
save_flpsgrun=flpsgrun
save_flgnuplot=flgnuplot

DO icrys=1,degree
   flpsgrun = TRIM(save_flpsgrun)//'_'//TRIM(int_to_char(icrys))
   flgrun = TRIM(save_flgrun)//'_'//TRIM(int_to_char(icrys))
   flpgrun = TRIM(save_flpgrun)//'_'//TRIM(int_to_char(icrys))
   flgnuplot = TRIM(save_flgnuplot)//'_'//TRIM(int_to_char(icrys))
   CALL plotband_sub(3,1,flinput)
END DO

flgrun=save_flgrun
flpgrun=save_flpgrun
flpsgrun=save_flpsgrun
flgnuplot=save_flgnuplot

RETURN
END SUBROUTINE plot_gruneisen_band_anis