#!/usr/bin/perl -w

use strict;

my($REPLACEWITH_FILE)=$ARGV[0];
my($TEMPLATE_FILE)=$ARGV[1];
my($REPLACE_STRING)=$ARGV[2];

if(!$REPLACEWITH_FILE || !$TEMPLATE_FILE || !$REPLACE_STRING) {
  print STDERR "Bad parameters\n";
  exit 1;
}

open(my $fh, "<$REPLACEWITH_FILE") || die "Couldn't open $REPLACEWITH_FILE";
$_=<$fh>;
chop;
my($replaceWithString)=$_;
close $fh;

open($fh, "<$TEMPLATE_FILE") || die "Couldn't open $TEMPLATE_FILE";
while(<$fh>) {
  s/$REPLACE_STRING/$replaceWithString/g;
  print;
}
close($fh);
