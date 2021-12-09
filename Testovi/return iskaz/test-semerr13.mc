//OPIS: int funkcija bez return-a
//RETURN:2
int f(int w){
	int r;
	r = w++;
}
int main(){
	int a, b, k;
	a = 4;
	b = 2;
	k = b + 4 - a++;
	return k;
}
