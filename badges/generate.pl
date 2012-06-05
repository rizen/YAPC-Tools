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
my @cols = (qw(first last email company url town country vip fop staff z2p tw subsidized speaker spouses netid password));


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
    say $i;
    my %registrant = zip @cols, @row;
    $registrant{id} = $i;
    my $vcard = make_vcard(\%registrant);
    my $qrcode = make_qrcode($vcard);
    make_face(\%registrant);
    make_back(\%registrant, $qrcode);
    $i++;
}
close $fh;


sub make_back {
    my ($reg, $qrpath) = @_;
    my $badge = Image::Magick->new(size=>'1125x825');
    say $badge->ReadImage('canvas:#b70101');
    unless ($reg->{first} eq '' && $reg->{last} eq '') {
        my $qrcode = Image::Magick->new;
        $qrcode->ReadImage($qrpath);
        say $badge->Composite(compose => 'over', image => $qrcode, x => 75, y => 160);
        say $badge->Annotate(text => $reg->{first}.' '.$reg->{last}, font => 'Garamond.ttf', x => 500, y => 200, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{email}, font => 'Garamond.ttf', x => 500, y => 250, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{company}, font => 'Garamond.ttf', x => 500, y => 300, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{url}, font => 'Garamond.ttf', x => 500, y => 350, fill => 'white', pointsize => '50');
        say $badge->Annotate(text => $reg->{town}.'  ['.uc($reg->{country}).']', font => 'Garamond.ttf', x => 500, y => 400, fill => 'white', pointsize => '50');
    }
    say $badge->Annotate(text => 'WiFi SSID: UWNet     Net-ID: '.$reg->{netid}.'     Password: '.$reg->{password}, x => 150, y => 725, fill => 'white', pointsize => '25', font => 'Arial.ttf');
    say $badge->Rotate(270);
    say $badge->Write($out_path.'/back-'.$reg->{id}.'.png');
}

sub make_face {
    my $reg = shift;
    my $badge = Image::Magick->new(size=>'1125x825');
    say $badge->ReadImage('canvas:#b70101');
    say $badge->Composite(compose => 'over', image => $logo, x => 650, y => 250);
    if ($reg->{first} eq '' && $reg->{last} eq '') {
        say $badge->Draw(stroke=>'black', fill => 'white', strokewidth=>3, primitive=>'rectangle', points=>'75,75 575,450');
    }
    else {
        say $badge->Annotate(text => $reg->{first}, font => 'Garamond.ttf', x => 75, y => 200, fill => 'white', pointsize => '170');
        say $badge->Annotate(text => $reg->{last}, font => 'Garamond.ttf', x => 75, y => 300, fill => 'white', pointsize => '90');
    }
    say $badge->Annotate(text => 'Guest of the Community', font => 'Garamond.ttf', x => 125, y => 570, fill => 'white', pointsize => '30') if $reg->{subsidized};
    say $badge->Annotate(text => 'Staff', font => 'Garamond.ttf', x => 125, y => 600, fill => 'white', pointsize => '30') if $reg->{staff};
    say $badge->Annotate(text => 'Speaker', font => 'Garamond.ttf', x => 125, y => 630, fill => 'white', pointsize => '30') if $reg->{speaker};
    say $badge->Annotate(text => 'Zero To Perl', font => 'Garamond.ttf', x => 125, y => 660, fill => 'white', pointsize => '30') if $reg->{z2p};
    say $badge->Annotate(text => 'Testing Workshop', font => 'Garamond.ttf', x => 125, y => 690, fill => 'white', pointsize => '30') if $reg->{tw};
    say $badge->Annotate(text => 'Friend of Perl', font => 'Garamond.ttf', x => 125, y => 720, fill => 'white', pointsize => '30') if $reg->{fop};
    say $badge->Rotate(90);
    say $badge->Write($out_path.'/face-'.$reg->{id}.'.png');
}

sub make_qrcode {
    my $vcard = shift;
    my $qrcode = Imager::QRCode->new(
        size          => 7,
        margin        => 2,
        version       => 1,
        level         => 'M',
        casesensitive => 1,
        lightcolor    => Imager::Color->new(183,1,1),
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
    $vcard->add_node({node_type => 'URL'})->value($reg->{url});
    #$vcard->add_node({node_type => 'TITLE'})->value($reg->{title});
    #$vcard->add_node({node_type => 'TEL'})->value($phone);
    $vcard->add_node({node_type => 'EMAIL'})->value($reg->{email});
    my $org = $vcard->add_node({node_type => 'ORG'});
    $org->name($reg->{company});
    #$org->unit([$dept]);
    #$vcard->add_node({node_type => 'X-skype'})->value($skype);
    return $address_book->export;
}

