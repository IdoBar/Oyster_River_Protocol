#!/usr/bin/make -rRsf

SHELL=/bin/bash -o pipefail

#USAGE:
#
#	make
#

MAKEDIR := $(dir $(firstword $(MAKEFILE_LIST)))
DIR := ${CURDIR}
CONDAROOT = ${DIR}/software/anaconda
orthopath := $(shell ls ${DIR}/software/OrthoFinder/orthofinder/orthofuser.py 2>/dev/null)
orthufuserversion = $(shell orthofuser.py --help | grep "OrthoFinder version" | awk '{print $$3}')
transrate := $(shell ls ${DIR}/software/orp-transrate/transrate 2>/dev/null)
# transabysspath := $(shell which ${DIR}/software/transabyss/transabyss 2>/dev/null)
# transabyssversion = $(shell conda ${DIR}/software/anaconda/install/bin/activate orp 2>/dev/null; transabyss --version 2>/dev/null; conda deactivate 2> /dev/null)
# trinitypath := $(shell which ${DIR}/software/trinityrnaseq-v2.12.0/Trinity 2>/dev/null)
# trinityversion = $(shell ${DIR}/software/trinityrnaseq-v2.12.0/Trinity --version | awk '{print $$3}' | head -1 | awk -F 'v' '{print $$2}')
# spadespath := $(shell which ${DIR}/software/SPAdes-3.15.2-Linux/bin/spades.py 2>/dev/null)
# spadesversion = $(shell ${DIR}/software/SPAdes-3.15.2-Linux/bin/spades.py --version | awk -F 'v' '{print $$2}')
diamond_data := $(shell ls ${DIR}/software/diamond/uniprot_sprot.fasta 2>/dev/null)
busco_data := $(shell ls ${DIR}/busco_dbs/eukaryota_odb10 2>/dev/null)
conda := $(shell conda info 2>/dev/null)
orp := $(shell ${CONDAROOT}/bin/conda info --envs | grep orp 2>/dev/null)
VERSION := ${shell cat  ${MAKEDIR}/version.txt}

all: setup conda orp orthofuser transrate diamond_data busco_data postscript

.DELETE_ON_ERROR:

setup:
	@mkdir -p ${DIR}/shared
	@mkdir -p ${DIR}/software
	@mkdir -p ${DIR}/software/diamond

conda:setup
ifdef conda
else
	cd ${DIR}/software && wget -O Miniforge3.sh "https://github.com/conda-forge/miniforge/releases/download/24.11.3-0/Miniforge3-24.11.3-0-Linux-x86_64.sh"
	cd ${DIR}/software && bash Miniforge3.sh -b -p ${CONDAROOT}
#	@echo ". ${CONDAROOT}/etc/profile.d/conda.sh" >> ~/.bashrc;
#	@echo ". ${CONDAROOT}/etc/profile.d/mamba.sh" >> ~/.bashrc;
	@echo ". ${CONDAROOT}/etc/profile.d/conda.sh" > pathfile
	source ~/.bashrc
endif

orp:orp_env.yml conda setup
ifdef orp
else
	( \
				source ${CONDAROOT}/etc/profile.d/conda.sh
				conda activate 
				conda config --set solver libmamba
				conda config --add channels conda-forge
				conda config --add channels bioconda
				mamba update -y -n base conda
				mamba env create  -f ${DIR}/orp_env.yml
# 				mamba clean -ya
				mamba env create  -f ${DIR}/orp_assemble_env.yml
#				mamba clean -ya
				mamba env create  -f ${DIR}/orp_pre_env.yml
#				mamba clean -ya
				mamba env create  -f ${DIR}/orp_post_env.yml
				mamba clean -ya
				conda deactivate
  )
	@echo PATH=\$$PATH:${CONDAROOT}/bin >> pathfile
endif


diamond_data:conda
ifdef diamond_data
		@echo "diamond_data is already installed"
else
		cd ${DIR}/software/diamond && aria2c -x5 https://ftp.uniprot.org/pub/databases/uniprot/current_release/knowledgebase/complete/uniprot_sprot.fasta.gz && gzip -d uniprot_sprot.fasta.gz && ${CONDAROOT}/envs/orp_post/bin/diamond makedb --in uniprot_sprot.fasta -d swissprot
endif

busco_data:conda
ifdef busco_data
else
	mkdir ${DIR}/busco_dbs && cd ${DIR}/busco_dbs
	cd ${DIR}/busco_dbs && aria2c -x5 https://busco-data.ezlab.org/v5/data/lineages/eukaryota_odb10.2024-01-08.tar.gz && tar -zxf eukaryota_odb10.2024-01-08.tar.gz
endif

transrate:
ifdef transrate
else
	cd ${DIR}/software && tar -zxf orp-transrate.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/orp-transrate >> pathfile
endif

orthofuser:
ifdef orthopath
ifeq ($(orthufuserversion),2.5.2)
	@echo "orthofuser right version is already installed"
else
	@echo "version ${orthufuserversion}"
	@echo "orthofuser is installed, but not the right version"
	cd ${DIR}/software/OrthoFinder/ && git pull
endif
else
	@echo "orthofuser is not installed and needs to be installed"
	cd ${DIR}/software && aria2c -x5 https://github.com/davidemms/OrthoFinder/releases/download/2.5.2/OrthoFinder.tar.gz
	cd ${DIR}/software/ && tar -zxf OrthoFinder.tar.gz
	@echo PATH=\$$PATH:${DIR}/software/OrthoFinder/ >> pathfile
endif

postscript: setup orp diamond_data busco_data orthofuser conda transrate
	@if [ -f pathfile ]; then\
		printf "\n\n*** The following location(s), if any print, need to be added to your PATH ***";\
		printf "\n*** They will be automatically to your ~/.profile or ~/.bash_profile ***\n\n";\
		cat pathfile;\
		cat pathfile >> ~/.profile;\
		cat pathfile >> ~/.bash_profile;\
		cat pathfile >> ~/.bash_profile;\
		export PATH=$$PATH:$$(cat pathfile);\
		printf "\n\n\n";\
		printf "\n*** type ``source ~/.profile`` to complete the install ***\n\n";\
	fi

clean:
	${CONDAROOT}/bin/conda remove -y --name orp --all
	rm -fr ${DIR}/software/anaconda/install
	rm -fr ${DIR}/software/OrthoFinder/
	rm -fr ${DIR}/software/orp-transrate
	rm -fr ${DIR}/software/transabyss
	rm -fr ${DIR}/software/anaconda/
	rm -fr ${DIR}/pathfile
