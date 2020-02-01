<?php

$lost_students = file("Lost_Students.txt");
$pathToAccountExe = "C:\Progra~1\Pcount~1\NT\ACCOUNT";

foreach($lost_students as $student) {
	$student = trim($student);
	$temp=`$pathToAccountExe DEPOSIT $student`;
	echo $temp;
}

?>