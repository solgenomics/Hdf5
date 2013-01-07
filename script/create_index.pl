
use lib 'lib/';
use strict;

use Hdf5::Simple;

my $file = shift || die "need file name to index\n";
my $hdf_file = shift || die "need hdf_file (2nd parameter)\n";
my $group = shift || 'default';

my $hdf = Hdf5::Simple->new({ hdf5_file => $hdf_file });

print STDERR "Start indexing. File: $file. Group: $group. HDF file: $hdf_file\n ";

$hdf->index_hdf5($file, $group);

print STDERR "Done.\n";
