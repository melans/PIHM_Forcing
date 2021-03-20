#!/bin/bash

################################################################################
# Bash script to generate forcing file from VIC grids - V.21.03.10
# modified Mar 10, 2021 - V.21.03.10
################################################################################
# created Mar 16, 2018 by anssary@gmail.com under supervision of tusharsinha.iitd@gmail.com
# the script requires a TINs & Grids mapping file that contains the TIN ID, the Grids ID, and the Grid's _Y_X
# here's a sample of this file:
# 1 243 _28.6875_-99.4375
# 2 447 _29.6875_-99.9375
# 3 268 _28.8125_-99.5625
# 4 225 _28.5625_-98.4375
# 5 197 _28.4375_-98.6875
# Usage :
	# 1) copy the script inside a folder (ex. TEST/genforc.sh)
	# 2) copy the necessary file (TINs_Grids) inside the same folder
	# 3) copy the VIC grids inside a sub-folder (ex. TEST/grids/wb_27.8125_-97.4375)
	# 4) cd to the folder (cd TEST)
	# 5) run the script (./genforc.sh)
# change the following variable names as desired
# TINs and Grids mapping file

read -p "TINs_Grids: " TINs_Grids
TINs_Grids=${TINs_Grids:-TINs_Grids}
#TINs_Grids="$TINs_Grids.TG";
# grids folder name
read -p "grids: " grids
grids=${grids:-grids}
#grids="grids";
# generated temp text files folder name
read -p "txt: " txt
txt=${txt:-txt}
#txt="txt";
# From year
read -p "y1: 1950 (accept or enter): " y1
y1=${y1:-1950}
#y1="1950";	# 0 - minutes
# y1="1951";	# 525600 - minutes
# To year
read -p "y2: 1980 (accept or enter): " y2
y2=${y2:-1980}
#y2="1954";	# 2103840 - minutes
# generated forcing file name
forc="$TINs_Grids""_$y1""_$y2"".forc";
################################################################################
# you may -CAREFULLY- change the following parameter
################################################################################
# given that the VIC grids are as follows:
#	wb_Y_X :
# 		col 1,2,3 = yr,m,d
# 		col 4,5,9,10 = TEMP,PREP,WIND,RH
# 	eb_Y_X :
# 		col 1,2,3 = yr,m,d
# 		col 6+7 = NET_SHORT_WAVE+NET_LONG_WAVE = RN
# 		col 15 = VAPOR_PRESSURE
# forcing fields source grid
forc_flds_src="wb,wb,wb,wb,eb,eb";
forc_flds_src="wb,wb,wb,wb,wb,wb";
forc_flds_src=(${forc_flds_src//,/ });
# forcing fields position in the grid file
forc_flds_col="5,4,10,9,6+7,15";
forc_flds_col="5,4,10,9,17+18,22";
forc_flds_col=(${forc_flds_col//,/ });
# fields required in the forcing file (in respective order)
# forc_flds="Prep,Temp,RH,Wind,Rn,VP,LAI,DH,MF,SS"
# forc_flds="Prep,Temp,RH,Wind,Rn,VP,LAI,RL,MF,SS"
forc_flds="PP,TT,RH,WD,RN,VP";
forc_flds=(${forc_flds//,/ });
# forcing fields factors, respectively
forc_flds_fct="/1,*1,/100,*86400,*86400,*1000";
forc_flds_fct=(${forc_flds_fct//,/ });
################################################################################
# LAI and RL series from this reference (https://ldas.gsfc.nasa.gov/nldas/web/web.veg.monthly.table.xls)
# ex. LAI_RL="7,3,10" or LAI_RL="8"
# leave blank to use all layers (1 - 13)
# LAI_RL="6,9,7";
LAI_RL="";
################################################################################
# LAI Interception Storage Factor
LAIf="0.0002";
# Height of wind velocity observation
WNf="10";
# epsilon
epsilon="0.00001";
################################################################################
################################################################################
#					PLEASE DON'T EDIT AFTER THIS LINE
################################################################################
################################################################################
# check if we have all the necessary files
tst1=(`tr ' ' '\n'<<<"${forc_flds_src[@]}"|sort -u|tr '\n' ' '`)
tst2=(`awk '!a[$3]++{printf $3" "}' $TINs_Grids`)
missing="";

for t1 in "${!tst1[@]}";do
	for t2 in "${!tst2[@]}";do
		f=$grids"/""${tst1[t1]}""${tst2[t2]}";
		if [ ! -f $f ]; then
			echo "$f is missing.";
			missing=1;
		fi;
	done;
done;

if [ $missing ]; then
	echo "Please get the missing files and try again.";
	exit;
fi;

# create txt destination folder if not exist
mkdir -p $txt;
# count how many series from the TINs_Grids file
series=`awk 'END{print $1}' $TINs_Grids`;
# count how many rows, from the 1st
rows=$grids/wb`awk '{print $3;exit}' $TINs_Grids`;
# count rows from start year to end year
rows=`awk '$1>="'$y1'"&&$1<="'$y2'"{r++}END{print r}' $rows`;
# multiply by 2, the forcing requires doubling the rows
rows=$((2 * rows));
# loop through forc_flds
for fld in "${!forc_flds[@]}"; do
	# get the src, whcih is the initial of the grid (wb or eb) that include fld
	src="${forc_flds_src[$fld]}";
	# get the column that contains the fld data
	col="${forc_flds_col[$fld]}";
	# in case of Rn sum columns 6,7
	col=${col/+/+\$};
	# short for field
	f="${forc_flds[$fld]}";
	# field factor
	ff="${forc_flds_fct[$fld]}";
	# xtra = add the Height of wind velocity observation
	if [[ "$f" = "WN" ]];then xtra="	"$WNf;else xtra="";fi
	# create the field txt empty file
	echo -n>$txt/$f.txt;
	# display the detailed message about the current file creation
	echo -n "composing $txt/$f.txt from column ((\$$col)$ff) in $src grids ";
	# loop through series
	for (( ser=0;ser++<$series; ));do
		# # display the name of the current file
		# echo "composing $txt/${grid_flds[$i]}.txt";
		# insert the header of each series in the field txt file, and the xtra (for Wind)
		echo "$f	$ser	$rows""$xtra">>$txt/$f.txt;
		# get the grid for the current series
		grid=`awk 'NR=='"$ser"'{print $3}' $TINs_Grids`;
		# find rows in the years y1, y2 range in the grid
		# i starts with 0, write each col value twice in separate new lines
		# multiply or devide by the factor ff, the factor contains the sign (* or /)
		# write the results to the field txt file
		awk '$1>="'$y1'" && $1<="'$y2'"{printf "%.6f\t%.6f\n%.6f\t%.6f\n",i++,($'$col')'$ff',i-'$epsilon',($'$col')'$ff' >> "'$txt'/'$f'.txt"}' $grids/$src$grid;
		# remove the 1st underscore, and replace the 2nd with comma in the grid
		xy=${grid/_/};
		xy=${xy/_/,};
		# display the message about the current grid
		echo -en "\r\t\t\t\t\t\t\t\t ==> series ($ser) , grid ($xy)";
		# add extra new line after each series
		echo>>$txt/$f.txt;
	done
	echo
done
################################################################################
# start working on the last parts LAI, RL, and MF
################################################################################
# display the LAI and RL preparation message
echo "Preparing LAI and RL series"
# preparing LAI and RL arrays
# create a comma separated sequence 1 to 13
_13=`seq -s, 1 13`;
# if LAI_RL is empty fill it with 1 to 13 sequence
LAI_RL=${LAI_RL:-$_13};
# convert LAI_RL string to array
LAI_RL=(${LAI_RL//,/ });
################################################################################
# calculate no. of years
yrs=$((y2-y1+1))
# create daily sum series for years y1 to y2 (if($1>="'$y1'" && $1<="'$y2'"))
# count days in the same month (if(m==$2){d++})
# count and print sum of days by adding sums of months (print ds;ds+=d;print ds;y=$1;m=$2;d=1)
daysSum=`awk 'BEGIN{y="'$y1'";m="01";ds=0}{if($1>="'$y1'" && $1<="'$y2'"){if(m==$2){d++}else{print ds;ds+=d;print ds-1;y=$1;m=$2;d=1}}}END{print ds;ds+=d;print ds-1}' $grids/$src$grid`;
days=( $daysSum );
days=${#days[@]};
################################################################################
# get certain row from the variable array
function _getVarRow {
	sed '1,/'$1'\tSTART/d;/END/,$d' $0|sed 's/# //g'|awk -F, 'NR=='$2
}
################################################################################
# 1st: LAI (leaf area index)
# create the LAI txt empty file
echo -n>$txt/LAI.txt;
# loop through lai series
for lai in "${!LAI_RL[@]}"; do
	# insert LAI headers
	echo "LAI	$((lai+1))	$((yrs*12*2))	$LAIf">>$txt/LAI.txt;
	lais="`_getVarRow LAI ${LAI_RL[$lai]}`";
	# insert LAI series lines
	# Create the LAI series from the daysSum series and seriesLAIs
	echo $daysSum|sed 's/ /\n/g'|awk 'split("'$lais'",lais,","){lai=int((NR-1)/2)%12+1;print $1"\t"lais[lai]}'>>$txt/LAI.txt;
	# add extra new line after each series
	echo>>$txt/LAI.txt;
done;
################################################################################
# 2nd: RL (rough length)
# create the LAI txt empty file
echo -n>$txt/RL.txt;
# loop through rl series
for rl in "${!LAI_RL[@]}"; do
	# insert RL headers
	echo "RL	$((rl+1))	$((yrs*12*2))">>$txt/RL.txt;
	rls="`_getVarRow RL ${LAI_RL[$rl]}`";
	# insert RL series lines
	# # Create the RL series from the daysSum series and seriesLAIs
	echo $daysSum|sed 's/ /\n/g'|awk 'split("'$rls'",rls,","){rl=int((NR-1)/2)%12+1;print $1"\t"rls[rl]}'>>$txt/RL.txt;
	# add extra new line after each series
	echo>>$txt/RL.txt;
done;
################################################################################
# 3rd: MF (melt factor)
# find the MF series in this script
# extract lines equal to no. of days in the determined time period ($y1 to $y2)
# remove the hash symbol
# replace the keyword days with the variable $days
# insert the result in an MF txt empty file
sed '1,/MF\tSTART/d;/END/,$d' $0|\
head -n $((days+1))|\
sed 's/# //g'|\
sed "s/days/$days/g"\
>$txt/MF.txt;
################################################################################
# 4th: SS (sink/source)
################################################################################
# compose the forcing header, and put all files together in the correct order to create the forcing file
# 5 series , 0 for NumG dummy , series , LAI series , 1 melting factor , 0 source / sink
h=`printf $series' %.0s' {1..5}`'0 '$series' '${#LAI_RL[@]}' 1 0';
# create the empty forcing file
echo "Create the forcing file ($forc) and fill the header";
echo $h|sed 's/ /\t/g'>$forc;
allForcFiles="${forc_flds[@]} LAI RL MF";
allForcFiles=${allForcFiles// /.txt txt\/};
cat txt/$allForcFiles.txt >> $forc;
################################################################################
while [ ! -s $forc ]
  do
  printf "%10s \r" Finalizing ... ;
done
# sed -i 's/\\t/\t/' $forc;
echo "DONE";
################################################################################
# VARIABLE
################################################################################
# Land Cover codes
# code,type
# LC	START
# 1,Evergreen Needleleaf Forest
# 2,Evergreen Broadleaf Forest
# 3,Deciduous Needleleaf Forest
# 4,Deciduous Broadleaf Forest
# 5,Mixed Cover
# 6,Woodland
# 7,Wooded Grassland
# 8,Closed Shrubland
# 9,Open Shrubland
# 10,Grassland
# 11,Cropland
# 12,Bare Ground
# 13,Urban and Built-Up
# LC	END
################################################################################
# Leaf Area Index
# rows: code 1-13
# cols: month Jan-Dec
# LAI	START
# 8.76,9.16,9.827,10.093,10.36,10.76,10.493,10.227,10.093,9.827,9.16,8.76
# 5.117,5.117,5.117,5.117,5.117,5.117,5.117,5.117,5.117,5.117,5.117,5.117
# 8.76,9.16,9.827,10.093,10.36,10.76,10.493,10.227,10.093,9.827,9.16,8.76
# 0.52,0.52,0.867,2.107,4.507,6.773,7.173,6.507,5.04,2.173,0.867,0.52
# 4.64,4.84,5.347,6.1,7.4335,8.7665,8.833,8.367,7.5665,6,5.0135,4.64
# 5.276088,5.528588,6.006132,6.4425972,7.2448806,8.3639474,8.540044,8.126544,7.2533006,6.3291908,5.6258086,5.300508
# 2.3331824,2.4821116,2.7266101,3.0330155,3.8849492,5.5212224,6.2395131,5.7733017,4.1556703,3.1274641,2.6180116,2.4039116
# 0.580555,0.6290065,0.628558,0.628546,0.919255,1.7685454,2.5506969,2.5535975,1.7286418,0.9703975,0.726358,0.6290065
# 0.3999679,0.4043968,0.3138257,0.2232945,0.2498679,0.3300675,0.4323964,0.7999234,1.1668827,0.7977234,0.5038257,0.4043968
# 0.782,0.893,1.004,1.116,1.782,3.671,4.782,4.227,2.004,1.227,1.004,0.893
# 0.782,0.893,1.004,1.116,1.782,3.671,4.782,4.227,2.004,1.227,1.004,0.893
# 0.001,0.001,0.001,0.001,0.001,0.001,0.001,0.001,0.001,0.001,0.001,0.001
# 1.2867143,1.3945997,1.5506977,1.7727263,2.5190228,4.1367678,5.0212291,4.5795799,2.8484358,1.8856229,1.5178736,1.3656797
# LAI	END
################################################################################
# Roughness Length
# rows: code 1-13
# cols: month Jan-Dec
# RL	START
# 1.112,1.103,1.088,1.082,1.076,1.068,1.073,1.079,1.082,1.088,1.103,1.112
# 2.653,2.653,2.653,2.653,2.653,2.653,2.653,2.653,2.653,2.653,2.653,2.653
# 1.112,1.103,1.088,1.082,1.076,1.068,1.073,1.079,1.082,1.088,1.103,1.112
# 0.52,0.52,0.666,0.91,1.031,1.044,1.042,1.037,1.036,0.917,0.666,0.52
# 0.816,0.8115,0.877,0.996,1.0535,1.056,1.0575,1.058,1.059,1.0025,0.8845,0.816
# 0.7602524,0.7551426,0.7772204,0.8250124,0.846955,0.8449668,0.8471342,0.8496604,0.8514252,0.8299022,0.7857734,0.7602744
# 0.35090494,0.34920916,0.36891486,0.40567288,0.42336056,0.42338372,0.42328378,0.42485112,0.42631836,0.40881268,0.37218526,0.35096866
# 0.05641527,0.05645892,0.05557872,0.05430207,0.05425842,0.05399002,0.05361482,0.0572041,0.05892068,0.05821407,0.05709462,0.05645892
# 0.03699235,0.03699634,0.03528634,0.03272533,0.03272134,0.03270066,0.03268178,0.03907616,0.04149324,0.04032533,0.03823134,0.03699634
# 0.0777,0.0778,0.0778,0.0779,0.0778,0.0771,0.0759,0.0766,0.0778,0.0779,0.0778,0.0778
# 0.0777,0.0778,0.0778,0.0779,0.0778,0.0771,0.0759,0.0766,0.0778,0.0779,0.0778,0.0778
# 0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112,0.0112
# 0.1947138,0.19413424,0.20831414,0.23348558,0.24574614,0.24605016,0.24538258,0.24630454,0.247455,0.23527388,0.20963734,0.19478494
# RL	END
################################################################################
# Melt Factor, assumed there is no snow in the target area, so MF is set to 0
# MF	START
# MF	1	2
# 0 0.0
# 365 0.0
# MF	END
################################################################################
