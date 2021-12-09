//OPIS: inkrement promjenljive unutar izraza
//RETURN: 1
int f(int x){
	x = x + 4; 
	return x;
}
int main(){
	int a, b, c, k, i;
	b = 1;
	a = f(3);
 	c = a++ + b - 8;
	k = i - c++;
	return c;
}
