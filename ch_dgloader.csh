#! /bin/csh
#
# CH for MPDL 2023-09-22
#
#
###########################################################################
# Parameter: $1 = input csv file containing De Gruyter holdings           #
#                                                                         #
###########################################################################

if ($#argv != 1 ) then
   goto usage
endif

set INPUTFILE = $1
set OUTPUTFILE = `echo "degruyter.mrc"`

if !(-f $INPUTFILE) then
  echo "Datei $INPUTFILE existiert nicht"
  exit
endif

############################################################################
# harvest valid ISBNs from holdings list                                   #
############################################################################

clear
echo " "
echo "Launch De Gruyter MARC file loader..."
sleep 1

echo " "
echo "Do charset encoding conversion"
sleep 0.25
dos2unix $INPUTFILE
sleep 1

echo " "
echo "Processing ISBNs in csv input file..."
set DATEEXTENSION = `date +%Y%m%d`
set TEMPFOLDER = `echo $DATEEXTENSION"_temp"`

mkdir -p ./$TEMPFOLDER
set ISBNFILE = `echo $TEMPFOLDER/"tmp.isbns"`
grep -o '^.*978.*' $INPUTFILE | sed 's/^.*978/978/g; s/-//g; s/.//14g; /[^0-9]/g' | sort --unique | sed 's/^/https:\/\/raw.githubusercontent.com\/oschmalfuss\/degruyter\/main\/title_records\//g; s/$/\.mrc/g' > $ISBNFILE

sleep 1

set ISBNCOUNT = `wc -l < $ISBNFILE`
echo " "
echo "Success: $ISBNCOUNT ISBNs extracted from input file."
sleep 1

############################################################################
# fetch MARC data from provider                                            #
############################################################################

echo " "
echo "Initiating MARC download procedure - please wait..."
sleep 1
cd $TEMPFOLDER
xargs -P 25 -n 1 curl -s -O < tmp.isbns 
cd -

set MARCCOUNT = `find $TEMPFOLDER -name "9*.mrc" -size +400c | wc -l`
sleep 1

echo " "
echo "Success: $MARCCOUNT MARC files downloaded."

############################################################################
# eliminate empty and/or invalid MARC files and do charset adaptions       #
############################################################################

sleep 0.25
echo " "
echo "Validating downloaded files - please wait..."

find $TEMPFOLDER -name "*.mrc" -size -400c -delete

dos2unix -f -q $TEMPFOLDER/*.mrc

############################################################################
# remove TEMP files and deliver resulting MARC file                        #
############################################################################

cat $TEMPFOLDER/9*.mrc > ./$OUTPUTFILE
sleep 1
echo " "
echo "Cleaning up TEMP folder..."
rm -r $TEMPFOLDER
sleep 1
echo " "
echo "Success: Data load finished! $ISBNCOUNT unique ISBNs were extracted from input file, $OUTPUTFILE contains $MARCCOUNT valid records loaded from De Gruyter."
sleep 0.25
echo " "
echo " "
exit


############################################################################
usage:
      echo "usage: $0 <input_file>"
      echo "  eg.: $0 degruyter.isbns"
#eof
