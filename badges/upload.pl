use strict;
use 5.010;
use LWP::UserAgent;
use HTTP::Request::Common;
use JSON;
use URI;
use Data::Printer;

# create session
my $session = post('session',[
     username    => $ENV{TGC_USER},
     password    => $ENV{TGC_PASS},
     api_key_id  => $ENV{TGC_APIKEY},
]);

# get user
my $user = get('user/'.$session->{user_id},[
    session_id  => $session->{id},
    include_related_objects => 1,
]);

# create folder
my $folder = post('folder',[
    name        => 'YAPC Badges',
    session_id  => $session->{id},
    user_id     => $user->{id},
    parent_id   => $user->{root_folder}{id},
]);


sub get {
    my ($path, $params) = @_;
    my $uri = URI->new('https://www.thegamecrafter.com/api/'.$path);
    $uri->query_form($params);
    my $response = LWP::UserAgent->new->request( GET $uri->as_string);
    my $result = from_json($response->decoded_content); 
    if ($response->is_success) {
        say $result->{result}{object_name}.' ID: ', $result->{result}{id};
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
        say $result->{result}{object_name}.' ID: ', $result->{result}{id};
        return $result->{result};
    }
    else {
        die 'Error: '. $response->status_line. ' '. $folder->{error}{message};
    }
}

