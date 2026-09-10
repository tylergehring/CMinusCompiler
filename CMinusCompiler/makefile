c-: parser.tab.o lex.yy.o
	g++ -o c- parser.tab.o lex.yy.o -lfl

parser.tab.c parser.tab.h: parser.y
	bison -d parser.y

lex.yy.c: parser.l parser.tab.h
	flex parser.l

parser.tab.o: parser.tab.c
	g++ -c parser.tab.c

lex.yy.o: lex.yy.c
	g++ -c lex.yy.c

clean:
	rm -f c- parser.tab.c parser.tab.h lex.yy.c *.o