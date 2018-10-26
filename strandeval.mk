#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	 $HOME/Oyster_River/Protocol/strandeval.mk main \
#  ASSEMBLY=test.fasta \
#  READ1=1.subsamp_1.cor.fq \
#  READ2=1.subsamp_2.cor.fq \
#  RUNOUT=test
#

VERSION = 2.1.0
MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CPU=24
READ1=
READ2=
RUNOUT =
ASSEMBLY=
bwapath := $(shell which bwa 2>/dev/null)
seqtkpath := $(shell which seqtk 2>/dev/null)



main: setup check welcome strandeval
clean:
setup:${DIR}/setup.done
strandeval:{DIR}/reports/${RUNOUT}.strandeval.done

.DELETE_ON_ERROR:
.PHONY:report check clean

${DIR}/setup.done:
	@mkdir -p ${DIR}/reports
	touch ${DIR}/setup.done

check:
ifdef bwapath
else
	$(error "\n\n*** BWA is not installed, must fix ***")
endif
ifdef seqtkpath
else
	$(error "\n\n*** SEQTK is not installed, must fix ***")
endif


welcome:
	printf "\n\n*****  Welcome to the Oyster River Stand Evaluation Tool ***** \n"
	printf "*****  This is version ${VERSION} *****\n"
	printf "*****  This is adapted from https://github.com/trinityrnaseq/trinityrnaseq/wiki/Examine-Strand-Specificity ***** \n\n"
	printf " \n\n"


{DIR}/reports/${RUNOUT}.strandeval.done:
	bwa index -p ${RUNOUT} ${ASSEMBLY}
	bwa mem -t $(CPU) ${RUNOUT} \
	<(seqtk sample -s 23894 ${READ1} 200000) \
	<(seqtk sample -s 23894 ${READ2} 200000) \
	| samtools view -@10 -Sb - \
	| samtools sort -T ${RUNOUT} -O bam -@10 -o "${RUNOUT}".sorted.bam -
	$$(dirname $$(readlink -f $$(which Trinity)))/util/misc/examine_strand_specificity.pl "${RUNOUT}".sorted.bam ${RUNOUT}
	hist  -p '#' -c red <(cat ${RUNOUT}.dat | awk '{print $$5}' | sed  1d)
	touch ${DIR}/reports/${RUNOUT}.strandeval.done
	printf "\n\n*****  See the following link for interpretation ***** \n"
	printf "*****  LINK ***** \n\n"
