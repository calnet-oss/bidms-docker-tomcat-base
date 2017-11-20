#!/usr/bin/perl -w

use strict;

my($REPLACEWITH_FILE)=$ARGV[0];
my($TEMPLATE_FILE)=$ARGV[1];
my($REPLACE_STRING)=$ARGV[2];

if(!$REPLACEWITH_FILE || !$TEMPLATE_FILE || !$REPLACE_STRING) {
  print STDERR "Bad parameters\n";
  exit 1;
}

my $fh;

if($REPLACEWITH_FILE ne "-") {
  open($fh, "<$REPLACEWITH_FILE") || die "Couldn't open $REPLACEWITH_FILE";
}
else {
  $fh = \*STDIN;
}
$ _ = <$fh>;
chop;
my($replaceWithString) = $_;
if($REPLACEWITH_FILE ne "-") {
  close $fh;
}

open($fh, "<$TEMPLATE_FILE") || die "Couldn't open $TEMPLATE_FILE";
while(<$fh>) {
  s/$REPLACE_STRING/$replaceWithString/g;
  print;
}
close($fh);
