all:
	gcc -I ../silly/lua53 -o client main.c -L ../silly/lua53/ -llua -lm -Wl,-no_compact_unwind
	gcc -I ../silly/lua53 -o socket.so -dynamiclib -fPIC -Wl,-undefined,dynamic_lookup socket.c
clean:
	-rm main
