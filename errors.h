#ifndef ERRORS_H
#define ERRORS_H

#include <stdlib.h>
#include <stdio.h>

void notdecl(int line, char *id) {
    fprintf(stderr, "line %d: %s not declared\n", line, id);
	exit(1);
}

void alreadydecl(int line, char *id) {
    fprintf(stderr, "line %d: %s already declared\n", line, id);
	exit(1);
}

void notid(int line, char *str) {
    fprintf(stderr, "line %d: %s isn't an id\n", line, str);
	exit(1);
}

void badtype(int line, char *id, char *actual, char *expected) {
    fprintf(stderr, "line %d: %s has type %s, expected %s\n", line, id, actual, expected);
	exit(1);
}

void unmatchtype(int line, char *id1, char* type1, char *id2, char *type2) {
    fprintf(stderr, "line %d: %s of type %s doesn't match %s of type %s\n", line, id1, type1, id2, type2);
	exit(1);
}

void unmatchassign(int line, int expcount, int varcount) {
    fprintf(stderr, "line %d: assign of %d expressions to %d variables\n", line, expcount, varcount);
	exit(1);
}

void unmatchcall(int line, int argcount) {
    fprintf(stderr, "line %d: call with %d arguments doesn't match number of function parameters\n", line, argcount);
	exit(1);
}

void badderef(int line, char *id) {
    fprintf(stderr, "line %d: excessive %s dereferencing\n", line, id);
	exit(1);
}

void unsupp(int line, char *feature) {
    fprintf(stderr, "line %d: %s unsupported\n", line, feature);
	exit(1);
}

void fatal(int line, char *msg) {
    fprintf(stderr, "line %d: %s\n", line, msg);
	exit(1);
}

#endif
