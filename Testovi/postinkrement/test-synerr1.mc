//OPIS: primjena inkrementa na poziv funkcije
int f(int x) {
	int a, b;
	b = x + a;
	return b;
}
int main(){
	int k;
	k = f(4)++;
	return 0;
}
