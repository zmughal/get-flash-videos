# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Videolectures;

use strict;
use FlashVideo::Utils;
use List::Util qw(max first);

sub find_video {
  my ($self, $browser) = @_;

  my $content = $browser->content;
  my $author = ($content =~ /author:\s*<\/span><a [^>]+>([^<]+)/s)[0];
  my $title  = ($content =~ /<h2>([^<]+)/)[0];

  my $smil_path = ($browser->content =~ /xhr:.*'([^']*smil.xml)'/)[0];
  my $smil_url = "http://videolectures.net/$smil_path";
  my $smil_content = $browser->get( $smil_url )->content;
  my $xml_data = from_xml( $smil_content, KeyAttr => 'video' ); # treat video tag as list
  my $videos = $xml_data->{body}{switch}{video};
  $videos = [  grep { $_->{proto} eq 'rtmp' } @$videos ]; # only keep the rtmp ones
  my $max_size = max map { 0 + $_->{size} } @$videos;
  my $max_size_video = first {  $_->{size} == $max_size } @$videos;

  my $filename = title_to_filename("$author - $title");
  if( $max_size_video->{proto} eq 'http' ) {
    return $max_size_video->{src}, $filename;
  } elsif( $max_size_video->{proto} eq 'rtmp' ) {
    my $streamer = $max_size_video->{streamer};
    my @cmd = ('vlc', $streamer, "--avio-options={rtmp_playpath=$max_size_video->{src}}",
        "--sout=file/avi:$filename.avi",
        "-I", "ncurses");
    system @cmd;
    return +{
      app      => (split m{/}, $streamer)[-1],
      rtmp     => $streamer,
      playpath => $max_size_video->{src},
      flv => $filename,
    };
  }
}

1;
