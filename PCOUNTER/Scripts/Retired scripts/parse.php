<?

// PHP Script to parse the PCOUNTER.log files and get per-printer history.
// 2008 Baylor University, Joseph Rafferty

list($usec, $sec) = explode(' ', microtime());
$script_start = (float) $sec + (float) $usec;

$start_date = "September 1, 2008";
$end_date = "September 30, 2008";

$printers = array(	
					"\\\\GUS\BDSCDenA_1sided",
					"\\\\GUS\BDSCDenA_2sided",
					"\\\\GUS\BDSCDenB_1sided",
					"\\\\GUS\BDSCDenB_2sided"
			);
$pages = 0;

for ($x=strtotime($start_date);$x<=strtotime($end_date);$x=$x+86400) {
	$filename = "PCOUNTER_".date('Y_md',$x).".LOG";
	echo "Processing $filename\n";
	if (file_exists($filename)) {
		$contents = file_get_contents($filename);
		$lines = explode("\n", trim($contents));
		$num = count($lines);
		foreach($lines as $line) {
			$elements = explode(',', $line);
			if (in_array($elements[2], $printers)) {
				print_r($elements);
				$pages += $elements[11];
				if($elements[11] != $elements[12]) echo "Difference!\n";
			}
		}
	}
}		


echo "\n\nTotal Pages: $pages\n";

list($usec, $sec) = explode(' ', microtime());
$script_end = (float) $sec + (float) $usec;

echo "Time Elapsed: ".round($script_end - $script_start, 3)." seconds\n";
?>