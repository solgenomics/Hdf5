
package Hdf5::Simple;

use Moose;

use PDL;
use PDL::IO::HDF5;
use File::Slurp;
use Data::Dumper;

has 'hdf5_file'     => ( isa => 'Str',
			is => 'rw',
    );

has 'column_names' => ( isa => 'Ref',
			is => 'rw',
    );

has 'column_name_index' => ( isa => 'HashRef',
			     is  => 'rw',
    );

has 'column_pos_index'  => ( isa => 'ArrayRef',
			     is  => 'rw',
    );
has 'row_names'    => ( isa => 'HashRef', 
			is  => 'rw',
    );

has 'row_name_index' => ( isa => 'HashRef',
			  is  => 'rw',
    );

has 'row_pos_index'  => ( isa => 'ArrayRef',
			  is  => 'rw',
    );

has 'hdf5'         => ( isa => 'PDL::IO::HDF5',
			is  => 'rw',
    );

has 'group'        => ( isa => 'Str',
			is => 'rw',
			default => 'default',
    );

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
    
    #print STDERR Data::Dumper::Dumper(\@column_header_matrix);

    # create a dataset for the row headers, remove from matrix
    #
    my @row_header_matrix;
    for(my $i=0; $i<@matrix; $i++) { 
	push @row_header_matrix, [ shift(@{$matrix[$i]}), $i ];
    }
    
    my $data_pdl = PDL::Char->new(@matrix); 
    my $col_pdl  = PDL::Char->new(@column_header_matrix);
    my $row_pdl  = PDL::Char->new(@row_header_matrix);

    #print STDERR $data_pdl;
    #print STDERR $col_pdl;
    #print STDERR $row_pdl;

    my $h = PDL::IO::HDF5->new(">".$self->hdf5_file());

    my @groups = $h->groups();
    #print STDERR "Currently there are @groups associated with this database.\n";

    my $g = $h->group($self->group);
    #print STDERR "GROUP NAME: ".$g->nameGet()."\n";
    

    my $snps = $g->dataset("SNPS");
    my $cols = $g->dataset("column_names");
    my $rows = $g->dataset("row_names");

    #print STDERR join "|", $snps->dims(), $cols->dims(), $rows->dims();


    $snps -> set($data_pdl);
    $cols -> set($col_pdl);
    $rows -> set($row_pdl); 


    $self->hdf5($h);
		    
    $self->build_index_cache($self->group);


    #print STDERR "Done.\n";
}


sub build_index_cache { 
    my $self = shift;

    my $h = $self->hdf5();
    my $g = $h->group($self->group);
    my $col_dataset =  $g->dataset('column_names');
    my $cols = $col_dataset ->get();
    # create column name hash
    #
    my %col_names;
    my @col_pos;

    my @col_dims = $cols->dims();
    
    # not sure why there are three dims...
#    print "ROWS, COLS, $col_dims[1], $col_dims[2]\n";
#    print "COLS: $cols\n";
    foreach my $c (0..$col_dims[2]-1) { 
	#print STDERR "LOOKING AT ROW $c\n";
	my $label = $cols->atstr(0, $c);
	my $pos   = $cols->atstr(1, $c);
	$col_names{$label} = $pos;
	push @col_pos, $label;
    }
    
    $self->column_name_index(\%col_names);
    $self->column_pos_index(\@col_pos);
    
    my $row_dataset = $g->dataset('row_names');
    my $rows = $row_dataset->get();
    
    # create row name hash
    #
    #print "ROWS: ".$rows."\n";
    my @row_dims = $rows->dims();
    #print STDERR "COL DIMS: ".(@row_dims)."\n";
    my %row_names;
    my @row_pos;
    
    foreach my $c (0..$row_dims[2]-1) {
	my $label = $rows->atstr(0, $c);
	my $pos   = $rows->atstr(1, $c);
	#print STDERR "ROWS: LOOKING AT $label, $pos\n";
	$row_names{$label} = $pos;
	push @row_pos, $label;
    }
    
#    die "Row name index is : ".(Data::Dumper::Dumper(\%row_hash))."\n";
    
    $self->row_name_index(\%row_names);
    $self->row_pos_index(\@row_pos);
}


sub get { 
    my $self = shift;
    
    my $x = shift;
    my $y = shift;
    my $p = shift;
    my $q = shift;

    #print STDERR "Get: group: ". $self->group. " HDF file: ".$self->hdf5_file()."\n";

    #print STDERR "\n\n\nOpening hdf file...\n";
    my $start = pdl([0, 0]);
    my $end   = pdl([3, 2]);
    #my $stride = pdl([1,1]);
    
    my $h = $self->hdf5();
    
    my $g = $h->group($self->group);
    
    #print STDERR "Retrieve dataset \n";

    my $dataset = $g->dataset('SNPS');

    #print STDERR "NAME: ".$dataset->nameGet()." DIMS: ".join ", ", $dataset->dims(), "\n";
    

    #print STDERR "Retrieve data...\n";
    my $pdl = $dataset->get($start, $end); #, $stride);

    
    
    return $pdl;
}
    


sub get_row { 
    my $self= shift;
    my $row_name = shift;

    my $hdf = $self->hdf5();

    #print STDERR Data::Dumper::Dumper($self->row_name_index());

    if (!defined($self->row_name_index()->{$row_name})) { 
	print STDERR "ROW NAME $row_name DOES NOT EXIST!\n";
	return undef;
    }
    
    my $g = $hdf->group($self->group);
    my $dataset = $g->dataset('SNPS');
    
    my ($cols, $rows) = $dataset->dims();
    
    #print STDERR "$cols, $rows. row name $row_name. Row index ".$self->row_name_index()->{$row_name}."\n";
    
    my $start = PDL->new(0, $self->row_name_index()->{$row_name});
    my $end   = PDL->new($cols-1, $self->row_name_index()->{$row_name});
    
    my $row = $dataset->get($start, $end);
    
    my $col_index = $self->column_name_index();
    
    # format the result has a hasref
    #
    my %return_data = ();
    #print STDERR $row;
    my @row_dims = $row->dims();

    #print Data::Dumper::Dumper(\@row_dims);
    #print STDERR "retrieved row data: ".Data::Dumper::Dumper(\@row_data)."\n";
    my $col_pos = $self->column_pos_index();
    for (my $i=0; $i < $row_dims[1]; $i++) { 
	$return_data{$col_pos->[$i]} = $row->atstr($i);
    }
    #print STDERR "RETURN DATA = ". Data::Dumper::Dumper(\%return_data);
    return \%return_data;
    
}

sub get_col { 
    my $self= shift;
    my $col_name = shift;
    
    if (!defined($self->column_name_index()->{$col_name})) { 
	return undef;
    }
    
    my $g = $self->hdf5()->group($self->group);
    my $dataset = $g->dataset('SNPS');
    
    my ($cols, $rows) = $dataset->dims();
        
    my $start = PDL->new($self->column_name_index()->{$col_name}, 0);
    my $end   = PDL->new($self->column_name_index()->{$col_name}, $rows-1);
    
    my $col = $dataset->get($start, $end); 
    
    #print STDERR "RETRIEVED COL: $col_name\n";
    
 # format the result has a hasref
    #
    my %return_data = ();
    my @col_dims = $col->dims();

    #print Data::Dumper::Dumper(\@col_dims);

    my $row_pos = $self->row_pos_index();
    for (my $i; $i< $col_dims[2]; $i++) { 
	$return_data{$row_pos->[$i]} = $col->atstr(0, $i);
    }
    
    
    return \%return_data;
    
}


1;
