package Chart::Gnuplot::Pie;
use strict;
use vars qw($VERSION);
use base 'Chart::Gnuplot';
use Carp;
$VERSION = '0.01';


sub new
{
    my ($self, %opt) = @_;
    my $obj = $self->SUPER::new(%opt);
    $obj->set(
        parametric => '',
        xyplane    => 0,
        urange     => '[0:1]',
        vrange     => '[0:1]',
        xrange     => '[-1:1]',
        yrange     => '[-1:1]',
        cbrange    => '[0:1]',
        size       => 'square',
    );
    $obj->command(join("\n", (
        'unset border',
        'unset tics',
        'unset key',
        'unset colorbox',
    )));
    return($obj);
}


sub plot2d
{
    my ($self, $dataSet) = @_;
    $self->set(
        view   => '0,0',
        zrange => '[0:1]',
    );
    $self->SUPER::plot3d($dataSet);
    return($self);
}


# Plot 3D pie chart
sub plot3d
{
    my ($self, $dataSet) = @_;
    $self->SUPER::_setChart([$dataSet]);
    my $rotate = (defined $self->{rotate})? $self->{rotate} : 0;

    open(CHT, ">>$self->{_script}") || confess("Can't write $self->{_script}");
    print CHT "set zrange [-1:1]\n";
    print CHT "set multiplot\n";

    if (ref $dataSet->{data} eq 'ARRAY')
    {
        my $pt = $dataSet->{data};
        my $sum = 0;
        for (my $i = 0; $i < @$pt; $i++)
        {
            $sum += $$pt[$i][1];
        }

        # Draw boundary around slice
        my $s = my $start = $rotate/360;
        for (my $i = 0; $i < @$pt; $i++)
        {
            # Initial color
            my $r = rand();
            my $g = rand();
            my $b = rand();

            # Draw side surface
            my $e = $$pt[$i][1]/$sum + $s;
            print CHT "set palette model RGB functions ".
                "$r*0.8, $g*0.8, $b*0.8\n";
            print CHT "splot cos(2*pi*(($e-$s)*u+$s)), ".
                "sin(2*pi*(($e-$s)*u+$s)), v*0.1 with pm3d\n";

            # Draw top surface
            print CHT "set palette model RGB functions $r, $g, $b\n";
            print CHT "splot cos(2*pi*(($e-$s)*u+$s))*v, ".
                "sin(2*pi*(($e-$s)*u+$s))*v, 0.1 with pm3d\n";

            # Print label
            my $pos = "cos(($s+$e)*pi)*1.1, sin(($s+$e)*pi)*1.1";
            $pos .= ", 0" if ($s+$e > 1 && $s+$e < 2);
            $pos .= ", 0.1" if ($s+$e < 1 || $s+$e > 2);
            $pos .= " right" if ($s+$e > 0.5 && $s+$e < 1.5);
            $pos .= " front";
            $self->label(
                text     => $$pt[$i][0],
                position => $pos,
            );
            $s = $e;
        }
    }
    print CHT "unset multiplot\n";
    close(CHT);

    $self->SUPER::_execute();
    return($self);
}


1;

##############################################################

package Chart::Gnuplot::Pie::DataSet;
use strict;
use base 'Chart::Gnuplot::DataSet';

sub _thaw
{
    my ($self, $chart) = @_;

    my $string = '';
    my $rotate = (defined $self->{rotate})? $self->{rotate} : 0;

    if (ref $self->{data} eq 'ARRAY')
    {
        my $pt = $self->{data};
        my $sum = 0;
        for (my $i = 0; $i < @$pt; $i++)
        {
            $sum += $$pt[$i][1];
        }

        my $s = my $start = $rotate/360;
        for (my $i = 0; $i < @$pt; $i++)
        {
            my $e = $$pt[$i][1]/$sum + $s;
            $string .= "cos(2*pi*(($e-$s)*u+$s))*v, ".
                "sin(2*pi*(($e-$s)*u+$s))*v, ". ($i+1)/(scalar(@$pt)+1) .
                " with pm3d";
            $string .= ', ' if ($i < $#$pt);

            # Print label
            my $pos = "cos(($s+$e)*pi)*1.1, sin(($s+$e)*pi)*1.1 front";
            $pos .= " right" if ($s+$e > 0.5 && $s+$e < 1.5);
            $chart->label(
                text     => $$pt[$i][0],
                position => $pos,
            );
            $s = $e;
        }

        # Draw boundary around slice
        if (defined $self->{boundary} && $self->{boundary} ne 'off')
        {
            $s = $start;
            for (my $i = 0; $i < @$pt; $i++)
            {
                my $e = $$pt[$i][1]/$sum + $s;
                $string .= ", cos(2*pi*(($e-$s)*u+$s)), ".
                    "sin(2*pi*(($e-$s)*u+$s)), 0 with lines lc \"black\"";
                $string .= ", u*cos(2*pi*$s), u*sin(2*pi*$s), 0 ".
                    "with lines lc \"black\"";
                $s = $e;
            }
        }
    }

    return($string);
}


1;

__END__

=head1 NAME

Chart::Gnuplot::Pie - Plot pie chart using Gnuplot on the fly

=head1 SYNOPSIS

    use Chart::Gnuplot::Pie;

    # Create the pie chart object
    my $chart = Chart::Gnuplot::Pie->new(
        output => "pie.png",
        title  => "Sample Pie",
        ....
    );

    # Data set
    my $dataSet = Chart::Gnuplot::Pie::DataSet->new(
        data => [
            ['Item 1', 7500],
            ['Item 2', 3500],
            ['Item 3', 2000],
            ['Item 4', 4500],
        ],
        ....
    );

    # Plot a 2D pie chart
    $chart->plot2d($dataSet);

    #################################################

    # Plot a 3D pie chart
    $chart->plot3d($dataSet);

=head1 DESCRIPTION

This module provides an interface for plotting pie charts using Gnuplot.
Gnuplot does not have built-in command for pie chart. This module draws the pie
charts using the parametric function plotting feature of Gnuplot, an idea from
Gnuplotter. 

C<Chart::Gnuplot::Pie> is a child class of C<Chart::Gnuplot>. As a result, what
you may do on a C<Chart::Gnuplot> object basically works on a
C<Chart::Gnuplot::Pie> object too, with a few exceptions. Similarly,
C<Chart::Gnuplot::Pie::DataSet> is a child class of C<Chart::Gnuplot::DataSet>.

It should be noted that this module is preliminary. Not many pie charting
options are provided in the current version. Besides, backward compatibility
may not be guaranteed in later versions.

=head1 REQUIREMENT

L<Chart::Gnuplot>

Gnuplot L<http://www.gnuplot.info>

ImageMagick L<http://www.imagemagick.org> (for full feature)

=head1 SEE ALSO

L<Chart::Gnuplot>

Gnuplot tricks: L<http://gnuplot-tricks.blogspot.com>

=head1 AUTHOR

Ka-Wai Mak <kwmak@cpan.org>

=head1 COPYRIGHT

Copyright (c) 2009 Ka-Wai Mak. All rights reserved.

=head1 LICENSE

This library is free software; you can redistribute it and/or modify it under
the same terms as Perl itself.

=cut
