<?php

/*************
** phcron.php - inserts the previous day's print log entries into a MySQL db. 
** intended to be executed by cron or some other scheduling service.
** 
** Joseph Rafferty
** Baylor University
** Created: Oct 13 2008
** 
** Last Modified: Oct 13 2008
*************/
set_time_limit(300);
$yest = time()-86400;
$logfile = "PCOUNTER_".date('Y_md',$yest).".LOG";
echo "Will try to insert $logfile \n";
$logpath = "C:\PCOUNTER\DATA\\";

// $jobs is our 2D array of jobs. each element of jobs is an array of a single job's attributes.
$jobs = array();


if (file_exists($logpath.$logfile)) {
	$contents = file_get_contents($logpath.$logfile);
	$lines = explode("\n", trim($contents));
	$num = count($lines);
	foreach($lines as $line) {
		$elements = explode(',', $line);
		$elements[1] = addslashes($elements[1]);
		if(count($elements)) $jobs[] = $elements;
	}
} else {
	die('Logfile $logfile not found!');
}


$db = mysql_connect('.', 'username', 'password');
if (!$db) {
    die('Could not connect: ' . mysql_error());
}
mysql_select_db('print_history');

$sql = "INSERT INTO `history` (	`username`,
								`docname`,
								`printer`,
								`timestamp`,
								`client`,
								`subcode`,
								`clientcode`,
								`papersize`,
								`optstring`,
								`size`,
								`pages`,
								`cost`,
								`balance`) VALUES ";
$numjobs = count($jobs);

echo "Inserting $numjobs jobs\n";

for($x=0; $x<$numjobs; $x++) {
	$job = $jobs[$x];
	$sql .= "(	'".str_replace('BAYLOR\\','',$job[0])."',
				'".$job[1]."',
				'".str_replace('\\\\GUS\\','',$job[2])."',
				'".date('Y-m-d H:i:s', mktime(substr($job[4],0,2),substr($job[4],3,2),0,substr($job[3],0,2),substr($job[3],3,2),substr($job[3],6,4)))."',
				'".substr($job[5],2)."',
				'".$job[6]."',
				'".$job[7]."',
				'".$job[8]."',
				'".$job[9]."',
				'".$job[10]."',
				'".$job[11]."',
				'".$job[12]."',
				'".trim($job[13])."')";
	$sql .= ($x==($numjobs-1)) ? "" : ", ";
}

mysql_query($sql);
echo mysql_error();
// To speed up insertion into the DB, we lock the table to flush the indexes
// LOCK TABLES history WRITE;

// then do the inserts

// then unlock (commit) the table
// UNLOCK TABLES;

mysql_close($db);

?>