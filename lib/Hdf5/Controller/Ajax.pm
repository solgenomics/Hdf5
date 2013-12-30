
package Hdf5::Controller::Ajax;

use Moose;

BEGIN { extends 'Catalyst::Controller::REST'; }

__PACKAGE__->config(
    default   => 'application/json',
    stash_key => 'rest',
    map       => { 'application/json' => 'JSON', 'text/html' => 'JSON' },
   );


use File::Slurp;
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

sub index : Path('/hdf5/index') Args(1) {
    my ($self, $c, $group) = @_;
    
    my $hdf = Hdf5::Simple->new( { hdf5_file => $c->config->{hdf5_file}, group=>$group, });
    
    $hdf->index_hdf5($self->data_file());
    
    $c->stash->{rest} = [ 1 ];
    
}


sub get : Path('/hdf5/get') Args(3) { 
    my $self = shift;
    my $c = shift;
    my $dimension = shift;
    my $name   = shift;
    my $group = shift;
    
    print STDERR "HDF5_FILE: ".$c->config->{hdf5_file}." GROUP: $group. MAME: $name.\n";

    my $hs = Hdf5::Simple->new( { hdf5_file=>$c->config->{hdf5_file}, group=>$group, });
    
    my $hashref;
    if ($dimension eq "row") { 
	$hashref = $hs->get_row($name);
    }
    elsif ($dimension eq "col") { 
	$hashref = $hs->get_col($name);
    }
    else { 
	die "Invalid dimension $dimension. Should either be 'row' or 'col'.\n";
    }

    $c->stash->{rest} = { query=>$name, response=>$hashref } ;
    
}

sub groups : Path('/hdf5/groups') Args(0) { 
    my $self = shift;
    my $c = shift;

    my $hs = Hdf5::Simple->new( { hdf5_file=>$c->config->{hdf5_file} });
    my @groups = $hs->groups();

    

    
}    



1;
