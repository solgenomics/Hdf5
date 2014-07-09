use Module::Build;

my $build = Module::Build->new(
    module_name        => 'Hdf5',
    license            => 'mit',
    create_makefile_pl => 'passthrough',
    dist_abstract      => '',
    add_to_cleanup     => [ ],
    dist_version  => '0.1',
    dist_author   => 'Lukas Mueller',
    dist_abstract => 'Hdf5 server for genotype data',




    meta_merge           => {
        resources =>
	{ repository => 'http://github.com/solgenomics/Hdf5', },
    },

    # and now the list of perl module dependencies
    requires           => {
     'perl'         => '5.10.0',
     'Carp'         => 0,
     'Socket'       => 0,
     'Moose'        => 0,
     'PDL'          => 0,
     'Data::Dumper' => 0,
     'File::Slurp'  => 0,
     'Catalyst'     => 0,
     'Catalyst::Plugin::Static::Simple' => 0,
     'Catalyst::Plugin::ConfigLoader' => 0,
     'Catalyst::Controller::REST' => 0,
     'Catalyst::Restarter' => 0,
     'Config::General' => 0,
     'PDL::IO::HDF5::Dataset' => 0,
    },
    build_requires => {
        'Test::More'      => 0,
	'YAML::Syck'      => 0,
    },
    
    );
$build->create_build_script;



