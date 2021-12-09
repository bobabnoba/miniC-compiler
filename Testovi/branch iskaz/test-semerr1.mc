//OPIS: conditional expressions razlicitog tipa
int main(){
	int a;
	unsigned b;
	a = 7;
	b = 3u;

	a = a + (a == b) ? a : b + 3;

	return a;
}
