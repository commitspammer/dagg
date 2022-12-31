typedef struct vector {
	int *data;
	size_t size;
	size_t cap;
} _Vector;

_Vector *_vcreate() {
	_Vector *v = malloc(sizeof(_Vector));
	v->size = 0;
	v->cap = 20;
	v->data = malloc(sizeof(int) * v->cap);
	return v;
}

void _vpush(_Vector *v, int num) {
	if (v->size < v->cap) goto SKIP;
	v->cap += v->cap / 2;
	v->data = realloc(v->data, sizeof(int) * v->cap);
	SKIP:
	v->data[v->size++] = num;
}

int _vpop(_Vector *v) {
	if (v->size <= 0) goto SKIP;
	v->size--;
	return v->data[v->size];
	SKIP:
	return 0;
}

_Vector *_vof(int vacount, ...) {
	_Vector *v = _vcreate();
	va_list valist;
	va_start(valist, vacount);
	int i = 0;
	LOOP:
	if (!(i++ < vacount)) goto JUMP;
	int n = va_arg(valist, int);
	_vpush(v, n);
	goto LOOP;
	JUMP:
	va_end(valist);
	return v;
}

_Vector *_vrange(int begin, int end) {
	_Vector *v = _vcreate();
	int i = 0;
	LOOP:
	if (!(i < end)) goto JUMP;
	_vpush(v, i);
	i++;
	goto LOOP;
	JUMP:
	return v;
}

void *_vconcat(_Vector *v1, _Vector *v2) {
	int i = 0;
	int len = v2->size;
	LOOP:
	if (!(i < len)) goto JUMP;
	_vpush(v1, v2->data[i]);
	i++;
	goto LOOP;
	JUMP: ;
}
