package Number::Interval;

=head1 NAME

Number::Interval - Implement a representation of a numeric interval

=head1 SYNOPSIS

  use Number::Interval;

  $i = new Number::Interval( Min => -4, Max => 20);
  $i = new Number::Interval( Min => 0 );

  $is = $i->contains( $value );
  $status = $i->intersection( $i2 );

  print "$i";

=head1 DESCRIPTION

Simple class to implement a closed or open interval. Can be used to
compare different intervals, determine set membership, calculate
intersections and provide default stringification methods.

Intervals can be bound or unbound. If C<max> is less than C<min>
the interval is inverted.

=cut

use 5.006;
use strict;
use warnings;
use Carp;
use overload 
  '""' => "stringify",
  'eq' => "equate";

# CVS ID: $Id: Interval.pm,v 1.6 2004/06/15 02:52:57 timj Exp $

use vars qw/ $VERSION /;
$VERSION = '0.01';

=head1 METHODS

=head2 Constructor

=over 4

=item B<new>

Create a new object. Can be populated when supplied with
keys C<Max> and C<Min>.

  $r = new Number::Interval();
  $r = new Number::Interval( Max => 5 );

=cut

sub new {
  my $proto = shift;
  my $class = ref($proto) || $proto;

  my %args = @_;

  my $r = {
	   Min => undef,
	   Max => undef,
	  };

  # Create object
  my $obj = bless $r, $class;

  # Populate it
  $obj->min( $args{Min}) if exists $args{Min};
  $obj->max( $args{Max}) if exists $args{Max};

  return $obj;
}

=back

=head2 Accessors

=over 4

=item B<max>

Return (or set) the upper end of the interval.

  $max = $r->max;
  $r->max(22.0);

C<undef> indicates that the interval has no upper bound.

=cut

sub max {
  my $self = shift;
  if (@_) {
    my $max = shift;
    $self->{Max} = $max;
  }
  return $self->{Max};
}

=item B<min>

Return (or set) the lower end of the interval.

  $min = $r->min;
  $r->min( undef );

C<undef> indicates that the interval has no lower bound.

=cut

sub min {
  my $self = shift;
  $self->{Min} = shift if @_;
  return $self->{Min};
}

=item B<minmax>

Return (or set) the minimum and maximum values of the
interval as an array.

  $r->minmax( 1, 5 );
  @interval = $r->minmax;

Returns reference to an array in a scalar context.

=cut

sub minmax {
  my $self = shift;
  if (@_) {
    $self->min( $_[0] );
    $self->max( $_[1] );
  }
  my @minmax = ( $self->min, $self->max );
  return (wantarray ? @minmax : \@minmax);
}

=item B<minmax_hash>

Return (or set) the minimum and maximum values of the
interval as an hash.

  $r->minmax_hash( min => 1, max => 5 );
  %interval = $r->minmax_hash;

Returns reference to an hash in a scalar context.

C<min> or C<max> can be ommitted. The returned hash
contains C<min> and C<max> keys but only if they
have defined values.

=cut

sub minmax_hash {
  my $self = shift;
  if (@_) {
    my %args = @_;
    $self->min( $args{min} ) if exists $args{min};
    $self->max( $args{max} ) if exists $args{max};
  }

  # Populate the output hash
  my %minmax;
  $minmax{min} = $self->min if defined $self->min;
  $minmax{max} = $self->max if defined $self->max;

  return (wantarray ? %minmax : \%minmax);
}

=back

=head2 General

=over 4

=item B<stringify>

Convert the object into a string representation for display.
Usually called via a stringify overload.

=cut

sub stringify {
  my $self = shift;

  my $min = $self->min;
  my $max = $self->max;

  if (defined $min and defined $max) {
    # Bound
    no warnings 'numeric'; #KLUGE
    if ($max < $min) {
      return "<=$max and >=$min";
    } else {
      return "$min-$max";
    }
  } elsif (defined $min) {
    return ">=$min";
  } elsif (defined $max) {
    return "<=$max";
  } else {
    return "**ERROR**";
  }

}

=item B<isinverted>

Determine whether the interval is inverted. This is true if
both max and min are supplied but max is less than min. For all other
cases (including unbound single-sided intervals) this will return false.

=cut

sub isinverted {
  my $self = shift;
  my $min = $self->min;
  my $max = $self->max;

  if (defined $min and defined $max) {
    return 1 if $min > $max;
  }
  return 0;
}

=item B<isbound>

Returns true if the interval is bound by an upper and lower limit.
An inverted interval would be bounded but inverted.

=cut

sub isbound {
  my $self = shift;
  my $min = $self->min;
  my $max = $self->max;
  if (defined $min and defined $max) {
    return 1;
  } else {
    return 0;
  }
}


=item B<equate>

Compare with another Interval object.
Returns true if they are the same. False otherwise.

=cut

sub equate {
  my $self = shift;
  my $comparison = shift;

  # Need to check that both are objects
  return 0 unless defined $comparison;
  return 0 unless UNIVERSAL::isa($comparison, "Number::Interval");
  no warnings 'numeric'; # KLUGE
  return 0 if $self->min != $comparison->min;
  return 0 if $self->max != $comparison->max;

}

=item B<contains>

Determine whether a supplied value is within the defined intervals.

  $is = $i->contains( $value );

=cut

sub contains {
  my $self = shift;
  my $value = shift;

  my $max = $self->max;
  my $min = $self->min;

  # Assume it doesnt match the interval
  my $contains = 0;
  if ($self->isinverted) {
    # Inverted interval. Both max and min must be defined
    if (defined $max and defined $min) {
      if ($value < $max || $value > $min) {
	$contains = 1;
      }
    } else {
      croak "An interval can not be inverted with only one defined value";
    }

  } else {
    # normal interval
    if (defined $max and defined $min) {
      if ($value < $max && $value > $min) {
	$contains = 1;
      }
    } elsif (defined $max) {
      $contains = 1 if $value < $max;
    } elsif (defined $min) {
      $contains = 1 if $value > $min;
    }

  }

  return $contains;
}


=item B<intersection>

Given another Interval object, modify the existing interval to include
the additional constraints. For example, if the current object
has a interval of -3 to 10, and it is merged with an external object
that has a interval of 0 to 20 then the interval of the current object
will be converted to 0 to 10 since that is consistent with both
intervals.

  $status = $interval->intersection( $newinterval );

Returns true if the intersection was successful.  If the intervals are
incompatible (no intersection) or if no object was supplied returns
false and the object is not modified.

Intersections of an inverted interval with a non-inverted interval
can, in some circumstances, result in an intersection covering
two distinct bound intervals. This class can not yet support multiple
intervals (that would make the intersection method even more of a nightmare)
so the routine dies if such a situation arises.

=cut

# There must be a neater way of implementing this method!
# There may be some edge cases that fail (when one of the
# interval boundaries is identical in both objects)

sub intersection {
  my $self = shift;
  my $new = shift;

  # Check input
  return 0 unless defined $new;
  return 0 unless UNIVERSAL::isa($new,"Number::Interval");

  # Get the values
  my $max1 = $self->max;
  my $min1 = $self->min;
  my $max2 = $new->max;
  my $min2 = $new->min;

  my $inverted1 = $self->isinverted;
  my $inverted2 = $new->isinverted;
  my $inverted = $inverted1 || $inverted2;

  my $bound1 = $self->isbound;
  my $bound2 = $new->isbound;
  my $bound  = $bound1 || $bound2;

  my $outmax;
  my $outmin;

  # There are six possible combinations of Bound interval,
  # inverted interval and unbound interval.

  if ($bound) {
    # Support BB, BU and BI and II

    if ($inverted) {
      # Any inverted: II or BI or IB or UI or IU
      #print "*********** INVERTED *********\n";

      if ($inverted1 && $inverted2) {
	# II
	# This is fairly easy.
	# Always take the smallest max and largest min
	$outmin = ( $min1 > $min2 ? $min1 : $min2);
	$outmax = ( $max1 < $max2 ? $max1 : $max2);

      } else {
	# IB, IU (BI and UI)
	# swap if needed, to have everything as IX
	my $nowbound;
	if ($inverted2) {
	  ($max1,$min1,$max2,$min2) = ($max2,$min2,$max1,$min1);
	  # determine bound state of #1 before losing order information
	  $nowbound = $bound1;
	} else {
	  # #1 is inverted so we need the bound state of #1
	  $nowbound = $bound2;
	}

	if ($nowbound) {
	  # IB
	  # We know that max2 and min2 are defined
	  # We always end up with at least one bound interval
	  if ($min2 < $max1) {
	    $outmin = $min2;

	    # If max2 is too high we get two intervals.
	    croak "This intersection results in two output intervals. Currently not supported" if $max2 > $min1;

	    # Upper limit of interval must be the min of the two maxes
	    $outmax = ( $max1 < $max2 ? $max1 : $max2 );

	  } elsif ($min2 < $min1) {

	    # Make sure we intersect a little
	    # If the bound interval lies outside the inverted interval
	    # return undef
	    if ($max2 >= $min1) {
	      $outmin = $min1;
	      $outmax = $max2;
	    }

	  } elsif ($min2 > $min1) {

	    # This is just the bound interval
	    $outmin = $min2;
	    $outmax = $max2;


	  } else {
	    croak "Oops Bug in interval intersection [6]"
	  }


	} else {
	  # IU
	  if (defined $max2) {

	    # The upper bound must be below the inverted "min"
	    # else we get intersection of two intervals
	    if ($max2 > $min1) {
	      croak "This intersection results in two output intervals. Currently not supported";
	    } elsif ($max2 > $max1) {
	      # Just use the inverted interval
	      $outmax = $max1;
	      $outmin = $min1;
	    } else {
	      # max must be decreased to include min2
	      $outmax = $max2;
	      $outmin = $min1;
	    }


	  } elsif (defined $min2) {

	    # The lower bound must be above the "max"
	    # else we get an intersection of two intervals
	    if ($min2 < $max1) {
	      croak "This intersection results in two output intervals. Currently not supported";
	    } elsif ($min2 < $min1) {
	      # Just use the inverted interval
	      $outmax = $max1;
	      $outmin = $min1;
	    } else {
	      # min must be increased to include min2
	      $outmax = $max1;
	      $outmin = $min2;
	    }

	  } else {
	    croak "This cant happen in Number::Interval[4]";
	  }

	}

      }



    } else {
      # BB, BU or UB
      #print "*********** BOUND NON INVERTED ************\n";
      if ($bound1 and $bound2) {
	# BB
	#print "---------- BB -----------\n";
	$outmin = ( $min1 > $min2 ? $min1 : $min2 );
	$outmax = ( $max1 < $max2 ? $max1 : $max2 );

	# Check that we really are overlapping
	if ($outmax < $outmin) {
	  # oops - intervals did not intersect. Reset
	  $outmin = $outmax = undef;
	}
	

      } else {
	# BU and UB
	#print "---------- BU/UB -----------\n";
	# swap if needed, to have everything as BU
	if ($bound2) {
	  ($max1,$min1,$max2,$min2) = ($max2,$min2,$max1,$min1);
	}

	# unbound is now guaranteed to be (2)
	# Check that unbound max is in interval
	if (defined $max2) {
	  if ($max2 < $max1 && $max2 > $min1) {
	    # inside interval
	    $outmax = $max2;
	    $outmin = $min1;
	  } elsif ($max2 < $min1) {
	    # outside interval. No intersection
	  } elsif ($max2 > $max1) {
	    # below interval. irrelevant
	    $outmax = $max1;
	    $outmin = $min1;
	  } else {
	    croak "Number::Interval - This should not happen[2]";
	  }

	} elsif (defined $min2) {
	  if ($min2 < $max1 && $min2 > $min1) {
	    # inside interval
	    $outmax = $max1;
	    $outmin = $min2;
	  } elsif ($min2 > $max1) {
	    # outside interval. No intersection
	  } elsif ($min2 < $min1) {
	    # below interval. irrelevant
	    $outmax = $max1;
	    $outmin = $min1;
	  } else {
	    croak "Number::Interval - This should not happen[3]";
	  }

	} else {
	  croak "interval intersection: This cant happen (no limit defined)[1]";
	}


      }

    }


  } else {
    # Unbound+Unbound only
    # Three options here. 
    # 1. A max and a max =>  max (same for min and min)
    # 2. max and a min with no overlap => no intersection
    # 3. max and min with overlap => bounded interval
    if (defined $max1 and defined $max2) {
      $outmax = ( $max1 > $max2 ? $max1 : $max2 );
    } else {
      # max and a min - one must be defined for both
      my $refmax = (defined $max1 ? $max1 : $max2);
      my $refmin = (defined $min1 ? $min1 : $min2);

      if ($refmax > $refmin) {
	# normal bound interval
	$outmax = $refmax;
	$outmin = $refmin;
      } else {
	# unbound interval. No intersection
      }


    }

  }


  # Modify object if we have new values
  if (defined $outmax or defined $outmin) {
    $self->max($outmax);
    $self->min($outmin);
    return 1;
  } else {
    return 0;
  }

}

=back

=head1 COPYRIGHT

Copyright (C) 2002-2004 Particle Physics and Astronomy Research Council.
All Rights Reserved.

This program is free software; you can redistribute it and/or modify it under
the terms of the GNU General Public License as published by the Free Software
Foundation; either version 2 of the License, or (at your option) any later
version.

This program is distributed in the hope that it will be useful,but WITHOUT ANY
WARRANTY; without even the implied warranty of MERCHANTABILITY or FITNESS FOR A
PARTICULAR PURPOSE. See the GNU General Public License for more details.

You should have received a copy of the GNU General Public License along with
this program; if not, write to the Free Software Foundation, Inc., 59 Temple
Place,Suite 330, Boston, MA  02111-1307, USA

=head1 AUTHOR

Tim Jenness E<lt>tjenness@cpan.orgE<gt>.

=cut

1;

