package Hdf5::Controller::Root;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller' }

#
# Sets the actions in this controller to be registered with no prefix
# so they function identically to actions created in MyApp.pm
#
__PACKAGE__->config(namespace => '');

=head1 NAME

Hdf5::Controller::Root - Root Controller for Hdf5

=head1 DESCRIPTION

[enter your description here]

=head1 METHODS

=head2 index

The root page (/)

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    # Hello World
    $c->response->body(<<BODY);
<h1>Mueller Lab HDF5 Server</h1>

This server supports two types of queries: 
<dl>
<dt>/hdf5/get/row/DATASET/ROWNAME</dt>
<dd>get the entire row named ROWNAME from dataset DATASET</dd>
<br />
<dt>/hdf5/get/col/DATASET/COLNAME</dt>
<dd>get the entire column named COLNAME from dataset DATASET</dd>
<br />
The data are returned in a JSON data structure of the following form:
data = { 
  query: querydata,
  response: responsedata
};


BODY
	
}

=head2 default

Standard 404 error page

=cut

sub default :Path {
    my ( $self, $c ) = @_;
    $c->response->body( 'Page not found' );
    $c->response->status(404);
}

=head2 end

Attempt to render a view, if needed.

=cut

sub end : ActionClass('RenderView') {}

=head1 AUTHOR

Lukas Mueller,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
