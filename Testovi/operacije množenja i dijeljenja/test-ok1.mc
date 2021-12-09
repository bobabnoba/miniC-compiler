//OPIS: korektan for iskaz
//RETURN:20
int main(){
	int zbir, razlika, i;
	zbir = 0;
	razlika = 0;
	for i in ( 1 .. 5 step 1){
		zbir = zbir + i;
		razlika = razlika - i;
	}
	return zbir - razlika;
}
