#!c:\strawberry\perl\bin\perl.exe -w

#  Jeff_Wilson@baylor.edu
#  Apr. 7, 2004
#  Revised February 11, 2008 for new server

use DBI;
use Env;

# Orient script to Oracle 10.2 HOME directory
$PATH=q{c:\oracle\oraclient102\bin;C:\Program Files\Oracle\bin};

# Defaults
$input_mode=0;
$config="PCounter.cfg";
$path_to_pcounter=q{C:\Program Files\Pcounter for NT\NT\ACCOUNT.EXE};

# Initialize
$num_records=0;
$total_billed=0;
$total_pcount=0;

# Set date var's from today's date
(undef,$min,$hour,$mday,$mon,$year,undef,undef,undef) = localtime(time);
$mon++;
$year+=1900;
$today_8    = sprintf("%02d%02d%04d",$mon,$mday,$year);
$today_6    = sprintf("%02d%02d%02d",$year%100,$mon,$mday);
$today      = sprintf("%d/%d/%d",$mon,$mday,$year);
$short_date = sprintf("%d/%d/%02d",$mon,$mday,$year % 100);
$mylog_file = sprintf("lockbox_%04d%02d%02d_%02d%02d.log",$year,$mon,$mday,$hour,$min);
$mybill_file= sprintf("bill_%04d%02d%02d_%02d%02d.txt",$year,$mon,$mday,$hour,$min);
$mybatchfile= sprintf("setbal_%04d%02d%02d_%02d%02d.bat",$year,$mon,$mday,$hour,$min);

#  Formats for LOCKBOX billing program
#
#  Record types:  
#    2  Batch header
#    3  Detail
#    4  Batch summary
#
#  These are encoded into the format statements for each record type


###############################################################################
#
#
#     DO NOT MODIFY THESE FORMATS!!!  THESE MATCH THE STRICT REQUIREMENTS
#     OF THE LOCKBOX SCRIPT FOR BANNER.  FUDGING THESE FORMATS WILL CAUSE
#     YOUR BILL TO "BOUNCE" AND YOU DON'T WANT THAT, DO YOU !?!?!
#
#
###############################################################################
# HEADER format
# expects $batch_num, $batch_desc, $date_8char
$header_format="%03d299%-48s%8s\n";
# DETAILED RECORD format
# expects $batch_num, $student_id_num, $detail_desc, $date_6char, $trans_amount*100
$detail_format="%03d3%9s %-33s  %6s+%011d\n";
# SUMMARY format
# expects $batch_num, $number_of_detail_lines, $date_6char, $total_charges*100
$summary_format="%03d4%05d%6s+%011d\n";
###############################################################################

sub ShowHelp {
	@arr=split(/\\/,$0);
	$progname=pop(@arr);
	# Help message for how to use this script
	print "$progname: Generates student bill for PawPrints\n";
	print "Usage: $progname [switches]\n";
	print "\t-a               uses output of ACCOUNT.EXE VIEWBAL BAYLOR as input\n";
	print "\t-f <file_name>   name of data file (from PADMIN.EXE backup)\n";
	print "\t-c <config_file> name of configuration file (default is pcounter.cfg)\n";
	print "\n\tExample: $progname -a\n";
	exit 9;
}

sub LBDie {
	my ($errLevel,$errMessage) = @_;
	printf "%s\n",$errMessage;
#exit $errLevel;
}

if( $#ARGV < 0 ) {
  &ShowHelp();
}

# Process command line arguments
while ( $a = shift(@ARGV) ) {
	if( $a =~ /^[\/\-][Hh\?]/ ) {
	  &ShowHelp();
	} elsif ( $a =~ /^[\/\-]A/i ) {
		$file_name=qq{"$path_to_pcounter" VIEWBAL BAYLOR|};
	} elsif ( $a =~ /^[\/\-]F/i ) {
	  $input_mode++;
		$file_name=shift(@ARGV);
	} elsif ( $a =~ /^[\/\-]C/i ) {
		$config=shift(@ARGV);
	} else {
		&LBDie(9, "Unknown command line switch: $a");
	}
}

open(INFILE,$file_name) ||
	&LBDie(9, "Unable to open $file_name for reading");

open(LBLOG,">$mylog_file") ||
	&LBDie(9, "Unable to open $mylog_file for logging");

# So that 'tail -f $mylog_file' works properly ...
select((select(LBLOG),$|=1)[0]);
	
open(REPORT,">$mybill_file") ||
  &LBDie(9, "Unable to open $mybill_file to create the bill");

# So that 'tail -f $mybill_file' works properly ...
select((select(REPORT),$|=1)[0]);

open(SETBAL,">$mybatchfile") ||
  &LBDie(9, "Unable to open $mybatchfile to create ACCOUNT.EXE DEPOSIT batch script");
	
# So that 'tail -f $mybatchfile' works properly ...
select((select(SETBAL),$|=1)[0]);

print LBLOG "Starting up $today\n";
print LBLOG "Using $file_name for input\n";
print "Using $file_name for input\n";

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

$allset=1;
# Force a value for each config variable
if( !$logdir ) {
  print "logdir not set\n";
  $allset=0;
}
if( !$batch_num ) {
  print "batch_num not set\n";
  $allset=0;
}
if( !$batch_desc ) {
  print "batch_desc not set\n";
  $allset=0;
}
if( !$budb_user  ) {
  print "budb_user not set\n";
  $allset=0;
}
if( !$budb_password  ) {
  print "budb_password not set\n";
  $allset=0;
}
if( !$budb_connect_str  ) {
  print "budb_connect_str not set\n";
  $allset=0;
}
if( !$ppdb_user ) {
  print "ppdb_user not set\n";
  $allset=0;
}
if( !$ppdb_password ) {
  print "ppdb_password not set\n";
  $allset=0;
}
if( !$ppdb_connect_str ) {
  print "ppdb_connect_str not set\n";
  $allset=0;
}
if( !($page_cost>0.0) ) {
  print "page_cost not set\n";
  $allset=0;
}
if( !$detail_desc ) {
  print "detail_desc not set\n";
  $allset=0;
}
if( !$allset ) {
  &LBDie(9, "Please check your $config settings ... unable to proceed");
}
######################
# LOCKBOX_LOG SCHEMA #
######################
#	LB_ROWID NUMBER(7) NOT NULL,
#	LB_BID VARCHAR(50) NOT NULL,
#	LB_IDCARDNUM VARCHAR(9) NOT NULL,
#	LB_PCOUNT NUMBER(5) NOT NULL,
#	LB_AMOUNT NUMBER(6,2) NOT NULL,
# LB_DATE DATE NOT NULL,

# connect to Oracle (using connect string from config file)
$ppdb_handle = DBI->connect( $ppdb_connect_str,
                             $ppdb_user,
	                           $ppdb_password,
	                           # pass in some DB options
	                           {RaiseError => 1, AutoCommit => 0 })
  || &LBDie(8, "PawPrints database connection failed: $DBI::errstr");

$ppdb_statement_handle = $ppdb_handle->prepare_cached(
	q{
		INSERT INTO PAWPRINTS.LOCKBOX_LOG(
			LB_ROWID,LB_BID,LB_IDCARDNUM,LB_PCOUNT,LB_AMOUNT,LB_DATE,LB_DESC)
		VALUES(PAWPRINTS.SEQ_LB_LOG.NEXTVAL,?,?,?,?,SYSDATE,?)
		}
	) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");

$budb_handle = DBI->connect( $budb_connect_str,
                             $budb_user,
	                           $budb_password,
	                           # pass in some DB options
	                           {RaiseError => 1, AutoCommit => 0 })
  || &LBDie(8, "PawPrints database connection failed: $DBI::errstr");
  
$budb_statement_handle = $budb_handle->prepare_cached(
	q{
	 SELECT ID_CARD_NUM,STUDENT_IND,FACULTY_IND,STAFF_IND,AUXILIARY_IND,SPECIAL_IND  
	 FROM PERSON.ID 
	 WHERE (SUBSTR(UPPER(BID), 1, 20) = ?)
	}
) || &LBDie(8, "Failed trying to prepare query: $DBI::errstr");

#print "         1         2         3         4         5         6         7         \n";
#print "1234567890123456789012345678901234567890123456789012345678901234567890123456789\n";
printf REPORT $header_format,$batch_num,$batch_desc,$today_8;

# Read account balance from input source, get BearID and page count
PCOUNT_REC: while(<INFILE>) {
#  print "DEBUG: $_";
  chomp;
  s/BAYLOR\\//og;  # remove BAYLOR\ from the beginning of BearIDs
  if( $input_mode && /ACCOUNT BALANCE/i) {
    # $input_mode==1
    # PADMIN.EXE spits out a Batch script like so:
    # Account balance "Jeff_Wilson" 797
    (undef,undef,$bid,$pcount)=split;
    $bid=~s/"//g;   # yank the quotes (")
  } else {
    # $input_mode==0
    # ACCOUNT.EXE spits out this format:
    # Jeff_Wilson has a balance of 797
    ($bid,undef,undef,undef,undef,$pcount)=split;
  }
  # All BearIDs should have an underscore, so edit out lines without underscore
  next PCOUNT_REC if ($bid !~ /_/);
  # unnecessary?  cast to numeric type
  $pcount+=0;
  # skip page count if it's a positive number
  next PCOUNT_REC if ($pcount >= 0);
  # make the negative number into a positive number
  $pcount = -$pcount;
  $bid=~tr/a-z/A-Z/;    # translate all letters to upper case
  # Execute the look up on the ID_CARD_NUM for this BearID; use eval to catch disruptive errors
  eval {
    $budb_statement_handle->execute($bid)
  };
  # check the eval for $@ to see if errors occurred
  do { &LBDie(2, $budb_statement_handle->err.
                 ": ID_CARD_NUM lookup failed for $bid, $pcount: $@\n"); }
  if ($@ || $budb_statement_handle->err);

  # gather in the data on the query we just executed
  if (defined ( my $id_row_ref = $budb_statement_handle->fetchrow_arrayref() )) {
    ($id_card_num,$stu_ind,$fac_ind,$stf_ind,$aux_ind,$spc_ind) = @{ $id_row_ref };
    # we only want to bill students ... not any staff, faculty, or other
    if(!(defined($id_card_num) &&
         defined($stu_ind) &&
         defined($fac_ind) &&
         defined($stf_ind) &&
         defined($aux_ind) &&
         defined($spc_ind)))
    {
      printf LBLOG "Not billed: %s, %s - status indicators were not defined\n",
                   defined($bid) ? $bid : "undef",
                   defined($pcount) ? $pcount : "undef";
      next PCOUNT_REC;
    }
    if(!($stu_ind =~ m/T/i && 
         $fac_ind =~ m/F/i &&
         $stf_ind =~ m/F/i &&
         $aux_ind =~ m/F/i &&
         $spc_ind =~ m/F/i ) ) {
      print LBLOG "Not billed: $bid,$pcount,S=$stu_ind,Fac=$fac_ind,Stf=$stf_ind,Aux=$aux_ind,Spc=$spc_ind\n";
      next PCOUNT_REC;
    }
    # copy in the string from DATE var-sub'd string
    $ddesc=$detail_desc;
    # variable substitution
    $ddesc=~s/PAGE/$pcount/g;
    # unnecessary?  cast to numeric type
    $amount=0;
    # calculate the amount to charge
    $amount=$pcount*$page_cost;
  	#$ppdb_statement_handle->bind_param(3, $pcount, { TYPE => SQL_INTEGER });		# cast the SQL datatype
  	#$ppdb_statement_handle->bind_param(4, $amount, { TYPE => SQL_INTEGER });
    eval {
      $ppdb_statement_handle->execute($bid,$id_card_num,$pcount,$amount,$ddesc);
    };
    do { print LBLOG "PawPrints insert failed ($bid,$id_card_num,$pcount,$amount,$ddesc): $@\n"; 
         &LBDie(2, $ppdb_statement_handle->err.
                    ": PawPrints insert failed ($bid,$id_card_num,$pcount,$amount,$ddesc): $@\n"); }
    if ($@ || $ppdb_statement_handle->err);
#    do { print LBLOG "PawPrints insert failed ($bid,$id_card_num,$pcount,$amount,$ddesc): $@\n"; last; } if $@;
    printf REPORT $detail_format,$batch_num,$id_card_num,$ddesc,$today_6,$amount*100;  # get rid of the decimal
    print "$bid,$pcount,$amount\n";
    print SETBAL "\@rem $bid,$pcount,$amount\n";
    print SETBAL "\"$path_to_pcounter\" DEPOSIT $bid $pcount \"$setbal_desc\"\n";
    $num_records++;
    $total_billed+=$amount;
    $total_pcount+=$pcount;
  }
  else 
  # not defined id_row_ref
  {
    next PCOUNT_REC if ($bid =~ /GUEST/);
    print LBLOG "Fetch row failed on $bid: $@\n"; 
    &LBDie(2, $budb_statement_handle->err.": Fetch row failed on $bid: $@\n"); 
  }
}
close(INFILE);

# check for rounding errors
if( ($total_pcount*$page_cost*100) != ($total_billed*100) ) {
  printf LBLOG "Rounding error: total_billed adjusted from %s to %s\n", $total_billed, $total_pcount*$page_cost;
  printf "Rounding error: total_billed adjusted from %s to %s\n", $total_billed, $total_pcount*$page_cost;
  $total_billed=$total_pcount*$page_cost;
}

printf REPORT $summary_format,$batch_num,$num_records,$today_6,$total_billed*100;          # get rid of the decimal
#print "         1         2         3         4         5         6         7         \n";
#print "1234567890123456789012345678901234567890123456789012345678901234567890123456789\n";
close(REPORT);

print "Processed $num_records people for a total bill of $total_billed\n";
print LBLOG "Processed $num_records people for a total bill of $total_billed\n";
close(LBLOG);

$ppdb_handle->commit;
$ppdb_handle->disconnect;
$budb_statement_handle->finish;
$budb_handle->disconnect;
