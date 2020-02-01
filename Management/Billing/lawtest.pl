use DBI;
use Env;

# Orient script to Oracle 10.2 HOME directory
$PATH=q{c:\oracle\oraclient102\bin;C:\Program Files\Oracle\bin};

$budb_handle = DBI->connect( 'dbi:Oracle:budb',
                             'pdbuser',
	                           'budb',
	                           # pass in some DB options
	                           {RaiseError => 1, AutoCommit => 0 })
  || &LBDie(8, "PawPrints database connection failed: $DBI::errstr");
  
$budb_statement_handle = $budb_handle->prepare_cached(
	q{
	 SELECT PID,ID_CARD_NUM,STUDENT_IND,FACULTY_IND,STAFF_IND,AUXILIARY_IND,SPECIAL_IND  
	 FROM PERSON.ID 
	 WHERE (SUBSTR(UPPER(BID), 1, 20) = ?)
	}
) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");

$law_statement_handle = $budb_handle->prepare_cached(
	q{
	 SELECT STATUS  
	 FROM PERSON.STUDENT 
	 WHERE (PID = ?)
	}
) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");


eval {
  $budb_statement_handle->execute(uc "Alex_Knapp")
};
# check the eval for $@ to see if errors occurred
do { &LBDie(2, $budb_statement_handle->err.
               ": ID_CARD_NUM lookup failed for <username> $@\n"); }
if ($@ || $budb_statement_handle->err);

if (defined ( my $id_row_ref = $budb_statement_handle->fetchrow_arrayref() )) {
    ($pid,$id_card_num,$stu_ind,$fac_ind,$stf_ind,$aux_ind,$spc_ind) = @{ $id_row_ref };
	
	eval {
		$law_statement_handle->execute($pid)
	};
	# check the eval for $@ to see if errors occurred
	do { &LBDie(2, $law_statement_handle->err.
                 ": LAW STATUS lookup failed for <username> $@\n"); }
	if ($@ || $law_statement_handle->err);
	
	if (defined ( my $id_row_ref = $law_statement_handle->fetchrow_arrayref() )) {
		($stat) = @{ $id_row_ref };
		print "status = $stat";
	}
}

