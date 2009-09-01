use warnings;
use strict;
use Test::More (tests => 1);

BEGIN {use Chart::Gnuplot::Pie;}

my $temp = "temp.ps";

# Test default setting of title
{
    my $c = Chart::Gnuplot::Pie->new(
        output => $temp,
        title  => 'Testing title',
    );
    ok(ref($c) eq 'Chart::Gnuplot::Pie');
}
