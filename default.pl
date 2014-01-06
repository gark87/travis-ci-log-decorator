#
# Travis CI log decorator (Default behaviour):
# Fold every THRESHOLD lines that starts with the same LENGTH symbols
# 
# 2014 (c) gark87 
#

use strict;
use warnings;

use constant THRESHOLD => 4;
use constant LENGTH    => 6;

my @last = ();
my $prefix = 'gark87';
my $name;
my $count = 1;

sub cleanup() {
  print foreach (@last); 
  if ($#last == THRESHOLD) {
    print "travis_fold:end:$name.$count\r\n";
    $count++;
  }
  @last = ();
}

while(<>) {
  my $no_color = $_;
  $no_color =~ s/\e(\[[0-9]*[mK]|M)//g;
  $no_color =~ s/^\s+//g;
  my $current_prefix = substr $no_color, 0, LENGTH;
  if ($current_prefix eq $prefix) {
    push @last, $_;
    print "travis_fold:start:$name.$count\r\n" if ($#last == THRESHOLD);
    print shift @last if ($#last > THRESHOLD);
  } else {
    cleanup();
    $prefix = $current_prefix;
    $name = $prefix;
    $name =~ s/\W+//g;
    push @last, $_;
  } 
}

cleanup();

