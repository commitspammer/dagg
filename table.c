#include <stdio.h>
#include <stdlib.h>
#include <string.h>
#include "table.h"

//typedef struct symbol {
//	char *name;
//	char *type;
//	int scope;
//} Symbol;

typedef struct table {
	Symbol symbol;
	struct table *next;
} Table;

typedef struct scope {
	int stack[100];
	int size;
} Scope;

Table *TABLE = NULL;
Scope SCOPE = { {0}, 0 };

static int search(char *name, int scope, Symbol *symb, Table *table) {
	if (table == NULL) {
		return 0;
	} else if (table->symbol.scope == scope && !strcmp(table->symbol.name, name)) {
		*symb = table->symbol; //i hope this is copying
		return 1;
	} else if (table->next == NULL) {
		return 0;
	} else {
		return search(name, scope, symb, table->next); 
	}
}

int lookup(char *name, Symbol *symb) {
	if (SCOPE.size <= 0) return 0;
	int i = SCOPE.size - 1;
	int found;
	do {
		found = search(name, SCOPE.stack[i], symb, TABLE);
	} while (!found && i-- > 0);
	return found;
}

int insert(char *name, char *type) {
	Symbol symb;
	if (lookup(name, &symb)) return 0;
	Table *newtable = malloc(sizeof(Table));
	newtable->symbol.name = strdup(name);
	newtable->symbol.type = strdup(type);
	newtable->symbol.scope = SCOPE.size > 0 ? SCOPE.stack[SCOPE.size-1] : -1;
	newtable->next = TABLE;
	TABLE = newtable;
	return 1;
}

void up() {
	static int scope_counter = 1;
	SCOPE.stack[SCOPE.size++] = scope_counter++;
	//for(int i=0;i<scope.size;i++) printf("%d,", scope.stack[i]); printf("\n");
}

void down() {
	if (SCOPE.size > 0) SCOPE.stack[--SCOPE.size] = 0;
}

void print_table() {
	Table *t = TABLE;
	while (t != NULL) {
		printf("%20s|%40s|%3d\n", t->symbol.name, t->symbol.type, t->symbol.scope);
		t = t->next;
	}
}

void free_table() {
	Table *table = TABLE;
	while (table != NULL) {
		Table *tmp = table->next;
		free(table->symbol.name);
		free(table->symbol.type);
		//free(table->symbol.scope);
		free(table);
		table = tmp;
	}
}


/*
Symbol symb;
if (lookup(id, &symb)) {
	//...
}

int error;
Symbol symb = lookup(id, &error);
if (!error) {
	//...
}
*/
