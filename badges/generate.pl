use strict;
use warnings;
use utf8;
use 5.010;
use Image::Magick;
use File::Path qw(make_path remove_tree);
use Text::CSV_XS;
use Text::vCard::Addressbook;
use Imager::QRCode;
use List::MoreUtils qw(zip);

# init
my $out_path = '/tmp/badge-output/';
remove_tree($out_path);
make_path($out_path);
my $logo = Image::Magick->new;
say $logo->ReadImage('logo.png');
my @cols = (qw(user_id login email salutation first last nick pseudonymous country town pm_group has_talk has_paid rights tshirt_size nb_family datetime));
my $ssid = 'attwifi';
my $password = 'WP3E-i8WM-iD';


# read registrants
my @rows;
my $filename = 'registrants.csv';
my $csv = Text::CSV_XS->new ({ binary => 1 }) or die "Cannot use CSV: ".Text::CSV_XS->error_diag ();
my $i = 1;
my $first = 1;
open my $fh, "<:encoding(utf8)", $filename or die "$filename $!";
while (my @row = @{$csv->getline($fh)}) {
    if ($first) {
        $first = 0;
        next;
    }
    my %registrant = zip @cols, @row;
    next unless $registrant{has_paid} || $registrant{has_talk};
    say $i;
    $registrant{id} = $i;
    my $vcard = make_vcard(\%registrant);
    my $qrcode = make_qrcode($vcard);
    make_badge(\%registrant, $qrcode);
    $i++;
}
close $fh;


sub make_badge {
    my ($reg, $qrpath) = @_;
    my $badge = Image::Magick->new(size=>'1125x825');
    say $badge->ReadImage('canvas:#333366');
    if ($reg->{first} eq '' && $reg->{last} eq '') {
        say $badge->Draw(stroke=>'black', fill => 'white', strokewidth=>3, primitive=>'rectangle', points=>'75,75 1050,600');
    }
    else {
        say $badge->Annotate(text => $reg->{first}, font => 'Garamond.ttf', x => 75, y => 200, fill => 'white', pointsize => '170');
        say $badge->Annotate(text => $reg->{last}, font => 'Garamond.ttf', x => 75, y => 300, fill => 'white', pointsize => '90');
    }
    my $label_y = 600;
    my %labels = (
     #   subsidized  => 'Guest of the Community',
     #   staff       => 'Staff',
        has_talk     => 'Speaker',
     #   z2p         => 'Zero To Perl',
     #   fop         => 'Friend of Perl',
     #   tw          => 'Testing Workshop',
    );
    while (my ($key, $label) = each %labels) {
        if ($reg->{$key}) {
            say $badge->Annotate(text => $label, font => 'Garamond.ttf', x => 125, y => $label_y, fill => 'orange', pointsize => '30');
            $label_y += 30;
        }
    }
    say $badge->Annotate(text => 'WiFi SSID: '.$ssid.'     Internet Access Code: '.$password, x => 150, y => 725, fill => 'white', pointsize => '25', font => 'Arial.ttf');
    unless ($reg->{first} eq '' && $reg->{last} eq '') {
        my $qrcode = Image::Magick->new;
        $qrcode->ReadImage($qrpath);
        say $badge->Annotate(text => $reg->{nick}, font => 'Garamond.ttf', x => 75, y => 375, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{pm_group}, font => 'Garamond.ttf', x => 75, y => 425, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{email}, font => 'Garamond.ttf', x => 75, y => 475, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{town}.'  ['.uc($reg->{country}).']', font => 'Garamond.ttf', x => 75, y => 525, fill => 'white', pointsize => '50');
        say $badge->Composite(compose => 'over', image => $qrcode, x => 800, y => 260);
    }
    #say $badge->Rotate(90);
    say $badge->Composite(compose => 'over', image => $logo, x => 850, y => 525);
    say $badge->Write($out_path.'/face-'.$reg->{id}.'.png');
    say $badge->Rotate(180);
    say $badge->Write($out_path.'/back-'.$reg->{id}.'.png');
}

sub make_qrcode {
    my $vcard = shift;
    my $qrcode = Imager::QRCode->new(
        size          => 4,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(51,51,102),
        darkcolor     => Imager::Color->new(255,255,255),
    );
    my $img = $qrcode->plot($vcard);
    $img->write(file => $out_path."qrcode.gif");
    return $out_path."qrcode.gif";
}

sub make_vcard {
    my $reg = shift;
    my $address_book = Text::vCard::Addressbook->new();
    my $vcard = $address_book->add_vcard();
    my $address = $vcard->add_node({node_type => 'ADR'});
   # $address->street($street);
    $address->city($reg->{town});
   # $address->region($state);
    #$address->post_code($zip);
    $address->country($reg->{country});
    my $name = $vcard->add_node({node_type => 'N'});
    $name->given($reg->{first});
    $name->family($reg->{last});
    $vcard->add_node({node_type => 'FN'})->value($reg->{first}.' '.$reg->{last});
    $vcard->add_node({node_type => 'NICKNAME'})->value($reg->{nick});
    #$vcard->add_node({node_type => 'URL'})->value($reg->{url});
    #$vcard->add_node({node_type => 'TITLE'})->value($reg->{title});
    #$vcard->add_node({node_type => 'TEL'})->value($phone);
    $vcard->add_node({node_type => 'EMAIL'})->value($reg->{email});
    my $org = $vcard->add_node({node_type => 'ORG'});
    $org->name($reg->{pm_group});
    #$org->unit([$dept]);
    #$vcard->add_node({node_type => 'X-skype'})->value($skype);
    return $address_book->export;
}

