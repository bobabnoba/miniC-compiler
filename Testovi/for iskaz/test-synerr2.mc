//OPIS: () umjesto []
int main(){
	int a;
	branch ( a -> 1 -> 3 -> 5 )
		one a = a + 1;
		two a = a + 3;
		three a = a + 5;
		other a = a - 3;
	end_branch

	return 0;
}
