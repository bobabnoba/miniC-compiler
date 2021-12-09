//OPIS: redefinicija funkcije
int f(){
	int k, l;
	k = 4 * l;
	return k;
}
int f(){
	int r;
	r = 45;
	return r;
}
int main(){
	int a, b, c;
	a = 42;
	b = f();
	return 0;
}
