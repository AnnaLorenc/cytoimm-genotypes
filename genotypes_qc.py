"""
Created on Fri Oct 11 11:15:28 2019

@author: bs11
"""

import os
import argparse


parser = argparse.ArgumentParser(description = "genotype processing pipeline", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("--prefix", help = "prefix of ped file")
args = parser.parse_args()

#load plink
loadPlink = 'module load hgi/plink/1.90b4'
print loadPlink
os.system(loadPlink)

#prefix of ped file
prefix = args.prefix

#Remove samples with <5% of present genotypes
removeDonors = 'plink --file %s --make-bed --mind 0.05 --out %s' % (prefix, prefix+'_f1')
print removeDonors
os.system(removeDonors)

#Remove variants with <5% call rate
callRateRemoval = 'plink --bfile %s --geno 0.05 --make-bed --out %s' % (prefix+'_f1', prefix+'_f2')
print callRateRemoval
os.system(callRateRemoval)

#Remove variants with maf <5%
mafRemoval = 'plink --bfile %s --maf 0.05 --make-bed --out %s' % (prefix+'_f2', prefix+'_f3')
print mafRemoval
os.system(mafRemoval)

#Remove variants that do not pass HW test
hwRemoval = 'plink --bfile %s --hwe 0.001 --make-bed --out %s' % (prefix+'_f3', prefix+'_f4')
print hwRemoval
os.system(hwRemoval)

#find duplicated variants
findDupVariants = 'plink --bfile %s --list-duplicate-vars suppress-first --make-bed --out %s' % (prefix+'_f4', prefix+'_f4_deduped')
print findDupVariants
os.system(findDupVariants)

#remove duplicated variants
excludeDupVariants = 'plink --bfile %s --exclude %s --make-bed --out %s' % (prefix+'_f4', prefix+'_f4_deduped.dupvar', prefix+'_f5')
print excludeDupVariants
os.system(excludeDupVariants)

#remove indels
removeIndels = 'plink --bfile %s --snps-only no-DI --make-bed --out %s' % (prefix+'_f5', prefix+'_f6')
print removeIndels
os.system(removeIndels)

#Find related individuals
findRelatedness = 'plink --bfile %s --genome --min 0.1 --make-bed --out %s' % (prefix+'_f6', prefix+'_f7')
print findRelatedness
os.system(findRelatedness)

#Sex check
sexCheck = 'plink --bfile %s --genome --check-sex --out %s' % (prefix+'_f7', prefix+'_f8')
print sexCheck
os.system(sexCheck)

makeChromDir = 'mkdir split_per_chromosome'
os.system(makeChromDir)

for chrom in range (1, 23):
    splitPerChrom = 'plink --bfile %s --chr %s --make-bed --out %s' % (prefix+'_f6', str(chrom), prefix+'_f6_chr'+str(chrom))
    print splitPerChrom
    os.system(splitPerChrom)
    vcf = 'plink --bfile %s --recode vcf --out %s' % (prefix+'_f6_chr'+str(chrom), prefix+'_f6_chr'+str(chrom))
    os.system(vcf)

move  = 'mv *_chr* ./split_per_chromosome'
os.system(move)
