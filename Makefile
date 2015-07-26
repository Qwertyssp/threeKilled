all:
	git submodule update --init --recursive
	git submodule foreach git pull origin master
	make -C silly BUILD_PATH=`pwd` TARGET=game macosx

