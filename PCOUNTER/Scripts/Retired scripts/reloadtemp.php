<?php

/*************
** reloadtemp.php - truncates the temp table and reloads it from the current pcounter.log file 
** intended to be executed by cron or some other scheduling service BEFORE tailing pcounter.log
** 
** Joseph Rafferty
** Baylor University
** Created: Dec 9 2008
** 
** Last Modified: Dec 9 2008
*************/

require_once 'historydb.class.php';

$db = new historydb;

function truncate_temp()
{
	echo "Truncating temp jobs table\n";
	$sql = "TRUNCATE TABLE temp";
	return mysql_query($sql);
}

function create_job_array($file)
{
	echo "Creating job array from $file \n";
	
	$jobs = array();
	
	if (file_exists($file)) {
		$contents = file_get_contents($file);
		$lines = explode("\n", trim($contents));
		$num = count($lines);
		foreach($lines as $line) {
			$elements = explode(',', $line);
			$elements[1] = addslashes($elements[1]);
			if(count($elements)) $jobs[] = $elements;
		}
	} else {
		die('Logfile $file not found!');
	}
	
	return $jobs;
}

function insert_jobs($jobs)
{
	$sql = "INSERT INTO `temp` (	`username`,
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
	return mysql_error();
}


// First step... truncate the temp table and start fresh
if(truncate_temp())
{
	$logfile = "PCOUNTER.LOG";
	$logpath = "C:\PCOUNTER\DATA\\";
	
	// Second step.. create the new job array
	$jobs = create_job_array($logpath.$logfile);
	
	if(count($jobs))
	{
		// Third step... insert that array into the temp table
		insert_jobs($jobs);
	}
	
	
}


mysql_close($db->conn);

?>