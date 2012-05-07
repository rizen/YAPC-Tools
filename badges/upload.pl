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
    include_relationships => 1,
]);

# get designer
my $designers = get($user->{_relationships}{designers},[
    session_id  => $session->{id},
]);
my $designer = $designers->{items}[0];

# create folder
my $folder = post('folder',[
    name        => 'YAPC Badges',
    session_id  => $session->{id},
    user_id     => $user->{id},
    parent_id   => $user->{root_folder}{id},
]);

# create game
my $game = post('game', [
    name        => 'YAPC Badges',
    designer_id => $designer->{id},
    session_id  => $session->{id},
]);

# create deck 
my $deck = post('pokerdeck', [
    name        => 'YAPC Badges',
    game_id => $game->{id},
    session_id  => $session->{id},
]);

my $badge_path = '/tmp/badge-output';
if ( opendir(my $dir, $badge_path) ) {
    my @files = readdir($dir);
    close $dir;
    foreach my $filename (@files) {
        next unless $filename =~ m/face-(\d+).png/;
        my $id = $1;
        my $face = post('file',[
            name        => $filename,
            folder_id   => $folder->{id},
            file        => [$badge_path .'/'. $filename],
            session_id  => $session->{id},
        ]);
        my $back = post('file',[
            name        => 'back-'.$id.'.png',
            folder_id   => $folder->{id},
            file        => [$badge_path .'/back-'.$id.'.png'],
            session_id  => $session->{id},
        ]);
        my $card = post('pokercard', [
            name        => $id,
            deck_id     => $deck->{id},
            session_id  => $session->{id},
            back_from   => 'Card',
            face_id     => $face->{id},
            back_id     => $back->{id},
            has_proofed_face    => 1,
            has_proofed_back    => 1,
        ]);
    }
}
else {
    die "Couldn't open ".$badge_path;
}

sub get {
    my ($path, $params) = @_;
    unless ($path =~ m/^\/api/) {
        $path = '/api/'.$path;
    }
    my $uri = URI->new('https://www.thegamecrafter.com'.$path);
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
    unless ($path =~ m/^\/api/) {
        $path = '/api/'.$path;
    }
    my $response = LWP::UserAgent->new->request( POST 'https://www.thegamecrafter.com'.$path, Content_Type => 'form-data', Content => $params );
    my $result = from_json($response->decoded_content); 
    if ($response->is_success) {
        say $result->{result}{object_name}.' ID: ', $result->{result}{id};
        return $result->{result};
    }
    else {
        die 'Error: '. $response->status_line. ' '. $folder->{error}{message};
    }
}

