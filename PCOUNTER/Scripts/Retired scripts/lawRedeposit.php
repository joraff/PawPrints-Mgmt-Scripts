<?php

$law_students = file("/Users/joraff/Desktop/G_Law_Student_Paw.txt");
/*
foreach($law_students as $line) {
	list($student, $balance) = explode($line, " ");
	$student = trim($student);
	$balance = trim($balance);
	echo "Re-setting balance for $student\n";
	$pathToAccountExe = "C:\Progra~1\Pcount~1\NT\ACCOUNT";
	
	$output = `$pathToAccoountExe BALANCE $student $balance 'Balance adjustment on 1/9/09'`
}
*/
foreach($law_students as $student) {
	$student = trim($student);
	$temp=split("[\n ]",`$pathToAccountExe VIEWBAL $refundUserName`);
	$endBalance = $temp[5];
	echo "$student = $endBalance\n";
}

?>