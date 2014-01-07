#
# Travis CI log decorator (maven behaviour):
# Folds successful JUnit tests
# 
# 2014 (c) gark87 
#

use strict;
use warnings;

use constant THRESHOLD => 4;
use constant LENGTH    => 6;

my @last = ();
my $count = 1;
my @states; # (name, handler, needs_end)

sub add_line($) {
  my ($line) = @_;
  push @last, $line;
  if ($#last == THRESHOLD) {
    my $items = $states[0];
    print "travis_fold:start:$items->[0].$count\r\n";
    $items->[2] = 1;
  }
  print shift @last if ($#last > THRESHOLD);
}

sub cleanup() {
  print foreach (@last);
  my $items = $states[0];
  if ($items) {
    if ($items->[2]) {
      print "travis_fold:end:$items->[0].$count\r\n";
      $count++;
    }
    $items->[2] = 0;
  }
  @last = ();
}

sub tests($) {
  my ($_) = @_;
  if (/^Running /o or /Failures: 0, Errors: 0,/o or /^ T E S T S/o or /^-{20}/o or /^\s*$/o) {
    add_line($_);
  } else {
    my $prev = pop @last;
    cleanup();
    print $prev if $prev;
    print $_;
    shift @states if (/^Results :/o);
  }
}

sub building($) {
  my ($_) = @_;
  if (/^\Q[INFO]\E(?! Reactor Summary:)/o or /^Download(ing|ed):/o or /^\d+\/\d+/o) {
    add_line($_);
  } else {
    cleanup();
    print $_;
    shift @states;
  }
}

while(<>) {
  if (/^ T E S T S/o) {
    cleanup();
    unshift @states, ['junit', \&tests, 0]; 
  }
  if (/^\Q[INFO] Building\E/o) {
    cleanup();
    unshift @states, ['building', \&building, 0];
  }
  if ($states[0]) {
    $states[0][1]->($_);
    next;
  }
  print $_;
}

cleanup();

