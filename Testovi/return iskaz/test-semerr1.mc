//OPIS: return exp u void funkciji
void k(int x){
	int a;
	a = x++;
	return a;
}
int main(){
	k(4);
	return 0;
}
