use strict;
use 5.010;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;

# create session
my $session = post('session',[
     username    => $ENV{TGC_USER},
     password    => $ENV{TGC_PASS},
     api_key_id  => $ENV{TGC_APIKEY},
]);

# get user
my $user = get('user/'.$session->{user_id},[
    session_id  => $session->{id}
    include_related_objects => 1,
]);


# create folder
my $folder = post('folder'
$response = LWP::UserAgent->new->request( POST 'https://www.thegamecrafter.com/api/folder', [
    name        => 'YAPC Badges',
    session_id  => $session->{result}{id},
    user_id     => $session->{result}{user_id},
]);
my $folder = from_json($response->decoded_content); 
if ($response->is_success) {
   say 'Folder ID: ', $folder->{result}{id};
}
else {
   say 'Error: ', $folder->{error}{message};
}



sub get {
    my ($path, $params) = @_;
    my $response = LWP::UserAgent->new->request( GET 'https://www.thegamecrafter.com/api/'.$path, $params );
    my $result = from_json($response->decoded_content); 
    if ($response->is_success) {
        say $self-' ID: ', $result->{result}{id};
        return $result->{result};
    }
    else {
        die 'Error: ', $folder->{error}{message};
    }
}

sub post {
    my ($path, $params) = @_;
    my $response = LWP::UserAgent->new->request( POST 'https://www.thegamecrafter.com/api/'.$path, $params );
    my $result = from_json($response->decoded_content); 
    if ($response->is_success) {
        say $path.' ID: ', $result->{result}{id};
        return $result->{result};
    }
    else {
        die 'Error: ', $folder->{error}{message};
    }
}

