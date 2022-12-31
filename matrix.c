typedef struct matrix {
	_Vector **data;
	size_t size;
	size_t cap;
} _Matrix;

_Matrix *_mcreate() {
	_Matrix *m = malloc(sizeof(_Matrix));
	m->size = 0;
	m->cap = 20;
	m->data = malloc(sizeof(_Vector*) * m->cap);
	return m;
}

void _mpush(_Matrix *m, _Vector *v) {
	if (m->size < m->cap) goto SKIP;
	m->cap += m->cap / 2;
	m->data = realloc(m->data, sizeof(_Vector*) * m->cap);
	SKIP:
	m->data[m->size++] = v;
}

_Vector *_mpop(_Matrix *m) {
	if (m->size <= 0) goto SKIP;
	m->size--;
	return m->data[m->size];
	SKIP:
	return NULL;
}

_Matrix *_mof(int vacount, ...) {
	_Matrix *m = _mcreate();
	va_list valist;
	va_start(valist, vacount);
	int i = 0;
	LOOP:
	if (!(i++ < vacount)) goto JUMP;
	_Vector *v = va_arg(valist, _Vector*);
	_mpush(m, v);
	goto LOOP;
	JUMP:
	va_end(valist);
	return m;
}

void *_mconcat(_Matrix *m1, _Matrix *m2) {
	int i = 0;
	int len = m2->size;
	LOOP:
	if (!(i < len)) goto JUMP;
	_mpush(m1, m2->data[i]);
	i++;
	goto LOOP;
	JUMP: ;
}
