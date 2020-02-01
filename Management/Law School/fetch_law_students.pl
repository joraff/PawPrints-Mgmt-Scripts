#!c:\strawberry\perl\bin\perl.exe -w

#  Joseph_Rafferty@baylor.edu
#  Jeff_Wilson@baylor.edu
#  Apr. 7, 2004
#  Revised February 11, 2008 for new server
#  Revised May 3, 2011 for another new server (changed paths)
#  Revised May 4, 2011 to exclude law students from billing

use DBI;
use Env;

# Orient script to Oracle 10.2 HOME directory
$PATH=q{c:\oracle\oraclient102\bin;C:\Program Files\Oracle\bin};

# Defaults
$input_mode=0;
$config=q{c:\adminresources\billing\PCounter.cfg};

open(CFG,$config) ||
	&LBDie(9,"Unable to open $config");

while(<CFG>) {
	chomp;
	next if /^#/;			# skip comments
	next if /^$/;			# skip empty lines
	($var,$val)=split(/=/);
	if( $var =~ /logdir/i ) {
		$logdir=$val;
	} elsif ( $var =~ /batch_num/i ) {
		$batch_num=$val;
	} elsif ( $var =~ /batch_desc/i ) {
		$batch_desc=$val;
		# Variable substitution
		$batch_desc=~s/DATE/$short_date/og;
	} elsif ( $var =~ /detail_desc/i ) {
		$detail_desc=$val;
		# Variable substitution
		$detail_desc=~s/DATE/$short_date/og;
	} elsif ( $var =~ /budb_user/i ) {
		$budb_user=$val;
	} elsif ( $var =~ /budb_password/i ) {
		$budb_password=$val;
	} elsif ( $var =~ /budb_connect_str/i ) {
		$budb_connect_str=$val;
	} elsif ( $var =~ /ppdb_user/i ) {
		$ppdb_user=$val;
	} elsif ( $var =~ /ppdb_password/i ) {
		$ppdb_password=$val;
	} elsif ( $var =~ /ppdb_connect_str/i ) {
		$ppdb_connect_str=$val;
	} elsif ( $var =~ /page_cost/i ) {
		$page_cost=$val;
		# cast to numeric
		$page_cost+=0;
	} elsif( $var =~ /setbal_desc/i ) {
		$setbal_desc=$val;
		# Variable substitution
		$setbal_desc=~s/DATE/$today/og;
	}
}
close(CFG);

$budb_handle = DBI->connect( $budb_connect_str,
                             $budb_user,
	                           $budb_password,
	                           # pass in some DB options
	                           {RaiseError => 1, AutoCommit => 0 })
  || &LBDie(8, "PawPrints database connection failed: $DBI::errstr");

$law_statement_handle = $budb_handle->prepare_cached(
	q{
	 SELECT BID   
	 FROM PERSON.ID
	 INNER JOIN PERSON.STUDENT
	 ON PERSON.STUDENT.PID = PERSON.ID.PID
	 WHERE (PERSON.STUDENT.STATUS = 'L')
	}
) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");

eval {
		$law_statement_handle->execute()
	};
	# check the eval for $@ to see if errors occurred
	
	
	my @data;
	while (@data = $law_statement_handle->fetchrow_array()) {
            my $bid = $data[0];
            print "\t$bid\n";
          }