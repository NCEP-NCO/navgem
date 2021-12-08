#!/bin/ksh
###################################################################
echo "----------------------------------------------------"
echo "exnawips - convert NCEP GRIB files into GEMPAK Grids"
echo "----------------------------------------------------"
echo "History: Mar 2000 - First implementation of this new script."
echo "S Lilly: May 2008 - add logic to make sure that all of the "
echo "                    data produced from the restricted ECMWF"
echo "                    data on the CCS is properly protected."
echo "C. Magee: 10/2013 - swap X and Y for rtgssthr Atl and Pac."
echo "HMU       09/2021 - Transition to WOCSS2"
#####################################################################

set -xa

cd $DATA

msg="Begin job for $job"
postmsg "$msg"

#
NAGRIB=nagrib2
#

cpyfil=gds
garea=dset
gbtbls=
maxgrd=4999
kxky=
grdarea=
proj=
output=T
pdsext=no

maxtries=180
fhr=$fstart
while [ $fhr -le $fend ] ; do
  typeset -Z3 fhr

  GRIBIN=$DCOMIN/US058GMET-OPSbd2.NAVGEM${fhr}-${PDY}${cyc}-NOAA-halfdeg.gr2
  GEMGRD=${RUN}_${PDY}${cyc}f${fhr}

  GRIBIN_chk=$GRIBIN

  icnt=1
  while [ $icnt -lt 1000 ]
  do
    if [ -r $GRIBIN_chk ] ; then
      break
    else
      let "icnt=icnt+1"
      sleep 20
    fi
    if [ $icnt -ge $maxtries ]
    then
       if [ "$DCOM_STATUS" = "data of opportunity" ]; then
          mail.py <<ENDMSG
One or more input data files are missing, including $GRIBIN_chk
ENDMSG
           exit 6
       else
           err_exit "FATAL ERROR: $GRIBIN_chk is missing"
       fi
    fi
  done

  cp $GRIBIN grib$fhr

  export pgm="${NAGRIB} F$fhr"
  startmsg

  $NAGRIB << EOF
   GBFILE   = grib$fhr
   INDXFL   = 
   GDOUTF   = $GEMGRD
   PROJ     = $proj
   GRDAREA  = $grdarea
   KXKY     = $kxky
   MAXGRD   = $maxgrd
   CPYFIL   = $cpyfil
   GAREA    = $garea
   OUTPUT   = $output
   GBTBLS   = $gbtbls
   GBDIAG   = 
   PDSEXT   = $pdsext
  l
  r
EOF
  export err=$?;err_chk
  gpend

  if [ $SENDCOM = "YES" ] ; then
     mv $GEMGRD $COMOUT/$GEMGRD
     if [ $SENDDBN = "YES" ] ; then
         $SIPHONROOT/bin/dbn_alert MODEL ${DBN_ALERT_TYPE} $job \
           $COMOUT/$GEMGRD
     else
       echo "##### DBN_ALERT_TYPE is: ${DBN_ALERT_TYPE} #####"
     fi
  fi

  let fhr=fhr+finc
done

#####################################################################
# GOOD RUN
set +x
echo "**************JOB $RUN NAWIPS COMPLETED NORMALLY ON WCOSS2"
set -x
#####################################################################

msg='Job completed normally.'
echo $msg
postmsg "$msg"

############################### END OF SCRIPT #######################
