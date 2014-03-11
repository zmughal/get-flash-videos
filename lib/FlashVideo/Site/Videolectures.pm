# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Videolectures;

use strict;
use FlashVideo::Utils;
use List::Util qw(max first);

sub find_video {
  my ($self, $browser, $url) = @_;

  $url = URI->new($url);
  my $req_video_id = $url->fragment || 1;

  my $content = $browser->content;
  my $author = ($content =~ /author:\s*<\/span><a [^>]+>([^<]+)/s)[0];
  my $title  = ($content =~ /<h2>([^<]+)/)[0];

  my $number_of_videos = ($content =~/videos:(\d+)/)[0];

  my $smil_path = ($content =~ /xhr:.*'([^']*smil.xml)'/)[0];
  my $smil_url = URI->new_abs($smil_path, "http://videolectures.net/");

  my $video_data = [];

  # download info about all parts
  for my $video_id (1..$number_of_videos) {
    my @path = $smil_url->path_segments();
    $path[-2] = $video_id; # change the video ID
    $smil_url->path_segments( @path );

    my $part_fname_append = $number_of_videos > 1 ? " (part_$video_id)" : "";

    my $smil_content = $browser->get( $smil_url )->content;
    my $xml_data = from_xml( $smil_content, KeyAttr => 'video' ); # treat video tag as list
    my $videos = $xml_data->{body}{switch}{video};
    # only keep the rtmp ones, because http seems to be returning 403 Forbidden
    $videos = [  grep { $_->{proto} eq 'rtmp' } @$videos ];
    my $max_size = max map { 0 + $_->{size} } @$videos;
    my $max_size_video = first {  $_->{size} == $max_size } @$videos;
    my $filename = title_to_filename("$author - $title$part_fname_append");
    if( $max_size_video->{proto} eq 'http' ) {
      push @$video_data, [$max_size_video->{src}, $filename];
    } elsif( $max_size_video->{proto} eq 'rtmp' ) {
      my $streamer = $max_size_video->{streamer};
      push @$video_data, +{
        app      => (split m{/}, $streamer)[-1],
        rtmp     => $streamer,
        playpath => $max_size_video->{src},
        flv => $filename,
      };
    }
  }
  if( $number_of_videos > 1 && ! $url->fragment ) {
    my $info_str = "There are $number_of_videos parts\n" .
        "To download other parts use\n" .
        "$0 '$url#<part_number>'\n" .
        "e.g., $0 '$url#2'";
    $info_str =~ s/^/    /mg;
    info $info_str;
  }
  my $vid_data = $video_data->[$req_video_id - 1];
  my @cmd = ('vlc', $vid_data->{rtmp}, "--avio-options={rtmp_playpath=$vid_data->{playpath}}",
      "--sout=file/avi:$vid_data->{flv}.avi",
      "-I", "ncurses");
  system @cmd;

  return $video_data->[$req_video_id - 1];
}

1;
