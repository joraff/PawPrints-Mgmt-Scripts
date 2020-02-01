<?php

require_once 'historydb.class.php';
$db = new historydb;

function tailme($file)
{
	// Number of jobs to look back for duplicates or gaps
	$backwards = 50;
	
	// Max ID of jobs in the temp table currently
	$upper = mysql_num_rows(mysql_query("SELECT id FROM temp"));
	$lower = ($upper-$backwards)+1;
	
	$prevjobs = array();
	$hashes = array();
	$result = mysql_query("SELECT * FROM temp WHERE id BETWEEN $lower and $upper");
	
	while($temp = mysql_fetch_assoc($result))
	{
		foreach($temp as $key=>$value) {
			$temp[$key] = stripslashes($value);
		}
		$hash = md5($temp['username'].$temp['docname'].$temp['printer'].$temp['optstring'].$temp['size']);
		$hashes[] = $hash;
		$temp['hash'] = $hash . "\n";
		$prevjobs[] = $temp;
	} 
	
	
	
	print "Following PCOUNTER.LOG\n";
	
	for ( ; ; )
	{
		$counter=1;
		
		$tail = popen('c:\unxutils\tail -'.$backwards.'f '.$file, 'r');
		echo 'c:\unxutils\tail -'.$backwards.'f '.$file;
		if(!$tail)
		stream_set_blocking($tail, 1);
		while($tail)
		{
			
			$line = fgets($tail);
			if(strlen($line))
			{
				$elements = explode(',', $line);
				$elements[1] = addslashes($elements[1]);
				
				if($counter<=$backwards)
				{
					$hash = md5( str_replace('BAYLOR\\','',$elements[0]).$elements[1].str_replace('\\\\GUS\\','',$elements[2]).$elements[9].$elements[10] );
					echo $hash . "\n";
					if(!in_array($hash, $hashes))
					{
						echo "$counter: NOT IN HASH!! INSERTING!! at ".date("h:i:s")."\n";
						
						$sql = "INSERT INTO `temp` (`username`,
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
						
						$sql .= "(	'".str_replace('BAYLOR\\','',$elements[0])."',
									'".$elements[1]."',
									'".str_replace('\\\\GUS\\','',$elements[2])."',
									'".date('Y-m-d H:i:s', mktime(substr($elements[4],0,2),substr($elements[4],3,2),0,substr($elements[3],0,2),substr($elements[3],3,2),substr($elements[3],6,4)))."',
									'".substr($elements[5],2)."',
									'".$elements[6]."',
									'".$elements[7]."',
									'".$elements[8]."',
									'".$elements[9]."',
									'".$elements[10]."',
									'".$elements[11]."',
									'".$elements[12]."',
									'".trim($elements[13])."')";
									
						//echo $sql . "\n";
						//mysql_query($sql);
						//$error = mysql_error($db);
						//if(strlen($error)) echo "problem: $error\n";
						//else echo "Inserted line\n";
					} else {
						echo "Row exists!! not inserting\n";
					}
				}
				
				//print_r($elements);
				$counter++;
			}
			if(!$tail) pclose($tail);
		}
	}
	
	mysql_close();
}

tailme('C:\PCOUNTER\DATA\PCOUNTER.LOG');

?>