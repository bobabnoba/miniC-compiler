//OPIS: cond exp nije par|var|literal
int f(){
	int a;
	a = 4;
	return a;
}
int main(int k) {
	int a;
	int b;
	a = 7;
	b = 3;
	
	a = a + (a == b) ? f : b + 3;

	return a;
}
