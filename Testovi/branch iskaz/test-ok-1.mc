//OPIS: korektan conditional izraz
//RETURN: 13
int main() {
	int a;
	int b;
	a = 7;
	b = 3;

	a = a + (a == b) ? a : b + 3;

	return a;
}
