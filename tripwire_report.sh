#! /bin/bash

#-------- Manuel Iván San Martín Castillo ---------#
#==================================================#
#====== Script to send a Tripwire via e-mail ======#
#==================================================#
#
# MANDATORY: It's necessary to install mutt package if mailutils version don't support -A flag
#
#----- Variables -----#
REPORTDIR="report_tmp"
REPORTTXT="report.txt"
REPORTPS="report.ps"
REPORTPDF="tripwire_report_$(date +%d)-$(date +%m)-$(date +%Y).pdf"
EMAIL="fail2banivan@gmail.com" #<--- Change This

#----- Specifies that SSMTP will be the binary used for mail sending -----#
#export SENDMAIL=/usr/sbin/ssmtp #<--- Uncomment this just in case of using a mailutils version with -A flag supported

#----- Temporal directory creation on /tmp -----#
/usr/bin/mkdir /tmp/$REPORTDIR && /usr/bin/chmod 700 /tmp/$REPORTDIR;

#----- Report generation on a .txt file -----#
/usr/sbin/tripwire --check > /tmp/$REPORTDIR/$REPORTTXT;

#----- PostScript file generation from .txt file -----#
/usr/bin/a2ps -o /tmp/$REPORTDIR/$REPORTPS /tmp/$REPORTDIR/$REPORTTXT;

#----- PostScript to PDF file conversion -----#
/usr/bin/ps2pdf /tmp/$REPORTDIR/$REPORTPS /tmp/$REPORTDIR/$REPORTPDF;

#----- Sending PDF attached on the mail -----#
/usr/bin/echo "Informe diario de Tripwire - $(date '+%A, %d de %B de %Y, %H:%M:%S')" | /usr/bin/mutt -s "[Tripwire] Informe diario - $(date +%d)/$(date +%m)/$(date +%Y)" -a /tmp/$REPORTDIR/$REPORTPDF -- $EMAIL
#/usr/bin/echo "Informe diario de Tripwire - $(date '+%A, %d de %B de %Y, %H:%M:%S')" | /usr/bin/mail -s "[Tripwire] Informe diario - $(date +%d)/$(date +%m)/$(date +%Y)" -A /tmp/$REPORTDIR/$REPORTPDF $EMAIL #<--- Uncomment this just in case of using a mailutils version with -A flag supported

#----- Temporal directory remove with all its contents as well -----#
/usr/bin/rm -rf /tmp/$REPORTDIR


