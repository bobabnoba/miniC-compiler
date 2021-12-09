//OPIS: primjena inkrementa na parametar funkcije
//RETURN:9
int fun(int r){
	int a;
	a = 1 + r;
	return a;
}
int main(){
	int s, u;
	s = 8;
	u = fun(s++);
	return u;
}
