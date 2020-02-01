#!c:\Perl\bin\perl.exe -w

#  Jeff_Wilson@baylor.edu
#  Apr. 7, 2004
#  Revised February 11, 2008 for new server

use DBI;
use Env;

$PATH=q{c:\oracle\oraclient102\bin;C:\Program Files\Oracle\bin};

$budb_handle = DBI->connect( "dbi:Oracle:budb",
							 "pdbuser",
							 "budb",
							   # pass in some DB options
							   {RaiseError => 1, AutoCommit => 0 })
  || &LBDie(8, "PawPrints database connection failed: $DBI::errstr");
  

$budb_statement_handle = $budb_handle->prepare_cached(
	q{
	 SELECT BID  
	 FROM PERSON.ID 
	 WHERE (ID_CARD_NUM = ?)
	}
) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");

$ids = "ids.txt";
open(IDS,$ids) or die("Could not open txt file.");

foreach $line (<IDS>) {
	chomp($line);
	$budb_statement_handle->execute($line) . "\n";
	if (defined ( my $id_row_ref = $budb_statement_handle->fetchrow_arrayref() )) {
	($bid) = @{ $id_row_ref };
		print $bid . "\n";
	}
}