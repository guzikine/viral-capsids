# This is a package that contains functions
# for operations with matrices and coordinates.
# This package is used from inside the main
# perl executable file inside this directory.

package operations;

use strict;
use warnings;

# This function updates the global max and min
# variables.
sub get_max_min( $$$ ) {
	my ( $max_ref, $min_ref, $coord_ref ) = @_;
	my @max = @{$max_ref};
	my @min = @{$min_ref};
	my @coordinates = @{$coord_ref};
	
	my $is_defined = defined($max[0]) ? 1 : 0;
	
	for my $i ( 0..2 ) {
		if ( $is_defined ) {
			if ( $coordinates[$i] > $max[$i] ) {
				$max[$i] = $coordinates[$i];
			}
			
			if ( $coordinates[$i] < $min[$i] ) {
				$min[$i] = $coordinates[$i];
			}
		}
		else {
			$max[$i] = $coordinates[$i];
			$min[$i] = $coordinates[$i];
		}
	}
	
	return ( \@max, \@min );
}

# Checks whether the matrix is identity.
sub is_identity_matrix( \@ ) {
	my @matrix = @{$_[0]};
	for (my $i = 0; $i < 3; $i++) {
    		for (my $j = 0; $j < 3; $j++) {
      			if ($i == $j) {
        			# Diagonal element
        			if ($matrix[$i][$j] != 1) {
          				return 0;
        			}
      			} 
      			else {
        			if ($matrix[$i][$j] != 0) {
          				return 0;
        			}
      			}
    		}
	}
	return 1;
}

# This function converts the matrix intervals
# presented in the CIF files into number arrays
# that can be used to iterate and use specific
# matrices.
sub get_matrix_intervals( \@ ) {
	my @matrix_intervals = @{$_[0]};
	my @processed_indices = ();
	
	foreach my $i ( @matrix_intervals ) {
		if ( $i =~ /^\d+$/ ) {
			my @temp = ($i);
			push @processed_indices, \@temp;
		}
		elsif ( $i =~ /\d+-\d+/ ) {
			my @interval = $i =~ /(\d+)-(\d+)/g;
			my @temp = map { $_ } $1..$2;
			push @processed_indices, \@temp;
		}
		else {
			my @temp = split(',', $i);
			push @processed_indices, \@temp;
		}
	}
	return @processed_indices;
}

# This function multiplies 3D vector by a 3x3 matrix
# and applies the translation to get the new coordinates.
sub matrix_translation_transformation( $$ ) {
	my ( $matrix_ref, $coordinates ) = @_;
	my @matrix = @{$matrix_ref};
	# Coordinates (x, y, z).
	my @coordinates = @{$coordinates};
	my @new_coordinates = ( 0, 0, 0 );
	
	for ( my $i = 0; $i < 3; $i++ ) {
		for ( my $j = 0; $j < 3; $j++ ) {
			$new_coordinates[$i] += 
				$matrix[$i][$j] * $coordinates[$j];
		}
		$new_coordinates[$i] += 
			$matrix[$i][3];
	}
	
	return \@new_coordinates;
}

# This function iterates through matrices just like
# defined in the instruction of the CIF file and uses
# them by multiplication to get new matrices. 
sub matrix_iteration {
	my ( $interval_ref, 
	     $value_ref, 
	     $matrix_ref,
	     $global_max_ref,
	     $global_min_ref, 
	     $cycles_remaining,
	     $write_handle ) = @_;
	
	my @current_interval = 
		@{$interval_ref->[-$cycles_remaining]};
	my @coordinates = @{$value_ref}[10..12];
	
	if ( $cycles_remaining != 0 ) {
		foreach my $i ( @current_interval ) {
			my $new_coord_ref = 
				matrix_translation_transformation( 
					$matrix_ref->{$i},
					\@coordinates );
			
			my @new_value = @{$value_ref};
			for ( my $j = 10; $j < 13; $j++ ) {
				$new_value[$j] = 
					$new_coord_ref->[$j-10];
			}
			
			( $global_max_ref, $global_min_ref ) = 
				matrix_iteration( 
					$interval_ref,
					\@new_value,
					$matrix_ref,
					$global_max_ref,
					$global_min_ref,
					$cycles_remaining - 1,
					$write_handle );
		}

	}
	else {
		( $global_max_ref, $global_min_ref ) = 
			get_max_min( 
				$global_max_ref, 
				$global_min_ref, 
				\@coordinates );
		my $string = join( ",", @{$value_ref} );
		print $write_handle "$string\n";
	}

	return ( $global_max_ref, $global_min_ref );
}

sub calculate_volume( $$ ) {
	# Coordinates (x, y, z).
	my ( $max, $min ) = @_;
	my @max_vals = @{$max};
	my @min_vals = @{$min};
	
	my $x = sqrt(($max_vals[0] - $min_vals[0]) ** 2);
	my $y = sqrt(($max_vals[1] - $min_vals[1]) ** 2);
	my $z = sqrt(($max_vals[2] - $min_vals[2]) ** 2);
	
	my $volume = $x * $y * $z;
	
	return $volume;
}

1;
