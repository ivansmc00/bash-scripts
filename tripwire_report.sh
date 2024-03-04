#! /bin/bash

#-------- Manuel Iván San Martín Castillo ---------#
#==================================================#
#====== Script to send a Tripwire via e-mail ======#
#==================================================#

#----- Variables -----#
REPORTDIR="report_tmp"
REPORTTXT="report.txt"
REPORTPS="report.ps"
REPORTPDF="tripwire_report_$(date +%d)-$(date +%m)-$(date +%Y).pdf"
EMAIL="foo-bar@example.com" #<--- Change This

#----- Specifies that SSMTP will be the binary used for mail sending -----#
export SENDMAIL=/usr/sbin/ssmtp #<--- Change if necessary

#----- Temporal directory creation on /tmp -----#
/usr/bin/mkdir /tmp/$REPORTDIR && /usr/bin/chmod 700 /tmp/$REPORTDIR;

#----- Report generation on a .txt file -----#
/usr/sbin/tripwire --check > /tmp/$REPORTDIR/$REPORTTXT;

#----- PostScript file generation from .txt file -----#
/usr/bin/a2ps -o /tmp/$REPORTDIR/$REPORTPS /tmp/$REPORTDIR/$REPORTTXT;

#----- PostScript to PDF file conversion -----#
/usr/bin/ps2pdf /tmp/$REPORTDIR/$REPORTPS /tmp/$REPORTDIR/$REPORTPDF;

#----- Sending PDF attached on the mail -----#
/usr/bin/echo "Informe diaro de Tripwire - $(date "+%A, %d de %B de %Y, %H:%M:%S")" | /usr/bin/mail -s "[Tripwire] Informe diario - $(date +%d)/$(date +%m)/$(date +%Y)" -A /tmp/$REPORTDIR/$REPORTPDF $EMAIL

#----- Temporal directory remove with all its contents as well -----#
/usr/bin/rm -rf /tmp/$REPORTDIR
