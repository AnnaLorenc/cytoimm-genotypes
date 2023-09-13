#!/bin/bash
echo "########################################################"
echo "#             ceberPCA v1.11 64 bits                   #"
echo "#                                                      #"
echo "#                  Jule 2nd 2014                       #"
echo "#                                                      #"
echo "#  This Bash script uses the following software under  #"
echo "#      GNU Public license v2: gcta64, R-base           #"
echo "#    The following are needed for ceberPCA to work:    #"
echo "#      gcta64, sed, R, vim and the R libraries         #"
echo "#            colortools and scatterplot3d              #"
echo "#                                                      #"
echo "########################################################"
HELP="FALSE"
FILE="NULL"
PC=3
SD=6
DOTSIZE=2
ALPHA="FF"
G1000="FALSE"
SPLITCHR="FALSE"
NEWVERSION="FALSE"
while getopts ":f:p:s:d:a:SngH" optname; do
        case $optname in
	n)
	echo "USing GCTA64 version 1.24 instead of version 1.04" >&2
	NEWVERSION="TRUE"
	;;
	S)
	echo "Performing the PCA analysis on each chromosome sepparatelly" >&2
	SPLITCHR="TRUE"
	;;
	g)
	echo "Merging your data with 1000G populations for PC analysis and plotting" >&2
	G1000="TRUE"
	;;
	a)
	echo "Setting dot transparency value to $OPTARG" >&2
	ALPHA="$OPTARG"
	;;
	d)
	echo "Dot size set to $OPTARG" >&2
	DOTSIZE="$OPTARG"
	;;
        H)
        echo "Available options are:"
        HELP="TRUE"
        ;;
	f)
	echo "bed/bim/fam data set to analyze is $OPTARG" >&2
	FILE="$OPTARG"
	;;
	p)
	echo "$OPTARG principal components will be used in the analysis" >&2
	PC="$OPTARG"
	;;
	s)
	echo "Individuals that deviate more than $OPTARG standard deviations from the centroid will be considered outliers" >&2
	SD="$OPTARG"
	;;
        \?)
        echo "Invalid option: -$OPTARG" >&2
        exit 1
        ;;
        esac
done
if [ $HELP = "TRUE" ]; then
	echo "-H	(Boolean) Displays this list"
	echo "-f	(Mandatory, Argument) bed/bim/fam file set name without extensions to do the PCA calculations (Default: NULL)"
	echo "-p	(Argument) Number of principal components to calculate (Default = 3)"
	echo "-s	(Argument) Number of standard deviations from the centroid beyond which individuals are considered outliers (Default = 6)"
	echo "-a	(Argument) 2 Digit Hexadecimal value for the transparency of the dots (00 means completely transparent and FF completely opaque) (Default = FF)"
	echo "-d	(Argument) Relative size of the dots (Default = 2)"
	echo "-g	(Boolean) Merge your data with 1000G populations for PC calculations and plotting (Default = FALSE)"
	echo "-S	(Boolean) Analyze each chromosome sepparatelly in order to need less total RAM, but takes longer (Default = FALSE)"
	echo "-n	(Boolean) USe GCTA64 version 1.24 instead of 1.04, which is faster but consumes more RAM (Default = FALSE)"
	exit
fi
echo "Creating temp files"
mkdir .${FILE}_PCATempFiles_EUR_Prunned
echo "Removing all non-SNP genetic variants"
if [ $G1000 = "TRUE" ]; then
	p-link --noweb --silent --allow-no-sex --bfile /lustre/scratch117/cellgen/teamtrynka/blagoje/cytoimmgen/phase_2/genotypes/PLINK_pipeline/PCA/1000G_forPCA_withNumberCode_EUR_maf0.05_Prunned_removed --bmerge ${FILE}.bed ${FILE}.bim ${FILE}.fam --geno 0.05 --extract ${FILE}.bim --make-bed --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
else
	cp ${FILE}.bed .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.bed
	cp ${FILE}.bim .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.bim
	cp ${FILE}.fam .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.fam
fi
cp .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.bim .${FILE}_PCATempFiles_EUR_Prunned/NonSNP.txt
vim -c "%s/\S\+\s\S\+\s\S\+\s\S\+\s\S\{1}\s\S\{1}\n//e|wq" .${FILE}_PCATempFiles_EUR_Prunned/NonSNP.txt
p-link --noweb --silent --allow-no-sex --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --exclude .${FILE}_PCATempFiles_EUR_Prunned/NonSNP.txt --make-bed --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
echo "No SNPs removed"
echo "Done"
echo "Calculating vectors"
echo "Go grab a coffe, this might take a while"
CHR=1
if [ $NEWVERSION = "TRUE" ]; then
	if [ $SPLITCHR = "TRUE" ]; then
		until [ $CHR = 23 ]; do
			echo "Starting ${CHR}"
                        p-link --noweb --allow-no-sex --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --chr $CHR --make-bed --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr$CHR > /dev/null
	        	/software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr$CHR --make-grm --autosome --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR} > /dev/null
	        	if [ -e .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR}.grm.bin ]; then
	                	echo .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR} >> .${FILE}_PCATempFiles_EUR_Prunned/MergeGRM.txt
	        	fi
	        	echo "Calculating Vectors for chromosome ${CHR}"
	        	let CHR=CHR+1
		done
		/software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --mgrm .${FILE}_PCATempFiles_EUR_Prunned/MergeGRM.txt --make-grm --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
	else
		/software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --make-grm --autosome --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
	fi
	echo "Done"
	echo "Calculating principal components"
	/software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --grm .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --pca ${PC} --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
	echo "Done"
else
        if [ $SPLITCHR = "TRUE" ]; then
                until [ $CHR = 23 ]; do
			p-link --noweb --allow-no-sex --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --chr $CHR --make-bed --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr$CHR > /dev/null
                        /software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr$CHR --make-grm --autosome --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR} > /dev/null
                        if [ -e .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR}.grm.bin ]; then
                                echo .${FILE}_PCATempFiles_EUR_Prunned/${FILE}_Chr${CHR} >> .${FILE}_PCATempFiles_EUR_Prunned/MergeGRM.txt
                        fi
                        echo "Calculating Vectors for chromosome ${CHR}"
                        let CHR=CHR+1
                done
		/software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --mgrm .${FILE}_PCATempFiles_EUR_Prunned/MergeGRM.txt --make-grm --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
        else
                /software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --bfile .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --make-grm --autosome --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
        fi
        echo "Done"
        echo "Calculating principal components"
        /software/hgi/pkglocal/blackbox/gcta-1.24.4/bin/gcta64 --grm .${FILE}_PCATempFiles_EUR_Prunned/${FILE} --pca ${PC} --out .${FILE}_PCATempFiles_EUR_Prunned/${FILE} > /dev/null
        echo "Done"
fi
cut -d " " -f 2,6 .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.fam > .${FILE}_PCATempFiles_EUR_Prunned/Status.txt
cp /nfs/users/nfs_l/lbc/Codes/MyCodes/Granada/PCA/PCAheader.txt .${FILE}_PCATempFiles_EUR_Prunned/
i=1
let PC2=PC+1
until [ $i = $PC2 ]; do
	vim .${FILE}_PCATempFiles_EUR_Prunned/PCAheader.txt -c "1s/\(.\+\)/\1 PC$i/e|wq"
	let i=i+1
done
join -1 1 -2 2 .${FILE}_PCATempFiles_EUR_Prunned/Status.txt .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.eigenvec > .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.eigenvec2
vim .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.eigenvec2 -c "%s/\(\S\+\)\s\(\S\+\)\s\(\S\+\)\s\(.\+\)/\3 \1 \2 \4/e|wq"
cat .${FILE}_PCATempFiles_EUR_Prunned/PCAheader.txt .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.eigenvec2 > .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.Plot
echo "Calculating PC outliers and plotting"
/software/bin/Rscript /nfs/users/nfs_l/lbc/Codes/MyCodes/Granada/PCA/PCA_1000G.R .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.Plot $SD $DOTSIZE $ALPHA
echo "Done"
mv PCmatrix.png ${FILE}_PCmatrix_EUR_Prunned.png
mv PC1vsPC2.png ${FILE}_PC1vsPC2_EUR_Prunned.png
mv PC1vsPC3.png ${FILE}_PC1vsPC3_EUR_Prunned.png
mv PC2vsPC3.png ${FILE}_PC2vsPC3_EUR_Prunned.png
mv PC1vsPC2_CaseControl.png ${FILE}_PC1vsPC2_CaseControl_EUR_Prunned.png
mv PC1vsPC3_CaseControl.png ${FILE}_PC1vsPC3_CaseControl_EUR_Prunned.png
mv PC2vsPC3_CaseControl.png ${FILE}_PC2vsPC3_CaseControl_EUR_Prunned.png
mv PC3D.png ${FILE}_PC3D_EUR_Prunned.png
vim Outliers.txt -c "%s/\"//ge|wq"
vim Outliers.txt -c "%s/NA.\+\n//ge|wq"
OUTLIERSLINES=`wc -l Outliers.txt | cut -d " " -f 1`
if [ $OUTLIERSLINES -eq 2 ]; then
	vim Outliers.txt -c "2s/\S\+\s//e|wq"
fi
if [ $OUTLIERSLINES -gt 2 ]; then
        vim Outliers.txt -c "2,\$s/\S\+\s//e|wq"
fi
vim Outliers.txt -c "%s/\(\S\+\s\S\+\)\s\S\+\s\(.\+\)/\1 \2/e|wq"
mv Outliers.txt ${FILE}.Outliers
cp .${FILE}_PCATempFiles_EUR_Prunned/${FILE}.Plot ${FILE}_EUR_Prunned.PCA
vim ${FILE}_EUR_Prunned.PCA -c "%s/\(\S\+\s\S\+\)\s\S\+\s\(.\+\)/\1 \2/e|wq"
#echo "Deleting temp files"
#rm -r .${FILE}_PCATempFiles_EUR_Prunned/
echo "Done"
echo "All done"
echo "Have a nice day!"
