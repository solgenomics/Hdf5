
package Hdf5::Controller::Ajax;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );


use File::Slurp;
use File::Basename;
use File::LibMagic;
use PDL::IO::HDF5;
use Hdf5::Simple;

has data_file => ( isa => 'Str',
		   is  => 'rw',
    );

has hdf5_file  => ( isa => 'Str',
		   is  => 'rw',
    );

has chunked   => ( isa => 'bool',
		   is  => 'rw',

    );

# need to password protect this url:
#
sub index : Path('/hdf5/index') Args(1) {
    my ($self, $c, $file) = @_;
    
    my $hdf = Hdf5::Simple->new( { hdf5_file => $c->config->{hdf5_path}."/$file", });
    
    $hdf->index_hdf5($self->data_file());
    
    $c->stash->{rest} = [ 1 ];
    
}

=head2 get

 Usage:        /hdf5/get/<row|col>/<file>/<name>
 Desc:         
 Ret:          json
 Args:
 Side Effects:
 Example:

=cut

sub get : Path('/hdf5/get') Args(3) { 
    my $self = shift;
    my $c = shift;
    my $dimension = shift;
    my $file = shift;
    my $name   = shift;
#    my $group = shift;
    
    
    print STDERR "HDF5_FILE: ".$c->config->{hdf5_path}."/".$file." MAME: $name.\n";

    my $path = $c->config->{hdf5_path}."/".$file;
    if (!$self->check_file($path)) { 
	$c->stash->{rest} = { error => "The dataset does not exist or is not of the right type." };
	return;
    }

    my $hs = Hdf5::Simple->new( { hdf5_file=>$c->config->{hdf5_path}."/$file" });
    
    my $hashref;
    if ($dimension eq "row") { 
	eval { 
	    $hashref = $hs->get_row($name);
	};
	if ($@) { 
	    $c->stash->{rest} = { error => "The row '$name' does not exist." };
	    return;
	}
    }
    elsif ($dimension eq "col") { 
	eval { 
	    $hashref = $hs->get_col($name);
	};
	if ($@) { 
	    $c->stash->{rest} = { error => "The column '$name' does not exist." };
	    return;
	}

    }
    else { 
	die "Invalid dimension $dimension. Should either be 'row' or 'col'.\n";
    }

    $c->stash->{rest} = { query=>$name, data=>$hashref } ;
    
}

=head2 files

 Usage:        /hdf5/files
 Desc:         list all the available files. 
               They must be in the hdf5_path dir.
 Ret:          json with key=files, and a list of files.
 Args:         none
 Side Effects:
 Example:

=cut

sub datasets : Path('/hdf5/datasets') Args(0) { 
    my $self = shift;
    my $c = shift;
    
    my @files = glob $c->config->{hdf5_path}."/*";

    my @basenames = map { basename $_; } @files;

    print STDERR "FILES : ".join (", ", @basenames);

    $c->stash->{rest} = { datasets => \@basenames};

}

sub check_file { 
    my $self = shift;
    my $file = shift;

    if ($file =~ m/\.\./) { return 0; }
    
    if ($file =~ m/\;/) { return 0; }
    
    my $type = File::LibMagic->new()->describe_filename($file);

    if ($type =~ m/Hierarchical Data Format \(version 5\)/) { 
	
	return 1;
    }
    
    return 0;

    
    
}

1;
