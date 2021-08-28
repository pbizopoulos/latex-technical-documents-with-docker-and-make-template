.POSIX:

is_shell_interactive:=$(shell [ -t 0 ] && echo 1)
ifdef is_shell_interactive
	debug_args=--interactive --tty
endif

ifneq (, $(shell which nvidia-container-cli))
	gpu_args=--gpus all
endif

host_volume=$(dir $(realpath Makefile))
container_volume=/workspace
tmp_directory=tmp

$(shell mkdir -p $(tmp_directory))

$(tmp_directory)/ms.pdf: ms.bib ms.tex $(tmp_directory)/execute-python
	docker container run \
		--rm \
		--user `id -u`:`id -g` \
		--volume $(host_volume):$(container_volume)/ \
		--workdir $(container_volume)/ \
		texlive/texlive latexmk -gg -pdf -usepretex="\pdfinfoomitdate=1\pdfsuppressptexinfo=-1\pdftrailerid{}" -outdir=$(tmp_directory)/ ms.tex

$(tmp_directory)/execute-python: Dockerfile main.py requirements.txt
	docker container run \
		$(debug_args) \
		$(gpu_args) \
		--detach-keys "ctrl-^,ctrl-^"  \
		--env HOME=$(container_volume)/$(tmp_directory) \
		--rm \
		--user `id -u`:`id -g` \
		--volume $(host_volume):$(container_volume)/ \
		--workdir $(container_volume)/ \
		`docker image build -q .` python main.py $(VERSION)
	touch $(tmp_directory)/execute-python

clean:
	rm -rf $(tmp_directory)/

$(tmp_directory)/format-python: main.py
	docker container run \
		--rm \
		--user `id -u`:`id -g` \
		--volume $(host_volume):$(container_volume)/ \
		--workdir $(container_volume)/ \
		alphachai/isort main.py
	docker container run \
		--rm \
		--user `id -u`:`id -g` \
		--volume $(host_volume):$(container_volume)/ \
		--workdir $(container_volume)/ \
		peterevans/autopep8 -i --max-line-length 1000 main.py
	touch $(tmp_directory)/format-python

$(tmp_directory)/lint-texlive: ms.bib ms.tex $(tmp_directory)/execute-python
	docker container run \
		--rm \
		--user `id -u`:`id -g` \
		--volume $(host_volume):$(container_volume)/ \
		--workdir $(container_volume)/ \
		texlive/texlive bash -c "chktex ms.tex && lacheck ms.tex"
	touch $(tmp_directory)/lint-texlive

$(tmp_directory)/arxiv.tar: $(tmp_directory)/ms.pdf
	cp $(tmp_directory)/ms.bbl .
	tar cf $(tmp_directory)/arxiv.tar ms.bbl ms.bib ms.tex `grep './$(tmp_directory)' $(tmp_directory)/ms.fls | uniq | cut -b 9-`
	rm ms.bbl

$(tmp_directory)/download-arxiv:
	curl https://arxiv.org/e-print/`grep arxiv.org README | cut -d '/' -f5` | tar xz
	mv ms.bbl $(tmp_directory)/
	touch $(tmp_directory)/download-arxiv $(tmp_directory)/execute-python

$(tmp_directory)/update-makefile:
	curl -LO https://github.com/pbizopoulos/a-makefile-for-developing-containerized-latex-technical-documents-template/raw/master/Makefile

$(tmp_directory)/update-docker-images:
	docker image pull alphachai/isort
	docker image pull peterevans/autopep8
	docker image pull texlive/texlive
