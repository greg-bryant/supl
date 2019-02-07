SHELL = /bin/sh

srcdir = .

VERBOSE = 1

#all: gen
#	./gen

#gen: gen.c
#	gcc gen.c -o gen

#supl: supl.o
#	ln supl.o supl
#	./supl

#supl.o: 
#	gcc supl.c -o supl.o

all: supl.c supl_y.c
	gcc -std=gnu90 supl.c -o supl

supl_y.c: supl_y.y supl_l.l
	lex -o supl_l.c supl_l.l
	yacc supl_y.y -o supl_y.c


# grogix CL compiler for mac / unix / linux
# intended to replace directory structure impositions
# and generate files for end-to-end webapps
# 	gcc -o $@ $^ -I../include -L../lib

grogix: grogix_y.o
	gcc -o grogix grogix_y.o

grogix_l.o: grogix_l.l
	gcc grogix_l.c -o grogix_l.o

grogix_y.o: grogix_y.c grogix_l.c
	gcc grogix_y.c -o grogix_y.o

grogix_l.c:
	flex grogix_l.l

grogix_y.c:
	bison grogix_y.y

