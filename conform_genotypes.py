#!/usr/bin/env python2
# -*- coding: utf-8 -*-
"""
Created on Tue Oct 22 13:00:27 2019

@author: bs11
"""

import os
import argparse


parser = argparse.ArgumentParser(description = "conform genotypes", formatter_class=argparse.ArgumentDefaultsHelpFormatter)
parser.add_argument("--prefix", help = "prefix of VCF file")
args = parser.parse_args()

#prefix of VCF file
prefix = args.prefix

for i in range (1, 23):
    chromosome = 'chr' + str(i)
    sample = prefix + '_' + chromosome + '.vcf'
    out = prefix + '_' + chromosome + '_Setted'
    conformGT = '/software/jdk1.8.0_60/bin/java -Xms6000m -Xmx6000m -jar ~/Codes/conform-gt.24May16.cee.jar ref=/lustre/scratch117/cellgen/teamtrynka/lara/Temp_Resources/BLUEPRINT_Beagle_Ref/UK10K_maf0.0001_%s.vcf gt=%s chrom=%s match=POS strict=true out=%s' % (chromosome, sample, str(i), out)
    print conformGT
    os.system(conformGT)
    tabix = 'tabix -f -p vcf %s' % (out)
    print tabix
    os.system(tabix)
