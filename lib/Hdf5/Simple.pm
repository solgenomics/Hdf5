
=head1 NAME

Hdf5::Simple - a simple HDF5 interface

=head1 SYNOPSYS

 my $hs = Hdf5::Simple->new( { 
    hdf5_file => $hdf5_file,
    });

 my $rowlistref = $hs->get_row($row_name);
 my $collistref = $hs->get_col($col_name);

=head1 DESCRIPTION

This object can index and query an HDF5 file with a special structure. The data is stored in a "SNPS" dataset (this should be changed to just 'data', actually), whereas a mapping of row headers to row IDs is stored in row_names, and columns in a column_names, dataset.

The object can retrieve either entire rows or entire columns, with the row and column names used as indices.


    
=head1 AUTHOR

Lukas Mueller <lam87@cornell.edu>

=head1 ACCESSORS

=cut


package Hdf5::Simple;

use Moose;

use PDL;
use PDL::IO::HDF5;
use File::Slurp;
use Data::Dumper;


=head1 hdf5_file

accessor for the filename of the hdf5 file. Required when creating the object.

=cut

has 'hdf5_file'     => ( isa => 'Str',
			is => 'rw',
    );

=head1 column_name_index

accessor for a listref of column names. 

Position in the array corresponds to the index in the hdf5 file.

=cut

has 'column_name_index' => ( isa => 'HashRef',
			     is  => 'rw',
    );

=head1 column_pos_index

accessor for listref specifying the column name by position

=cut

has 'column_pos_index'  => ( isa => 'ArrayRef',
			     is  => 'rw',
    );

=head1 row_names

accessor for hashref specifying the position by row name

=cut

has 'row_names'    => ( isa => 'HashRef', 
			is  => 'rw',
    );

=head1 row_name_index

accessor for hashref specifying the position by row name

=cut

has 'row_name_index' => ( isa => 'HashRef',
			  is  => 'rw',
    );

=head1 row_pos_index

accessor for an arrayref specifying the name by position (array index)

=cut

has 'row_pos_index'  => ( isa => 'ArrayRef',
			  is  => 'rw',
    );

=head1 hdf5

accessor for the PDL::IO::HDF5 object that does the heavy lifting. Mostly used internally.

=cut 

has 'hdf5'         => ( isa => 'PDL::IO::HDF5',
			is  => 'rw',
    );

=head1 group

accessor for the hdf5 group to be accessed. Required in the constructor.

Allows to change the group during the existence of the object.

=cut

has 'group'        => ( isa => 'Str',
			is => 'rw',
			default => 'default',
    );

=head1 FUNCTIONS

=cut

sub BUILD { 
    my $self = shift;
        
    if (-e $self->hdf5_file()) { 
	my $h = PDL::IO::HDF5->new($self->hdf5_file());
	$self->hdf5($h);
	$self->build_index_cache($self->group);
    }
    else { 
	print STDERR "File ".$self->hdf5_file()." does not exist. Need to index first\n";
    }
}
    
=head2 index_hdf5

 Usage:        $hs -> index_hdf5($file)
 Desc:         creates the hdf5 file from file $file. File must be a 
               tab delimited text file containing a matrix, with row and 
               column headers.
 Ret:          nothing
 Args:         filename for the file to index
 Side Effects: creates the hdf5 file

=cut

sub index_hdf5 {
    my $self = shift;
    my $file = shift;

    if (-e $self->hdf5_file()) { 
	die "The file ".$self->hdf5_file()." already exists. Please delete before re-indexing.\n";
    }

    print STDERR "Converting file $file to HDF5... ";

    my @lines = read_file($file);

    # create a matrix containing everything
    #
    my @matrix;
    foreach my $l (@lines) { 
     	chomp($l);
     	my @fields = split /\t/, $l;
     	push @matrix, \@fields;
    }

    # create a dataset for the column headers, remove from matrix
    #
    my $column_headers = shift @matrix;
    
    shift(@$column_headers); # remove first element at (0,0)
    my @column_header_matrix = ();
    for(my $i=0; $i<@$column_headers; $i++) { 
     	push @column_header_matrix, [ $column_headers->[$i], $i ] ;	
    }
    
    # create a dataset for the row headers, remove from matrix
    #
    my @row_header_matrix;
    for(my $i=0; $i<@matrix; $i++) { 
	push @row_header_matrix, [ shift(@{$matrix[$i]}), $i ];
    }
    
    my $data_pdl = PDL::Char->new(@matrix); 
    my $col_pdl  = PDL::Char->new(@column_header_matrix);
    my $row_pdl  = PDL::Char->new(@row_header_matrix);

    my $h = PDL::IO::HDF5->new(">".$self->hdf5_file());

    my @groups = $h->groups();

    my $g = $h->group($self->group);

    my $snps = $g->dataset("SNPS");
    my $cols = $g->dataset("column_names");
    my $rows = $g->dataset("row_names");

    $snps -> set($data_pdl);
    $cols -> set($col_pdl);
    $rows -> set($row_pdl); 

    $self->hdf5($h);
		    
    $self->build_index_cache($self->group);
}

=head2 build_index_cache

 Usage:        $hs->build_index_cache
 Desc:         Used internally to build a cache of column and row names
 Ret:          nothing
 Args:
 Side Effects:
 Example:

=cut

sub build_index_cache { 
    my $self = shift;

    my $h = $self->hdf5();
    my $g = $h->group($self->group);
    my $col_dataset =  $g->dataset('column_names');
    my $cols = $col_dataset ->get();

    my %col_names;
    my @col_pos;

    my @col_dims = $cols->dims();
    
    # not sure why there are three dims...
    foreach my $c (0..$col_dims[2]-1) { 
	my $label = $cols->atstr(0, $c);
	my $pos   = $cols->atstr(1, $c);
	$col_names{$label} = $pos;
	push @col_pos, $label;
    }
    
    $self->column_name_index(\%col_names);
    $self->column_pos_index(\@col_pos);
    
    my $row_dataset = $g->dataset('row_names');
    my $rows = $row_dataset->get();
    
    my @row_dims = $rows->dims();
    my %row_names;
    my @row_pos;
    
    foreach my $c (0..$row_dims[2]-1) {
	my $label = $rows->atstr(0, $c);
	my $pos   = $rows->atstr(1, $c);
	#print STDERR "ROWS: LOOKING AT $label, $pos\n";
	$row_names{$label} = $pos;
	push @row_pos, $label;
    }
        
    $self->row_name_index(\%row_names);
    $self->row_pos_index(\@row_pos);
}


sub get { 
    my $self = shift;
    
    my $x = shift;
    my $y = shift;
    my $p = shift;
    my $q = shift;

    my $start = pdl([0, 0]);
    my $end   = pdl([3, 2]);
    #my $stride = pdl([1,1]);
    
    my $h = $self->hdf5();
    
    my $g = $h->group($self->group);
    
    my $dataset = $g->dataset('SNPS');

    my $pdl = $dataset->get($start, $end); #, $stride);
    
    return $pdl;
}
    
=head2 get_row

 Usage:
 Desc:         retrieve an entire row from the hdf5 file
 Args:         a row name
 Ret:          a hash containing the column names and corresponding values

=cut

sub get_row { 
    my $self= shift;
    my $row_name = shift;

    my $hdf = $self->hdf5();

    if (!defined($self->row_name_index()->{$row_name})) { 
	die "ROW NAME $row_name DOES NOT EXIST!\n";
    }
    
    my $g = $hdf->group($self->group);
    my $dataset = $g->dataset('SNPS');
    
    my ($cols, $rows) = $dataset->dims();
    
    my $start = PDL->new(0, $self->row_name_index()->{$row_name});
    my $end   = PDL->new($cols-1, $self->row_name_index()->{$row_name});
    
    my $row = $dataset->get($start, $end);
    
    my $col_index = $self->column_name_index();
    
    # format the result has a hasref
    #
    my %return_data = ();

    my @row_dims = $row->dims();

    my $col_pos = $self->column_pos_index();
    for (my $i=0; $i < $row_dims[1]; $i++) { 
	$return_data{$col_pos->[$i]} = $row->atstr($i);
    }

    return \%return_data;
    
}

=head2 get_col

 Usage:
 Desc:
 Args:
 Ret:

=cut

sub get_col { 
    my $self= shift;
    my $col_name = shift;
    
    if (!defined($self->column_name_index()->{$col_name})) { 
	die "Column $col_name does not exist.";
    }
    
    my $g = $self->hdf5()->group($self->group);
    my $dataset = $g->dataset('SNPS');
    
    my ($cols, $rows) = $dataset->dims();
        
    my $start = PDL->new($self->column_name_index()->{$col_name}, 0);
    my $end   = PDL->new($self->column_name_index()->{$col_name}, $rows-1);
    
    my $col = $dataset->get($start, $end); 
    
    my %return_data = ();
    my @col_dims = $col->dims();

    my $row_pos = $self->row_pos_index();
    for (my $i; $i< $col_dims[2]; $i++) { 
	$return_data{$row_pos->[$i]} = $col->atstr(0, $i);
    }
    
    return \%return_data;
}

sub groups { 
    my $self = shift;
    my @groups = $self->hdf5()->groups();

    return @groups;
}


1;
