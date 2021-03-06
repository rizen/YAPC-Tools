#!/usr/bin/perl

use strict;
use 5.010;
use Net::MovableType;
use XML::FeedPP;
use Config::JSON;
use HTML::FormatText::Html2text;
use Email::MIME::CreateHTML;
use Email::Sender::Simple;
use Email::Sender::Transport::SMTP;
use CHI;
use Getopt::Long;

# cli options
GetOptions( "config=s" => \my $config_file, "verbose" => \my $verbose );

# config
my $config = Config::JSON->new($config_file);

# do stuff
my $posts = get_latest_posts();
post_to_mailing_list($posts) if $config->get('enable/mailing_list');
post_to_movable_type($posts) if $config->get('enable/movable_type');

# functions 
sub post_to_mailing_list {
  say "Posting to mailing list..." if $verbose;
  my $posts = shift;
  my $transport = Email::Sender::Transport::SMTP->new($config->get('smtp'));
  foreach my $post (@{$posts}) {
    say "\t".$post->{title} if $verbose;
     my $email = Email::MIME->create_html(
         header => [
             To      => $config->get('mailing_list/to'),
             From    => $config->get('mailing_list/from'),
             Subject => $post->{title},
         ],
         body      => $post->{description},
         body_attributes      => { charset => 'utf-8' },
         text_body_attributes => { charset => 'utf-8' },
         text_body => HTML::FormatText::Html2text->format_string($post->{description}),
     );
     Email::Sender::Simple->send($email, { transport => $transport });
     last if $config->get('enable/most_recent_only');
  }
}

sub post_to_movable_type {
  say "Posting to Movable Type..." if $verbose;
  my $posts = shift;
  my $movable_type = Net::MovableType->new($config->get('movable_type/api_uri'));
  $movable_type->username($config->get('movable_type/username'));
  $movable_type->password($config->get('movable_type/password'));
  $movable_type->blogId($config->get('movable_type/blog_id'));
  foreach my $post (@{$posts}) {
    say "\t".$post->{title} if $verbose;
    $movable_type->newPost($post,1);
    last if $config->get('enable/most_recent_only');
  }
}

sub get_latest_posts {
  say "Fetching feed..." if $verbose;
  my $cache = CHI->new( driver => 'File', root_dir => '/tmp/rss2channels');
  my $latest = $cache->get('latest_entry_guid');
  my $feed = XML::FeedPP->new( $config->get('rss_uri') );
  my @entries;

  foreach my $item ( $feed->get_item() ) {
    say "\t".$item->title.' - '.$item->guid if $verbose;
    if (scalar @entries == 0) { # cache the first item fetched
      $cache->set('latest_entry_guid', $item->guid);
    }
    last if ($latest eq $item->guid); # stop fetching entries once we've got the latest
    my $id = $item->guid;
    $id =~ s{http://blog.yapcna.org/post/(\d+)}{$1}xms;
    my $description = $item->description.q{

         <p>[From the <a href="http://blog.yapcna.org">YAPC::NA Blog</a>.]</p>

    };
    #$description =~ s/\o{342}\o{200}\o{231}/'/gs; # fix for stylized quotes
    push @entries, {
      title		=> $item->title,
      description       => $description,
      mt_tb_ping_urls	=> ['http://disqus.com/forums/yapcnablog/httpblogyapcnaorgpost'.$id.'/trackback/'],
      mt_convert_breaks => 0,
      mt_keywords => 'yapc::na, yapc, conferences, yapcna2012',
    };
  }

  return \@entries;
}


