# Part of get-flash-videos. See get_flash_videos for copyright.
package FlashVideo::Site::Techtalks;

use strict;
use FlashVideo::Utils;

sub find_video {
  my ($self, $browser) = @_;

  my $author = ($browser->content =~ /<li class="authors">([^<]+)/s)[0];
  my $title  = ($browser->content =~ /<h2 class="title">([^<]+)/)[0];

  my $streamer = ($browser->content =~ /netConnectionUrl:\s*["']([^"']+)/)[0];
  my $playpath = ($browser->content =~ /<a\s+class="rtmp"\s+href=["']([^"']+)/)[0];
  my $swfUrl = 'http://techtalks.tv' .
                  ($browser->content =~ m{url:\s+["']([^"']+)})[0];
  # NOTE This will not download the slides

  my $data = {
    app      => (split m{/}, $streamer)[-1],
    rtmp     => $streamer,
    swfUrl   => $swfUrl,
    playpath => $playpath,
    pageUrl  => 'http://techtalks.tv',
    flv      => title_to_filename("$author - $title"),
  };

  return $data;
}

1;
