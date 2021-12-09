//OPIS: neispravan poziv void funkcije
void f(){
	return;
}
int main(){
	int k;
	k = f();
	return 0;
}
