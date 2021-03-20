
#238.3741.210306.004638 mr@mr ~/tamuk/phd/pihm/2021/soil_mukey $ 
mkdir -p mukey && for f in TX*;do for s in $f/*shp;do ogr2ogr -f csv mukey/$f $s && mv mukey/${s/shp/csv} mukey/$(echo $s|sed 's/\//_/g'|sed 's/shp/txt/') && \rm -fr mukey/$f;done;done

#279.3778.210306.010738 mr@mr ~/tamuk/phd/pihm/2021/soil_mukey $ 
for p in silt clay om bd;do cat mukey/*$p*|awk -F, '{gsub(/"/,"");print $(NF-2),$1,$NF}'|awk '$1~/[0-9]/'|sort -nk1>mukey/$p.txt;done

#308.3805.210306.012219 mr@mr ~/tamuk/phd/pihm/2021/soil_mukey $ 
pr -mts mukey/silt.txt mukey/clay.txt mukey/om.txt mukey/bd.txt|awk '{printf "%s\t%.4f\t%.4f\t%.4f\t%.4f\t%s\n",$1,$3,$6,$9,$12,$2}'|sort -nk1|uniq|sed '1iMUKEY,SILT,CLAY,OM,BD,AREA'|sed 's/,/\t/g' > areas_mukey.txt

