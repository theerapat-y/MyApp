package MyApp::Controller::Login;
use Moose;
use namespace::autoclean;

BEGIN { extends 'Catalyst::Controller'; }

=head1 NAME

MyApp::Controller::Login - Catalyst Controller

=head1 DESCRIPTION

Catalyst Controller.

=head1 METHODS

=cut


=head2 index

=cut

sub index :Path :Args(0) {
    my ( $self, $c ) = @_;

    $c->response->body('Matched MyApp::Controller::Login in Login.');
}

=head2 index
 
Login logic
 
=cut
 
sub index :Path :Args(0) {
    my ($self, $c) = @_;
 
    # Get the username and password from form
    my $username = $c->request->params->{username};
    my $password = $c->request->params->{password};
 
    # If the username and password values were found in form
    if($c->request->method ne 'GET')
    {
        if ($username && $password) {
            # Attempt to log the user in
            if ($c->authenticate({ username => $username,
                                    password => $password  } )) {
                # If successful, then let them use the application
                $c->response->redirect($c->uri_for(
                    $c->controller('Books')->action_for('list')));
                return;
            } else {
                # Set an error message
                $c->stash(error_msg => "Invalid username or password.");
            }
        } else {
            # Set an error message
            $c->stash(status_msg => "Please enter username and password.") unless ($c->user_exists);
        }
    }
 
    # If either of above don't work out, send to the login page
    $c->stash(template => 'login.tt2');
}

=head1 AUTHOR

Theerapat,,,

=head1 LICENSE

This library is free software. You can redistribute it and/or modify
it under the same terms as Perl itself.

=cut

__PACKAGE__->meta->make_immutable;

1;
