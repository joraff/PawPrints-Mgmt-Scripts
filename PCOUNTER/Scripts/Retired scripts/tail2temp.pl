#!/usr/bin/perl

use File::Tail;

$filename = 'c:\PCOUNTER\DATA\PCOUNTER.LOG';

for( ; ; ) {
  print "Reading logs from $filename";
  eval {
    my $f = File::Tail->new(name=>$filename,interval=>1);
    my $data;
    while (defined($data = $f->read)) {
      print $data
      next unless $data;
    }
  }; # /eval
  warn "Caught exception: $@" if $@;
  # is this file still current?
  sleep 1;
}