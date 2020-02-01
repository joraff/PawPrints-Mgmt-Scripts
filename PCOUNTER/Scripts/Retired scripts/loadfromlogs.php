<?php

// PHP Script to parse the PCOUNTER.log files and get per-printer history.
// 2008 Baylor University, Joseph Rafferty

ini_set('memory_limit', '-1');

list($usec, $sec) = explode(' ', microtime());
$script_start = (float) $sec + (float) $usec;

$db = mysql_connect('.', 'username', 'password');
if (!$db) {
    die('Could not connect: ' . mysql_error());
}
mysql_select_db('print_history');



if(count($argv)>1) {
	$start_date = $argv[1];
	$end_date = $argv[2];

	for ($x=strtotime($start_date);$x<=strtotime($end_date);$x=$x+86400) {
		$filename = "c:\PCOUNTER\DATA\PCOUNTER_".date('Y_md',$x).".LOG";
		echo "Processing $filename\n";
		if (file_exists($filename)) {
			$jobs = array();
			$contents = file_get_contents($filename);
			$lines = explode("\n", trim($contents));
			$num = count($lines);
			foreach($lines as $line) {
				$elements = explode(',', $line);
				foreach($elements as $key=>$value) {
					$elements[$key] = addslashes($value);
				}
				if(count($elements)) $jobs[] = $elements;
			}
			
			$numjobs = count($jobs);
			$iterations = ceil($numjobs/2500);
			
			echo ":inserting $numjobs jobs in $iterations iterations\n";
			for ($i=0; $i < $iterations; $i++) { 
				echo " inserting batch ".($i+1)."... ";
				$sql = "INSERT INTO `history` (	`username`, `docname`, `printer`, `date`, `time`, `client`, `clientcode`, `subcode`, `papersize`, `optstring`, `size`, `pages`, `cost`, `balance`) VALUES ";

				
				for($y=($i*2500); $y < ($i+1)*2500 && $y < $numjobs; $y++) {
					$job = $jobs[$y];
					$sql .= "( '".$job[0]."', '".$job[1]."', '".$job[2]."', '".$job[3]."', '".$job[4]."', '".$job[5]."', '".$job[6]."', '".$job[7]."', '".$job[8]."', '".$job[9]."', '".$job[10]."', '".$job[11]."', '".$job[12]."', '".$job[13]."' ), ";
				}
				
				$sql = rtrim($sql, ', ');
			
				if( mysql_query($sql) ) echo " done\n";
				else echo "error: ".mysql_error()."\n";
			}
		}
	}		


	list($usec, $sec) = explode(' ', microtime());
	$script_end = (float) $sec + (float) $usec;

	echo "Time Elapsed: ".round($script_end - $script_start, 3)." seconds\n";
} else {
	echo "Usage:  php logfileinsert.php {start_date} {end_date} \n\nDates should be in the format of MM/DD/YYYY\n\n\n";
}

?>