#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	oyster.mk READ1= READ2= MEM=110 CPU=24 RUNOUT=runname STRAND=RF
#

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CPU=16
BUSCO_THREADS=${CPU}
MEM=110
TRINITY_KMER=25
SPADES1_KMER=55
SPADES2_KMER=75
TRANSABYSS_KMER=32
RCORR := ${shell which rcorrector}
RCORRDIR := $(dir $(firstword $(RCORR)))
READ1=
READ2=
BUSCO := ${shell which busco}
BUSCODIR := $(dir $(firstword $(BUSCO)))
RUNOUT=USER_RUN
LINEAGE=eukaryota_odb10
BUSCODB := ${MAKEDIR}/busco_dbs
START=1
STRAND :=
TPM_FILT = 0
BUSCO_CONFIG_FILE := ${MAKEDIR}/software/config.ini
export BUSCO_CONFIG_FILE
VERSION := ${shell cat  ${MAKEDIR}/version.txt}
LOWEXPFILE=${DIR}/assemblies/working/${RUNOUT}.LOWEXP.txt
RED:=$(shell tput setaf 1)
reset:=$(shell tput sgr0)

.DEFAULT_GOAL := main

help:
main: setup check welcome readcheck run_trimmomatic run_rcorrector run_trinity run_spades75 run_spades55 run_transabyss run_filtershort run_orthofuser merge makelist \
	makegroups orthotransrate makeorthout make_goodlist orthofusing diamond diamond_uniq make_list1 make_list2 make_list3 make_list5 make_list6 make_list7 posthack cdhit orp_diamond orp_uniq salmon_index salmon filter \
	secondfilter busco transrate strandeval report
preprocess:setup check welcome readcheck run_trimmomatic run_rcorrector
update_merge:setup check welcome readcheck run_filtershort run_orthofuser merge makelist makegroups orthotransrate makeorthout make_goodlist orthofusing diamond diamond_uniq \
	make_list1 make_list2 make_list3 make_list5 make_list6 make_list7 posthack cdhit orp_diamond orp_uniq salmon_index salmon filter busco transrate strandeval report
run_trimmomatic:${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq
run_rcorrector:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
run_trinity:${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
run_spades55:${DIR}/assemblies/${RUNOUT}.spades55.fasta
run_spades75:${DIR}/assemblies/${RUNOUT}.spades75.fasta
run_transabyss:${DIR}/assemblies/${RUNOUT}.transabyss.fasta
run_filtershort:${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades55.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades75.fasta.short.fasta \
	${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.transabyss.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.trinity.Trinity.fasta.short.fasta
run_orthofuser:${DIR}/orthofuse/${RUNOUT}/orthofuser.done
merge:${DIR}/orthofuse/${RUNOUT}/merged.fasta
orthotransrate:${DIR}/orthofuse/${RUNOUT}/merged/assemblies.csv
makeorthout:${DIR}/orthofuse/${RUNOUT}/orthout.done
make_goodlist:${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list
orthofusing:${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
salmon:${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf
diamond:${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt
diamond_uniq:${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt
posthack:${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta
orthofuse:merge orthotransrate orthofusing
report:busco transrate reportgen
busco:${DIR}/reports/${RUNOUT}.busco.done
transrate:${DIR}/reports/transrate_${RUNOUT}/assemblies.csv
reportgen:${DIR}/reports/qualreport.${RUNOUT}.done
clean:
setup:${DIR}/assemblies/working ${DIR}/reads ${DIR}/rcorr ${DIR}/assemblies/diamond ${DIR}/assemblies ${DIR}/reports ${DIR}/orthofuse ${DIR}/quants ${DIR}/assemblies/working
strandeval:${DIR}/reports/${RUNOUT}.strandeval.done
filter:${DIR}/assemblies/${RUNOUT}.filter.done
secondfilter:${DIR}/assemblies/${RUNOUT}.ORP.fasta
makelist:${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list
makegroups:${DIR}/orthofuse/${RUNOUT}/groups.done
make_list1:${DIR}/assemblies/diamond/${RUNOUT}.list1
make_list2:${DIR}/assemblies/diamond/${RUNOUT}.list2
make_list3:${DIR}/assemblies/diamond/${RUNOUT}.list3
make_list5:${DIR}/assemblies/diamond/${RUNOUT}.list5
make_list6:${DIR}/assemblies/diamond/${RUNOUT}.list6
make_list7:${DIR}/assemblies/diamond/${RUNOUT}.list7
cdhit:${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta
orp_diamond:${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
orp_uniq:${DIR}/assemblies/working/${RUNOUT}.unique.ORP.done
salmon_index:${DIR}/quants/${RUNOUT}.ortho.idx

.DELETE_ON_ERROR:
.PHONY:reportgen check clean

${DIR}/assemblies/working ${DIR}/reads ${DIR}/rcorr ${DIR}/assemblies/diamond ${DIR}/assemblies ${DIR}/reports ${DIR}/orthofuse ${DIR}/quants:
	@mkdir -p ${DIR}/reads
	@mkdir -p ${DIR}/assemblies
	@mkdir -p ${DIR}/rcorr
	@mkdir -p ${DIR}/reports
	@mkdir -p ${DIR}/orthofuse
	@mkdir -p ${DIR}/quants
	@mkdir -p ${DIR}/assemblies/diamond
	@mkdir -p ${DIR}/assemblies/working

check:
ifeq ($(shell basename $$(source activate orp_salmon; which salmon)),salmon)
$(info SALMON installed)
else
$(error *** SALMON is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp; which transrate)),transrate)
else
$(info TRANSRATE installed)
$(error *** TRANSRATE is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp; which seqtk)),seqtk)
else
$(info SEQTK installed)
$(error *** SEQTK is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_busco; which busco)),busco)
$(info BUSCO installed)
else
$(error *** BUSCO is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp; which mcl)),mcl)
else
$(info MCL installed)
$(error *** MCL is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_spades; which rnaspades.py)),rnaspades.py)
$(info SPADES installed)
else
$(error *** SPADES is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_trinity; which Trinity)),Trinity)
$(info TRINITY installed)
else
$(error *** TRINITY is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_trimmomatic; which trimmomatic)),trimmomatic)
$(info TRIMMOMATIC installed)
else
$(error *** TRIMMOMATIC is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_transabyss; which transabyss)),transabyss)
$(info TRANSABYSS installed)
else
$(error *** TRANSABYSS is not installed, must fix ***)
endif

ifeq ($(shell basename $$(source activate orp_rcorrector; which run_rcorrector.pl)),run_rcorrector.pl)
$(info RCORRECTOR installed)
else
$(error *** RCORRECTOR is not installed, must fix ***)
endif

help:
	printf "$(RED)\n\n*****  Welcome to the Oyster River Prptocol ***** \n"
	printf "*****  This is version ${VERSION} *****\n\n"
	printf "Usage:\n\n"
	printf "/path/to/Oyster_River/Protocol/oyster.mk CPU=24 \\n"
	printf "MEM=128 \\n"
	printf "STRAND=RF \\n"
	printf "READ1=1.subsamp_1.cor.fq \\n"
	printf "READ2=1.subsamp_2.cor.fq \\n"
	printf "RUNOUT=test\n\n$(reset)"

readcheck:
	if [ -e ${READ1} ]; then printf ""; else printf "\n\n\n\n ERROR: YOUR READ1 FILE DOES NOT EXIST AT THE LOCATION YOU SPECIFIED\n\n\n\n "; $$(shell exit); fi;
	if [ -e ${READ2} ]; then printf ""; else printf "\n\n\n\n ERROR: YOUR READ2 FILE DOES NOT EXIST AT THE LOCATION YOU SPECIFIED\n\n\n\n "; $$(shell exit); fi;
ifeq ($(shell file ${READ1} | awk '{print $$2}'),gzip)
	if [ $$(gzip -cd $${READ1} | head -n 400 | awk '{if(NR%4==2) {count++; bases += length} } END{print int(bases/count)}') -gt $(SPADES2_KMER) ] && [ $$(gzip -cd $${READ2} | head -n 400 | awk '{if(NR%4==2) {count++; bases += length} } END{print int(bases/count)}') -gt $(SPADES2_KMER) ];\
	then\
		printf " ";\
	else\
		printf "\n\n\n\n IT LOOKS LIKE YOUR READS ARE NOT AT LEAST $(SPADES2_KMER) BP LONG,\n ";\
		printf "PLEASE EDIT YOUR COMMAND USING THE "SPADES2_KMER=INT" FLAGS,\n";\
		printf " SETTING THE ASSEMBLY KMER LENGTH TO AN ODD NUMBER LESS THAN YOUR READ LENGTH \n\n\n\n";\
		$$(shell exit);\
	fi
else
	if [ $$(head -n400 $${READ1} | awk '{if(NR%4==2) {count++; bases += length} } END{print int(bases/count)}') -gt $(SPADES2_KMER) ] && [ $$(head -n400 $${READ2} | awk '{if(NR%4==2) {count++; bases += length} } END{print int(bases/count)}') -gt $(SPADES2_KMER) ];\
	then\
		printf " ";\
	else\
		printf "\n\n\n\n IT LOOKS LIKE YOUR READS ARE NOT AT LEAST $(SPADES2_KMER) BP LONG,\n ";\
		printf "PLEASE EDIT YOUR COMMAND USING THE "SPADES2_KMER=INT" FLAGS,\n";\
		printf " SETTING THE ASSEMBLY KMER LENGTH LESS THAN YOUR READ LENGTH \n\n\n\n";\
		$$(shell exit);\
	fi
endif

welcome:
	printf "$(RED)\n\n*****  Welcome to the Oyster River ***** \n"
	printf "*****  This is version ${VERSION} *****$(reset)\n\n"
	printf " \n\n"

${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq:${READ1} ${READ2}
	@if [ $$(hostname | cut -d. -f3-5) == 'bridges.psc.edu' ];\
	then\
		java -jar $$TRIMMOMATIC_HOME/trimmomatic-0.36.jar PE -threads $(CPU) -baseout ${DIR}/rcorr/${RUNOUT}.TRIM.fastq ${READ1} ${READ2} LEADING:3 TRAILING:3 ILLUMINACLIP:${MAKEDIR}/barcodes/barcodes.fa:2:30:10:8:TRUE MINLEN:25;\
	else\
		source activate orp_trimmomatic;\
		trimmomatic PE -threads $(CPU) -baseout ${DIR}/rcorr/${RUNOUT}.TRIM.fastq ${READ1} ${READ2} LEADING:3 TRAILING:3 ILLUMINACLIP:${MAKEDIR}/barcodes/barcodes.fa:2:30:10:8:TRUE MINLEN:25;\
	fi

${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq:${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq
	source activate orp_rcorrector;\
	run_rcorrector.pl -t $(CPU) -k 31 -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq -od ${DIR}/rcorr

${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq
ifeq ($(STRAND),RF)
		source activate orp_trinity;\
		Trinity --SS_lib_type RF --no_version_check --bypass_java_version_check --no_normalize_reads --seqType fq --output ${DIR}/assemblies/${RUNOUT}.trinity --max_memory $(MEM)G --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq --CPU $(CPU) --inchworm_cpu 10 --full_cleanup
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta > ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa && mv -f ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
		rm -f ${DIR}/assemblies/*gene_trans_map
else ifeq ($(STRAND),FR)
		source activate orp_trinity;\
		Trinity --SS_lib_type FR --no_version_check --bypass_java_version_check --no_normalize_reads --seqType fq --output ${DIR}/assemblies/${RUNOUT}.trinity --max_memory $(MEM)G --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq --CPU $(CPU) --inchworm_cpu 10 --full_cleanup
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta > ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa && mv -f ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
		rm -f ${DIR}/assemblies/*gene_trans_map
else
		source activate orp_trinity;\
		Trinity --no_version_check --bypass_java_version_check --no_normalize_reads --seqType fq --output ${DIR}/assemblies/${RUNOUT}.trinity --max_memory $(MEM)G --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq --CPU $(CPU) --inchworm_cpu 10 --full_cleanup
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta > ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa && mv -f ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fa ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
		rm -f ${DIR}/assemblies/*gene_trans_map
endif

${DIR}/assemblies/${RUNOUT}.spades55.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
ifeq ($(STRAND),RF)
		source activate orp_spades;\
		rnaspades.py --ss-rf --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k55 --threads $(CPU) --memory $(MEM) -k $(SPADES1_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k55/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k55
else ifeq ($(STRAND),FR)
		source activate orp_spades;\
		rnaspades.py --ss-fr --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k55 --threads $(CPU) --memory $(MEM) -k $(SPADES1_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k55/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k55
else
		source activate orp_spades;\
		rnaspades.py --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k55 --threads $(CPU) --memory $(MEM) -k $(SPADES1_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k55/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k55
endif

${DIR}/assemblies/${RUNOUT}.spades75.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
ifeq ($(STRAND),RF)
		source activate orp_spades;\
		rnaspades.py --ss-rf --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k75 --threads $(CPU) --memory $(MEM) -k $(SPADES2_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k75/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k75
else ifeq ($(STRAND),FR)
		source activate orp_spades;\
		rnaspades.py --ss-fr --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k75 --threads $(CPU) --memory $(MEM) -k $(SPADES2_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k75/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k75
else
		source activate orp_spades;\
		rnaspades.py --only-assembler -o ${DIR}/assemblies/${RUNOUT}.spades_k75 --threads $(CPU) --memory $(MEM) -k $(SPADES2_KMER) -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		mv ${DIR}/assemblies/${RUNOUT}.spades_k75/transcripts.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.spades_k75
endif

${DIR}/assemblies/${RUNOUT}.transabyss.fasta:${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
ifeq ($(STRAND),RF)
		source activate orp_transabyss;\
		transabyss --SS --threads $(CPU) --outdir ${DIR}/assemblies/${RUNOUT}.transabyss --kmer $(TRANSABYSS_KMER) --length 250 --name ${RUNOUT}.transabyss.fasta --pe ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa >  ${DIR}/assemblies/${RUNOUT}.transabyss.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.transabyss/ ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa
else ifeq ($(STRAND),FR)
		source activate orp_transabyss;\
		transabyss --SS --threads $(CPU) --outdir ${DIR}/assemblies/${RUNOUT}.transabyss --kmer $(TRANSABYSS_KMER) --length 250 --name ${RUNOUT}.transabyss.fasta --pe ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa >  ${DIR}/assemblies/${RUNOUT}.transabyss.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.transabyss/ ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa
else
		source activate orp_transabyss;\
		transabyss --threads $(CPU) --outdir ${DIR}/assemblies/${RUNOUT}.transabyss --kmer $(TRANSABYSS_KMER) --length 250 --name ${RUNOUT}.transabyss.fasta --pe ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
		awk '{print $$1}' ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa >  ${DIR}/assemblies/${RUNOUT}.transabyss.fasta
		rm -fr ${DIR}/assemblies/${RUNOUT}.transabyss/ ${DIR}/assemblies/${RUNOUT}.transabyss/${RUNOUT}.transabyss.fasta-final.fa
endif

${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades55.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades75.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.transabyss.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.trinity.Trinity.fasta.short.fasta:${DIR}/assemblies/${RUNOUT}.transabyss.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
	mkdir -p ${DIR}/orthofuse/${RUNOUT}/working
	source activate orp;\
	for fasta in $$(ls ${DIR}/assemblies/${RUNOUT}.transabyss.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta); do python ${MAKEDIR}/scripts/long.seq.py ${DIR}/assemblies/$$(basename $$fasta) ${DIR}/orthofuse/${RUNOUT}/working/$$(basename $$fasta).short.fasta 200; done

${DIR}/orthofuse/${RUNOUT}/orthofuser.done:${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades55.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades75.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.transabyss.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.trinity.Trinity.fasta.short.fasta
	source activate orp;\
	${MAKEDIR}/software/OrthoFinder/orthofinder -d -I 12 -f ${DIR}/orthofuse/${RUNOUT}/working/ -og -t $(CPU) -a $(CPU)
	touch ${DIR}/orthofuse/${RUNOUT}/orthofuser.done

${DIR}/orthofuse/${RUNOUT}/merged.fasta:${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades55.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades75.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.transabyss.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.trinity.Trinity.fasta.short.fasta
	cat ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades55.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.spades75.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.transabyss.fasta.short.fasta ${DIR}/orthofuse/${RUNOUT}/working/${RUNOUT}.trinity.Trinity.fasta.short.fasta > ${DIR}/orthofuse/${RUNOUT}/merged.fasta


${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list:${DIR}/orthofuse/${RUNOUT}/orthofuser.done
	export END=$$(wc -l $$(find ${DIR}/orthofuse/${RUNOUT}/working/ -name Orthogroups.txt 2> /dev/null) | awk '{print $$1}') && \
	export ORTHOINPUT=$$(find ${DIR}/orthofuse/${RUNOUT}/working/ -name Orthogroups.txt 2> /dev/null) && \
	echo $$(eval echo "{1..$$END}") | tr ' ' '\n' > ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list

${DIR}/orthofuse/${RUNOUT}/groups.done:${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list
	source activate orp;\
	export ORTHOINPUT=$$(find ${DIR}/orthofuse/${RUNOUT}/working/ -name Orthogroups.txt 2> /dev/null) && \
	cat ${DIR}/orthofuse/${RUNOUT}/${RUNOUT}.list | parallel  -j $(CPU) -k "sed -n ''{}'p' $$ORTHOINPUT | tr ' ' '\n' | sed '1d' > ${DIR}/orthofuse/${RUNOUT}/{1}.groups"
	touch ${DIR}/orthofuse/${RUNOUT}/groups.done

${DIR}/orthofuse/${RUNOUT}/merged/assemblies.csv:${DIR}/orthofuse/${RUNOUT}/merged.fasta ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	source activate orp;\
	${MAKEDIR}/software/orp-transrate/transrate -o ${DIR}/orthofuse/${RUNOUT}/merged -t $(CPU) -a ${DIR}/orthofuse/${RUNOUT}/merged.fasta --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	find ${DIR}/orthofuse/${RUNOUT}/merged -name "*bam" -delete

${DIR}/orthofuse/${RUNOUT}/orthout.done:${DIR}/orthofuse/${RUNOUT}/groups.done
	echo All the text files are made, start GREP
	source activate orp;\
	find ${DIR}/orthofuse/${RUNOUT}/ -maxdepth 1 -name '*groups' 2> /dev/null | parallel -j $(CPU) "grep -Fwf {} $$(find ${DIR}/orthofuse/${RUNOUT}/ -name contigs.csv 2> /dev/null) > {1}.orthout 2> /dev/null"
	echo About to delete all the text files
	find ${DIR}/orthofuse/${RUNOUT}/ -maxdepth 1 -name '*groups' -delete
	touch ${DIR}/orthofuse/${RUNOUT}/orthout.done

${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list:${DIR}/orthofuse/${RUNOUT}/orthout.done
	echo Search output files
	source activate orp;\
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*orthout' 2> /dev/null | parallel -j $(CPU) "awk -F, -v max=0 '{if(\$$9>max){want=\$$1; max=\$$9}}END{print want}'" >> ${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list
	find ${DIR}/orthofuse/${RUNOUT}/ -name '*orthout' -delete

${DIR}/assemblies/${RUNOUT}.orthomerged.fasta:${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list ${DIR}/orthofuse/${RUNOUT}/merged.fasta
	source activate orp;\
	python ${MAKEDIR}/scripts/filter.py ${DIR}/orthofuse/${RUNOUT}/merged.fasta ${DIR}/orthofuse/${RUNOUT}/good.${RUNOUT}.list > ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta

${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt:${DIR}/assemblies/${RUNOUT}.orthomerged.fasta ${DIR}/assemblies/${RUNOUT}.transabyss.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta
	source activate orp_diamond;\
	printf "\n\n\n\n Starting diamond \n\n\n\n";\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt;\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.transabyss.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt;\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.spades75.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt;\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.spades55.fasta -d ${MAKEDIR}/software/diamond/swissprot -o ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt;\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt

${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt:${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f1 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f1 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f1 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt
	awk '{print $$2}' ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f1 | sort | uniq | wc -l > ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt

#list1 is unique geneIDs in orthomerged
#list2 is unique  geneIDs in other assemblies
#list3 is which genes are in other assemblies but not in orthomerged
#list4 are the contig IDs from {sp55,sp75,trin,ta} from list3
#list5 is unique IDs contig IDs from list4
#list6 is contig IDs from orthomerged FASTAs
#list7 is stuff that is in 5 but not 6

${DIR}/assemblies/diamond/${RUNOUT}.list1:${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt
	source activate orp;\
	cut -f2 ${DIR}/assemblies/diamond/${RUNOUT}.orthomerged.diamond.txt | cut -d "|" -f3 | cut -d "_" -f1 | sort --parallel=20 |uniq > ${DIR}/assemblies/diamond/${RUNOUT}.list1

${DIR}/assemblies/diamond/${RUNOUT}.list2:${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt
	source activate orp;\
	cut -f2 ${DIR}/assemblies/diamond/${RUNOUT}.{transabyss,spades75,spades55,trinity}.diamond.txt | cut -d "|" -f3 | cut -d "_" -f1 | sort --parallel=20 | uniq > ${DIR}/assemblies/diamond/${RUNOUT}.list2

${DIR}/assemblies/diamond/${RUNOUT}.list3:${DIR}/assemblies/diamond/${RUNOUT}.list1 ${DIR}/assemblies/diamond/${RUNOUT}.list2
	grep -xFvwf ${DIR}/assemblies/diamond/${RUNOUT}.list1 ${DIR}/assemblies/diamond/${RUNOUT}.list2 > ${DIR}/assemblies/diamond/${RUNOUT}.list3

${DIR}/assemblies/diamond/${RUNOUT}.list5:${DIR}/assemblies/diamond/${RUNOUT}.list3 ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades75.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.spades55.diamond.txt ${DIR}/assemblies/diamond/${RUNOUT}.transabyss.diamond.txt
	source activate orp;\
	for item in $$(cat ${DIR}/assemblies/diamond/${RUNOUT}.list3); do grep -F $$item ${DIR}/assemblies/diamond/${RUNOUT}.{transabyss,spades75,spades55,trinity}.diamond.txt | head -1 | cut -f1; done | cut -d ":" -f2 | sort --parallel=10 | uniq >> ${DIR}/assemblies/diamond/${RUNOUT}.list5

${DIR}/assemblies/diamond/${RUNOUT}.list6:${DIR}/assemblies/${RUNOUT}.orthomerged.fasta
	grep -F ">" ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta | sed 's_>__' > ${DIR}/assemblies/diamond/${RUNOUT}.list6

${DIR}/assemblies/diamond/${RUNOUT}.list7:${DIR}/assemblies/diamond/${RUNOUT}.list6 ${DIR}/assemblies/diamond/${RUNOUT}.list5
	grep -xFvwf ${DIR}/assemblies/diamond/${RUNOUT}.list6 ${DIR}/assemblies/diamond/${RUNOUT}.list5 > ${DIR}/assemblies/diamond/${RUNOUT}.list7

${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta ${DIR}/assemblies/working/${RUNOUT}.orthomerged.fasta:${DIR}/assemblies/diamond/${RUNOUT}.list7
	source activate orp;\
	python ${MAKEDIR}/scripts/filter.py <(cat ${DIR}/assemblies/${RUNOUT}.{spades55,spades75,transabyss,trinity.Trinity}.fasta) ${DIR}/assemblies/diamond/${RUNOUT}.list7 >> ${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta
	cat ${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta > ${DIR}/assemblies/working/${RUNOUT}.orthomerged.fasta

${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta:${DIR}/assemblies/working/${RUNOUT}.orthomerged.fasta
	source activate orp_cdhit;\
	cd-hit-est -M 5000 -T $(CPU) -c .98 -i ${DIR}/assemblies/working/${RUNOUT}.orthomerged.fasta -o ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta

${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt:${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta
	source activate orp_diamond;\
	diamond blastx --quiet -p $(CPU) -e 1e-8 --top 0.1 -q ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta -d ${MAKEDIR}/software/diamond/swissprot  -o ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
	touch ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt

${DIR}/assemblies/working/${RUNOUT}.unique.ORP.done:${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
	awk '{print $$2}' ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt | awk -F "|" '{print $$3}' | cut -d _ -f1 | sort | uniq | wc -l > ${DIR}/assemblies/working/${RUNOUT}.unique.ORP.txt
	touch ${DIR}/assemblies/working/${RUNOUT}.unique.ORP.done

${DIR}/quants/${RUNOUT}.ortho.idx:${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta
	source activate orp_salmon;\
	salmon index --no-version-check -t ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta -i ${DIR}/quants/${RUNOUT}.ortho.idx -k 31 --threads $(CPU)

${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf:${DIR}/quants/${RUNOUT}.ortho.idx ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	source activate orp_salmon;\
	salmon quant --no-version-check --validateMappings -p $(CPU) -i ${DIR}/quants/${RUNOUT}.ortho.idx --seqBias --gcBias --libType A -1 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq -2 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq -o ${DIR}/quants/salmon_orthomerged_${RUNOUT}

${DIR}/assemblies/${RUNOUT}.filter.done:${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
ifdef TPM_FILT
	cat ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf| awk '$$4 > $(TPM_FILT)' | cut -f1 | sed 1d > ${DIR}/assemblies/working/${RUNOUT}.HIGHEXP.txt
	cat ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf | awk '$$4 < $(TPM_FILT)' | cut -f1 > ${DIR}/assemblies/working/${RUNOUT}.LOWEXP.txt
	touch ${DIR}/assemblies/${RUNOUT}.filter.done
	printf "\n\n\n\n PART: TPM_FILT MAKE LOW AND HIGH\n\n\n\n"
else
	touch ${DIR}/assemblies/${RUNOUT}.filter.done
endif

${DIR}/assemblies/${RUNOUT}.ORP.fasta:${DIR}/assemblies/${RUNOUT}.filter.done ${DIR}/assemblies/working/${RUNOUT}.LOWEXP.txt ${DIR}/assemblies/working/${RUNOUT}.HIGHEXP.txt ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt
	if [[ "$$(test -s ${DIR}/assemblies/working/${RUNOUT}.LOWEXP.txt && echo "yes")" == "yes" ]];\
	then\
			source activate orp;\
			cp ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/assemblies/working/${RUNOUT}.ORP_BEFORE_TPM_FILT.fasta;\
			python ${MAKEDIR}/scripts/filter.py ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/assemblies/working/${RUNOUT}.HIGHEXP.txt > ${DIR}/assemblies/working/${RUNOUT}.ORP.HIGHEXP.fasta;\
			grep -Fwf ${DIR}/assemblies/working/${RUNOUT}.LOWEXP.txt ${DIR}/assemblies/${RUNOUT}.ORP.diamond.txt >> ${DIR}/assemblies/working/${RUNOUT}.blasted;\
			awk '{print $$1}' ${DIR}/assemblies/working/${RUNOUT}.blasted | sort | uniq | tee -a ${DIR}/assemblies/working/${RUNOUT}.donotremove.list;\
			python ${MAKEDIR}/scripts/filter.py ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/assemblies/working/${RUNOUT}.donotremove.list > ${DIR}/assemblies/working/${RUNOUT}.saveme.fasta;\
			cat ${DIR}/assemblies/working/${RUNOUT}.saveme.fasta ${DIR}/assemblies/working/${RUNOUT}.ORP.HIGHEXP.fasta > ${DIR}/assemblies/${RUNOUT}.ORP.fasta;\
			printf "\n\n\n\n PART: FILTER LOW STUFF \n\n\n\n";\
	else\
			cp ${DIR}/assemblies/${RUNOUT}.ORP.intermediate.fasta ${DIR}/assemblies/${RUNOUT}.ORP.fasta;\
			printf "\n\n\n\n PART: THERE IS NO LOW STUFF \n\n\n\n";\
	fi

${DIR}/reports/${RUNOUT}.busco.done:${DIR}/assemblies/${RUNOUT}.ORP.fasta
	source activate orp_busco;\
	python $$(which busco) --offline --lineage ${BUSCODB}/${LINEAGE} -i ${DIR}/assemblies/${RUNOUT}.ORP.fasta -m transcriptome --cpu ${BUSCO_THREADS} -o run_${RUNOUT}.ORP --config ${BUSCO_CONFIG_FILE}
	mv run_${RUNOUT}* ${DIR}/reports/
	touch ${DIR}/reports/${RUNOUT}.busco.done

${DIR}/reports/transrate_${RUNOUT}/assemblies.csv:${DIR}/assemblies/${RUNOUT}.ORP.fasta ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq
	source activate orp;\
	${MAKEDIR}/software/orp-transrate/transrate -o ${DIR}/reports/transrate_${RUNOUT} -a ${DIR}/assemblies/${RUNOUT}.ORP.fasta --left ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq --right ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq -t $(CPU)
	find ${DIR}/reports/transrate_${RUNOUT} -name "*bam" -delete

${DIR}/reports/${RUNOUT}.strandeval.done:${DIR}/assemblies/${RUNOUT}.ORP.fasta
	source activate orp_trinity;\
	bwa index -p ${RUNOUT} ${DIR}/assemblies/${RUNOUT}.ORP.fasta;\
	bwa mem -t $(CPU) ${RUNOUT} \
	<(seqtk sample -s 23894 ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq 400000) \
	<(seqtk sample -s 23894 ${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq 400000) \
	| samtools view -@10 -Sb - \
	| samtools sort -T ${RUNOUT} -O bam -@10 -o "${RUNOUT}".sorted.bam -;\
	samtools flagstat "${RUNOUT}".sorted.bam > ${DIR}/assemblies/${RUNOUT}.flagstat;\
	perl -I $$(dirname $$(readlink -f $$(which Trinity)))/PerlLib ${MAKEDIR}/scripts/examine_strand.pl "${RUNOUT}".sorted.bam ${RUNOUT};\
	hist  -p '#' -c red <(cat ${RUNOUT}.dat | awk '{print $$5}' | sed  1d);\
	rm -f "${RUNOUT}".sorted.bam
	rm -fr ${RUNOUT}.{bwt,pac,ann,amb,sa,dat}
	touch ${DIR}/reports/${RUNOUT}.strandeval.done
	printf "\n\n*****  See the following link for interpretation ***** \n"
	printf "*****  https://oyster-river-protocol.readthedocs.io/en/latest/strandexamine.html ***** \n\n"


clean:
	rm -fr ${DIR}/orthofuse/${RUNOUT}/ ${DIR}/rcorr/${RUNOUT}.TRIM_2P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_1P.fastq ${DIR}/rcorr/${RUNOUT}.TRIM_1P.cor.fq ${DIR}/assemblies/${RUNOUT}.trinity.Trinity.fasta \
	${DIR}/assemblies/${RUNOUT}.spades55.fasta ${DIR}/assemblies/${RUNOUT}.spades75.fasta ${DIR}/assemblies/${RUNOUT}.transabyss.fasta \
	${DIR}/orthofuse/${RUNOUT}/merged.fasta ${DIR}/assemblies/${RUNOUT}.orthomerged.fasta ${DIR}/assemblies/diamond/${RUNOUT}.trinity.diamond.txt \
	${DIR}/assemblies/diamond/${RUNOUT}.newbies.fasta ${DIR}/reports/busco.done ${DIR}/reports/transrate.done ${DIR}/quants/salmon_orthomerged_${RUNOUT}/quant.sf \
	${DIR}/rcorr/${RUNOUT}.TRIM_2P.cor.fq ${DIR}/reports/run_${RUNOUT}.orthomerged/ ${DIR}/reports/transrate_${RUNOUT}/

${DIR}/reports/qualreport.${RUNOUT}.done ${DIR}/reports/qualreport.${RUNOUT}:${DIR}/assemblies/working/${RUNOUT}.unique.ORP.done ${DIR}/assemblies/${RUNOUT}.ORP.fasta
	printf "\n\n*****  QUALITY REPORT FOR: ${RUNOUT} using the ORP version ${VERSION} ****"
	printf "\n*****  THE ASSEMBLY CAN BE FOUND HERE: ${DIR}/assemblies/${RUNOUT}.ORP.fasta **** \n\n"
	printf "*****  BUSCO SCORE ~~~~~~~~~~~~~~~~~~~~~~>" | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/run_${RUNOUT}.ORP -name 'short*') | sed -n 8p  | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  TRANSRATE SCORE ~~~~~~~~~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/transrate_${RUNOUT} -name assemblies.csv) | awk -F , '{print $$37}' | sed -n 2p | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  TRANSRATE OPTIMAL SCORE ~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat $$(find reports/transrate_${RUNOUT} -name assemblies.csv) | awk -F , '{print $$38}' | sed -n 2p | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES ORP ~~~~~~~~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/working/${RUNOUT}.unique.ORP.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES TRINITY ~~~~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.trinity.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES SPADES55 ~~~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp55.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES SPADES75 ~~~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.sp75.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  UNIQUE GENES TRANSABYSS ~~~~~~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/diamond/${RUNOUT}.unique.transabyss.txt | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf "*****  READS MAPPED AS PROPER PAIRS ~~~~~>      " | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	cat ${DIR}/assemblies/${RUNOUT}.flagstat | grep "properly paired" | awk '{print $$6}' | sed 's_(__' | tee -a ${DIR}/reports/qualreport.${RUNOUT}
	printf " \n\n"
