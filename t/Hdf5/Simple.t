
use strict;

use lib 'lib/';
use Test::More;
use Data::Dumper;
use Hdf5::Simple;
use File::Slurp;
my $test_hdf_file = 't/test_hdf.hdf';

my $test_file = 't/test_file.txt'; #'/home/mueller/snp_max_project/test_snp_file3.txt';

my $test_group = 'test';

print STDERR "Removing prior hdf_file $test_hdf_file...\n";
unlink $test_hdf_file;

my $h = Hdf5::Simple->new( { hdf5_file => $test_hdf_file, group=>'test' });
$h->index_hdf5($test_file);

my $cni = $h->column_name_index();
my $cpi = $h->column_pos_index();

print "Column Name Index:". Data::Dumper::Dumper($cni)."\n";

print "Column Pos Index: ".Data::Dumper::Dumper($cpi)."\n";

my $rni = $h->row_name_index();
my $rpi = $h->row_pos_index();

print "Row name Index: ".Data::Dumper::Dumper($rni)."\n";
print "Row Pos Index: ". Data::Dumper::Dumper($rpi)."\n";


my $r = $h->get_row('XF');

print "row xf:\n";
foreach my $k (keys %$r) { 
    print "$k, $r->{$k}\n";
}

print "col 'B'\n";
my $c = $h->get_column('B');
foreach my $k (keys %$c) { 
    print "$k, $c->{$k}\n";
}



# my $pdl = $h->get(1,1,1,2);


# my ($a, $b, $c) = $pdl->dog();

# my @b = $b->dog();

# print join ", ", @b;

# $h->build_index_cache();

# print Data::Dumper::Dumper($h->row_names);

# print Data::Dumper::Dumper($h->column_names);

# my $x = $pdl->sclr;

# print "scalar form of x: ". Data::Dumper::Dumper($x);
