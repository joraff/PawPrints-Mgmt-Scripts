<?php

$lawStudents = file('G_Law_Student_Paw.txt');

$balances = array();

if(count($lawStudents)) {
	$pathToAccountExe = "C:\Progra~1\Pcount~1\NT\ACCOUNT";
	
	print_r($students);
	
	foreach($lawStudents as $student) {
		if(strlen($student)) {
			$student = trim($student);
			$output = split("[\n ]", `$pathToAccountExe VIEWBAL $student`);
			$balances[] = $output[5];
		}
	}
	echo "<pre>";
	print_r($balances);
} else {
	echo "no students in file";
}
?>