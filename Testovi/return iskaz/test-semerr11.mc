//OPIS: poziv return; u int funkciji (warn)
//RETURN: 5
int f(int a){ 
	int b;
	b = a++ + 5;
	return; 
}
int main(){
	int c;
	c = 5;
	return c;
}
