#!/usr/bin/perl

use File::Tail;
use DBI;

$dsn = "dbi:mysqlPP:database=test;host=gus";

    $dbh = DBI->connect($dsn, 'test', 'test');

    $drh = DBI->install_driver("mysqlPP");

    $sth = $dbh->prepare("SELECT * FROM test");
    $sth->execute;
    $numRows = $sth->rows;
    $numFields = $sth->{'NUM_OF_FIELDS'};
    $sth->finish;

	print "numFields: $numFields\n"
  #$file=File::Tail->new(name=>"/var/log/system.log", interval=>0, maxinterval=>5);
  #while (defined($line=$file->read)) {
  #    print "$line";
  #}