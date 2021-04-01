#!/bin/bash

# fixing the limitation of soil and geology generation in PIHMgis found here (lines 26, 153):
# https://github.com/gopal-bhatt/PIHMgis/blob/PIHMgis_v3.0/0LibsOther/pedo_transfer_functions.cpp

# usage: ./me_soil_geol.sh.txt

mukey="mukey.txt";
echo $((`wc -l < $mukey`-1)) | tee $mukey.soil $mukey.geol >/dev/null 2>/dev/null;
Rscript --vanilla <(awk '/\tRSCRIPT START SOIL/,/\tRSCRIPT END SOIL/' $0) "`realpath $mukey`" >> $mukey.soil;
Rscript --vanilla <(awk '/\tRSCRIPT START GEOL/,/\tRSCRIPT END GEOL/' $0) "`realpath $mukey`" >> $mukey.geol;
# sed -i -e 's/NaN/nan/g' -e 's/Inf/inf/g' -e '/NULL[[:space:]]*$/d' $mukey.{soil,geol}
# sed -i -e 's/nan/0/ig' -e 's/inf/0/ig' -e '/NULL[[:space:]]*$/d' $mukey.{soil,geol}
exit;

################################################################################
# SOIL
################################################################################
#	RSCRIPT START SOIL
options(warn=-1);
m <- read.csv(commandArgs(TRUE)[1], header = TRUE, sep=' ');
#34 TextureFileTextStream >> TextureData[NumClasses][1]; //SILT
S <- if(m[,2]<=0)0.001 else m[,2];
#35 TextureFileTextStream >> TextureData[NumClasses][2]; //CLAY
C <- if(m[,2]<=0)0.0748 else m[,3];
#36 TextureFileTextStream >> TextureData[NumClasses][3]; if(TextureData[NumClasses][3]<0) TextureData[NumClasses][3]=2.5; //ORGANIC MATTER
O <- if(m[,4]<=0)2.5 else m[,4];
#37 TextureFileTextStream >> TextureData[NumClasses][4]; if(TextureData[NumClasses][4]<0) TextureData[NumClasses][4]=1.3; //BULK DENSITY (g/cm3)
D <- if(m[,5]<=0)1.3 else m[,5];
#39 TextureData[NumClasses][5] = 1;
TopSoil <- 1;

# ** KsatV
#76 HydraulicParameter[i][1]=exp(7.755+0.03252*S+0.93*TopSoil-0.967*D*D-0.000484*C*C-0.000322*S*S+0.001/S-0.0748/OM-0.643*log(S)-0.01398*D*C-0.1673*D*OM+0.02986*TopSoil*C-0.03305*TopSoil*S);
#77 HydraulicParameter[i][1]=HydraulicParameter[i][1]/100; //UNIT CONVERSION cm/d to m/day
HydraulicParameter_1 <- exp(7.755+0.03252*S+0.93*TopSoil-0.967*D*D-0.000484*C*C-0.000322*S*S+0.001/S-0.0748/O-0.643*log(S)-0.01398*D*C-0.1673*D*O+0.02986*TopSoil*C-0.03305*TopSoil*S)/100;

# ** ThetaS
#85 HydraulicParameter[i][2]=  (0.7919+0.001691*C-0.29619*D-0.000001491*S*S+0.0000821*OM*OM+0.02427/C+0.01113/S+0.01472*log(S)-0.0000733*OM*C-0.000619*D*C-0.001183*D*OM-0.0001664*TopSoil*S);
HydraulicParameter_2 <- (0.7919+0.001691*C-0.29619*D-0.000001491*S*S+0.0000821*O*O+0.02427/C+0.01113/S+0.01472*log(S)-0.0000733*O*C-0.000619*D*C-0.001183*D*O-0.0001664*TopSoil*S);

# ** ThetaR
#91 HydraulicParameter[i][3]=0.01;
HydraulicParameter_3 <- 0.01;

# ** InfD
#97 HydraulicParameter[i][4]=0.10;
HydraulicParameter_4 <- 0.10;

# ** ALPHA
#104 HydraulicParameter[i][5]=  exp(-14.96+0.03135*C+0.0351*S+0.646*OM+15.29*D-0.192*TopSoil-4.671*D*D-0.000781*C*C-0.00687*OM*OM+0.0449/OM+0.0663*log(S)+0.1482*log(OM)-0.04546*D*S-0.4852*D*OM+0.00673*TopSoil*C);
HydraulicParameter_5 <- exp(-14.96+0.03135*C+0.0351*S+0.646*O+15.29*D-0.192*TopSoil-4.671*D*D-0.000781*C*C-0.00687*O*O+0.0449/O+0.0663*log(S)+0.1482*log(O)-0.04546*D*S-0.4852*D*O+0.00673*TopSoil*C)*100;

# ** BETA
#111 HydraulicParameter[i][6]=1+exp(-25.23-0.02195*C+0.0074*S-0.1940*OM+45.5*D-7.24*D*D+0.0003658*C*C+0.002885*OM*OM-12.81/D-0.1524/S-0.01958/OM-0.2876*log(S)-0.0709*log(OM)-44.6*log(D)-0.02264*D*C+0.0896*D*OM+0.00718*TopSoil*C);
HydraulicParameter_6 <- 1+exp(-25.23-0.02195*C+0.0074*S-0.1940*O+45.5*D-7.24*D*D+0.0003658*C*C+0.002885*O*O-12.81/D-0.1524/S-0.01958/O-0.2876*log(S)-0.0709*log(O)-44.6*log(D)-0.02264*D*C+0.0896*D*O+0.00718*TopSoil*C);

# ** hAreaF
#117 HydraulicParameter[i][7]=0.01;
HydraulicParameter_7 <- 0.01;

# ** macKsatV
#123 HydraulicParameter[i][8]=100*HydraulicParameter[i][1];
HydraulicParameter_8 <- 100*HydraulicParameter_1;

# remove NaN and Inf values
HydraulicParameter_1[is.na(HydraulicParameter_1) | is.infinite(HydraulicParameter_1) | HydraulicParameter_1<=0] <- min(HydraulicParameter_1, na.rm = TRUE);
HydraulicParameter_2[is.na(HydraulicParameter_2) | is.infinite(HydraulicParameter_2) | HydraulicParameter_2<=0] <- min(HydraulicParameter_2, na.rm = TRUE);
HydraulicParameter_3[is.na(HydraulicParameter_3) | is.infinite(HydraulicParameter_3) | HydraulicParameter_3<=0] <- min(HydraulicParameter_3, na.rm = TRUE);
HydraulicParameter_4[is.na(HydraulicParameter_4) | is.infinite(HydraulicParameter_4) | HydraulicParameter_4<=0] <- min(HydraulicParameter_4, na.rm = TRUE);
HydraulicParameter_5[is.na(HydraulicParameter_5) | is.infinite(HydraulicParameter_5) | HydraulicParameter_5<=0] <- min(HydraulicParameter_5, na.rm = TRUE);
HydraulicParameter_6[is.na(HydraulicParameter_6) | is.infinite(HydraulicParameter_6) | HydraulicParameter_6<=0] <- min(HydraulicParameter_6, na.rm = TRUE);
HydraulicParameter_7[is.na(HydraulicParameter_7) | is.infinite(HydraulicParameter_7) | HydraulicParameter_7<=0] <- min(HydraulicParameter_7, na.rm = TRUE);
HydraulicParameter_8[is.na(HydraulicParameter_8) | is.infinite(HydraulicParameter_8) | HydraulicParameter_8<=0] <- min(HydraulicParameter_8, na.rm = TRUE);

cat(sprintf("%s\t%.8f\t%.8f\t%.2f\t%.2f\t%.5f\t%.5f\t%.2f\t%.4f\n",rownames(m),HydraulicParameter_1,HydraulicParameter_2,HydraulicParameter_3,HydraulicParameter_4,HydraulicParameter_5,HydraulicParameter_6,HydraulicParameter_7,HydraulicParameter_8),sep='');
#	RSCRIPT END SOIL
################################################################################


################################################################################
# GEOL
################################################################################
#	RSCRIPT START GEOL
options(warn=-1);
m <- read.csv(commandArgs(TRUE)[1], header = TRUE, sep=' ');
#161 TextureFileTextStream >> TextureData[NumClasses][1]; //SILT
S <- if(m[,2]<=0)0.001 else m[,2];
#162 TextureFileTextStream >> TextureData[NumClasses][2]; //CLAY
C <- if(m[,2]<=0)0.0748 else m[,3];
#163 TextureFileTextStream >> TextureData[NumClasses][3]; if(TextureData[NumClasses][3]<0) TextureData[NumClasses][3]=2.5; //ORGANIC MATTER
O <- if(m[,4]<=0)2.5 else m[,4];
#164 TextureFileTextStream >> TextureData[NumClasses][4]; if(TextureData[NumClasses][4]<0) TextureData[NumClasses][4]=1.3; //BULK DENSITY (g/cm3)
D <- if(m[,5]<=0)1.3 else m[,5];
#166 TextureData[NumClasses][5] = 0;
TopSoil <- 0;

# ** KsatV
#203 HydraulicParameter[i][1]=exp(7.755+0.03252*S+0.93*TopSoil-0.967*D*D-0.000484*C*C-0.000322*S*S+0.001/S-0.0748/OM-0.643*log(S)-0.01398*D*C-0.1673*D*OM+0.02986*TopSoil*C-0.03305*TopSoil*S);
#204 HydraulicParameter[i][1]=HydraulicParameter[i][1]/100; //UNIT CONVERSION cm/d to m/day
#207 DataFileTextStream << 10.0 * HydraulicParameter[i][1] << "\t";
# HydraulicParameter_1*10
HydraulicParameter_1 <- exp(7.755+0.03252*S+0.93*TopSoil-0.967*D*D-0.000484*C*C-0.000322*S*S+0.001/S-0.0748/O-0.643*log(S)-0.01398*D*C-0.1673*D*O+0.02986*TopSoil*C-0.03305*TopSoil*S)/100;

# ** ThetaS
#212 HydraulicParameter[i][2]=  (0.7919+0.001691*C-0.29619*D-0.000001491*S*S+0.0000821*OM*OM+0.02427/C+0.01113/S+0.01472*log(S)-0.0000733*OM*C-0.000619*D*C-0.001183*D*OM-0.0001664*TopSoil*S);
HydraulicParameter_2 <- (0.7919+0.001691*C-0.29619*D-0.000001491*S*S+0.0000821*O*O+0.02427/C+0.01113/S+0.01472*log(S)-0.0000733*O*C-0.000619*D*C-0.001183*D*O-0.0001664*TopSoil*S);

# ** ThetaR
#218 HydraulicParameter[i][3]=0.01;
HydraulicParameter_3 <- 0.01;

# ** InfD
#224 //HydraulicParameter[i][4]=0.10;
# HydraulicParameter_4 <- 0.10;

# ** ALPHA
#231 HydraulicParameter[i][5]=  exp(-14.96+0.03135*C+0.0351*S+0.646*OM+15.29*D-0.192*TopSoil-4.671*D*D-0.000781*C*C-0.00687*OM*OM+0.0449/OM+0.0663*log(S)+0.1482*log(OM)-0.04546*D*S-0.4852*D*OM+0.00673*TopSoil*C);
HydraulicParameter_5 <- exp(-14.96+0.03135*C+0.0351*S+0.646*O+15.29*D-0.192*TopSoil-4.671*D*D-0.000781*C*C-0.00687*O*O+0.0449/O+0.0663*log(S)+0.1482*log(O)-0.04546*D*S-0.4852*D*O+0.00673*TopSoil*C)*100;

# ** BETA
#238 HydraulicParameter[i][6]=1+exp(-25.23-0.02195*C+0.0074*S-0.1940*OM+45.5*D-7.24*D*D+0.0003658*C*C+0.002885*OM*OM-12.81/D-0.1524/S-0.01958/OM-0.2876*log(S)-0.0709*log(OM)-44.6*log(D)-0.02264*D*C+0.0896*D*OM+0.00718*TopSoil*C);
HydraulicParameter_6 <- 1+exp(-25.23-0.02195*C+0.0074*S-0.1940*O+45.5*D-7.24*D*D+0.0003658*C*C+0.002885*O*O-12.81/D-0.1524/S-0.01958/O-0.2876*log(S)-0.0709*log(O)-44.6*log(D)-0.02264*D*C+0.0896*D*O+0.00718*TopSoil*C);

# ** hAreaF
#244 HydraulicParameter[i][7]=0.01;
HydraulicParameter_7 <- 0.01;

# ** macKsatV
#250 HydraulicParameter[i][8]=100000*HydraulicParameter[i][1];
HydraulicParameter_8 <- 100000*HydraulicParameter_1;

# ** macD
#256 HydraulicParameter[i][9]=1.0;
HydraulicParameter_9 <- 1.0;

# remove NaN and Inf values
HydraulicParameter_1[is.na(HydraulicParameter_1) | is.infinite(HydraulicParameter_1) | HydraulicParameter_1<=0] <- min(HydraulicParameter_1, na.rm = TRUE);
HydraulicParameter_2[is.na(HydraulicParameter_2) | is.infinite(HydraulicParameter_2) | HydraulicParameter_2<=0] <- min(HydraulicParameter_2, na.rm = TRUE);
HydraulicParameter_3[is.na(HydraulicParameter_3) | is.infinite(HydraulicParameter_3) | HydraulicParameter_3<=0] <- min(HydraulicParameter_3, na.rm = TRUE);
# HydraulicParameter_4[is.na(HydraulicParameter_4) | is.infinite(HydraulicParameter_4) | HydraulicParameter_4<=0] <- min(HydraulicParameter_4, na.rm = TRUE);
HydraulicParameter_5[is.na(HydraulicParameter_5) | is.infinite(HydraulicParameter_5) | HydraulicParameter_5<=0] <- min(HydraulicParameter_5, na.rm = TRUE);
HydraulicParameter_6[is.na(HydraulicParameter_6) | is.infinite(HydraulicParameter_6) | HydraulicParameter_6<=0] <- min(HydraulicParameter_6, na.rm = TRUE);
HydraulicParameter_7[is.na(HydraulicParameter_7) | is.infinite(HydraulicParameter_7) | HydraulicParameter_7<=0] <- min(HydraulicParameter_7, na.rm = TRUE);
HydraulicParameter_8[is.na(HydraulicParameter_8) | is.infinite(HydraulicParameter_8) | HydraulicParameter_8<=0] <- min(HydraulicParameter_8, na.rm = TRUE);
HydraulicParameter_9[is.na(HydraulicParameter_9) | is.infinite(HydraulicParameter_9) | HydraulicParameter_9<=0] <- min(HydraulicParameter_9, na.rm = TRUE);


cat(sprintf("%s\t%.8f\t%.8f\t%.8f\t%.2f\t%.5f\t%.5f\t%.2f\t%.4f\t%.2f\n",rownames(m),HydraulicParameter_1*10,HydraulicParameter_1,HydraulicParameter_2,HydraulicParameter_3,HydraulicParameter_5,HydraulicParameter_6,HydraulicParameter_7,HydraulicParameter_8,HydraulicParameter_9),sep='');
#	RSCRIPT END GEOL
################################################################################
