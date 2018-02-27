#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	make
#

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
shannonpath := $(shell which shannon.py 2>/dev/null)
brewpath := $(shell which brew 2>/dev/null)
rcorrpath := $(shell which rcorrector 2>/dev/null)
orthopath := $(shell which orthofuser.py 2>/dev/null)
trimmomaticpath := $(shell which trimmomatic 2>/dev/null)
salmonpath := $(shell which salmon 2>/dev/null)
bowtie2path := $(shell which bowtie2 2>/dev/null)
hmmerpath := $(shell which hmmsan 2>/dev/null)
mclpath := $(shell which mcl 2>/dev/null)
transrate := $(shell which transrate 2>/dev/null)
blast := $(shell which blastp 2>/dev/null)
spades := $(shell which spades.py 2>/dev/null)
trinity := $(shell which Trinity 2>/dev/null)
seqtk := $(shell which seqtk 2>/dev/null)
busco := $(shell which run_BUSCO.py 2>/dev/null)
quorumpath := $(shell which quorum 2>/dev/null)


all: setup brew mcl hmmer quorum orthofuser rcorrector blast spades trinity shannon seqtk busco trimmomatic transrate bowtie2 salmon postscript

.DELETE_ON_ERROR:

#need salmon, bowtie2, mcl, fix path designations

setup:
	@mkdir -p ${DIR}/scripts
	@mkdir -p ${DIR}/shared
	@rm -f pathfile

brew:setup
ifdef brewpath
	@echo "BREW is already installed"
else
	$error("*** BREW MUST BE PROPERLY INSTALLED BEFORE YOU CAN PROCEED, SEE: http://angus.readthedocs.io/en/2016/linuxbrew_install.html ***")
endif

transrate:brew
	cd ${DIR}/software && tar -zxf orp-transrate.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/orp-transrate >> pathfile

rcorrector:brew
ifdef rcorrpath
	@echo "RCORRECTOR is already installed"
else
	brew install rcorrector
endif

quorum:brew
ifdef quorumpath
	@echo "quorum is already installed"
else
	mkdir ${DIR}/software/quorum
	cd ${DIR}/software/quorum && curl -LO ftp://ftp.genome.umd.edu/pub/QuorUM/quorum_easy_install
	cd ${DIR}/software/quorum && sh ./quorum_easy_install
	@echo PATH=\$$PATH:${DIR}/software/quorum/bin >> pathfile
endif

mcl:brew rcorrector
ifdef mclpath
	@echo "MCL is already installed"
else
	brew install mcl
endif

hmmer:brew mcl
ifdef hmmerpath
	@echo "HMMER is already installed"
else
	brew install hmmer
endif

bowtie2:brew hmmer
ifdef bowtie2path
	@echo "BOWTIE2 is already installed"
else
	brew install bowtie2
endif

orthofuser:brew
ifdef orthopath
	@echo "ORTHOFUSER is already installed"
else
	@touch pathfile
	cd ${DIR}/software && git clone https://github.com/macmanes-lab/OrthoFinder.git
	@echo PATH=\$$PATH:${DIR}/software/OrthoFinder/orthofinder >> pathfile
endif

blast:brew
ifdef blast
	@echo "BLASTP is already installed"
else
	@echo "blastp is not installed, installing now..."
	cd ${DIR}/software && curl -LO ftp://ftp.ncbi.nlm.nih.gov/blast/executables/blast+/LATEST/ncbi-blast-2.7.1+-x64-linux.tar.gz && tar -zxf ncbi-blast-2.7.1+-x64-linux.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/ncbi-blast-2.7.1+/bin >> pathfile
endif

spades:brew
ifdef spades
	@echo "SPAdes is already installed"
else
	cd ${DIR}/software && \
	curl -LO http://cab.spbu.ru/files/release3.11.1/SPAdes-3.11.1-Linux.tar.gz && tar -zxf SPAdes-3.11.1-Linux.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/SPAdes-3.11.1-Linux/bin >> pathfile
endif

trinity:brew
ifdef trinity
	@echo "TRINITY is already installed"
else
	cd ${DIR}/software && \
	git clone https://github.com/trinityrnaseq/trinityrnaseq.git && cd trinityrnaseq && make -j4
	@echo PATH=\$$PATH:${DIR}/software/trinityrnaseq >> pathfile
endif

shannon:brew
ifdef shannonpath
	@echo "SHANNON is already installed"
else
	cd ${DIR}/software && git clone https://github.com/sreeramkannan/Shannon.git
	chmod +x software/Shannon/shannon.py
	@echo PATH=\$$PATH:${DIR}/software/Shannon >> pathfile
endif


salmon:brew
ifdef salmonpath
	@echo "SALMON is already installed"
else
	cd ${DIR}/software && curl -LO https://github.com/COMBINE-lab/salmon/releases/download/v0.8.2/Salmon-0.8.2_linux_x86_64.tar.gz &&\
	tar -zxf ${DIR}/software/Salmon-0.8.2_linux_x86_64.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/Salmon-0.8.2_linux_x86_64/bin >> pathfile
endif

seqtk:brew
ifdef seqtk
	@echo "SEQTK is already installed"
else
	cd ${DIR}/software && \
	git clone https://github.com/lh3/seqtk.git && cd seqtk && make
	@echo PATH=\$$PATH:${DIR}/software/seqtk >> pathfile
endif

busco:brew
ifdef busco
	@echo "BUSCO is already installed"
else
	cd ${DIR}/software && \
	git clone https://gitlab.com/ezlab/busco.git && cd busco && python setup.py install --user --prefix=
	@echo PATH=\$$PATH:${DIR}/software/busco/scripts >> pathfile
endif

trimmomatic:brew bowtie2
ifdef trimmomaticpath
	@echo "TRIMMOMATIC is already installed"
else
	@if [ $$(hostname | cut -d. -f3-5) == 'bridges.psc.edu' ];\
	then\
		module load trimmomatic/0.36;\
		echo "I just installed TRIMMOMATIC via the module system ";\
	else\
		brew install trimmomatic;\
		echo "I just installed TRIMMOMATIC via brew ";\
	fi
endif

postscript:brew setup transrate rcorrector mcl hmmer bowtie2 orthofuser blast spades trinity shannon salmon seqtk busco trimmomatic
	@printf "\n\n*** The following location(s), if any print, need to be added to your PATH ***"
	@printf "\n*** They will be automatically to your ~/.profile or ~/.bash_profile ***\n\n"
	@cat pathfile
	@cat pathfile >> ~/.profile
	@cat pathfile >> ~/.bash_profile
	@export PATH=$$PATH:$$(cat pathfile)
	@printf "\n\n\n"
	@printf "\n*** type <<source ~/.profile>> to complete the install ***\n\n"
