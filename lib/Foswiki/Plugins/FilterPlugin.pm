# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2005-2024 Michael Daum http://michaeldaumconsulting.com
#
# This program is free software; you can redistribute it and/or
# modify it under the terms of the GNU General Public License
# as published by the Free Software Foundation; either version 2
# of the License, or (at your option) any later version.
#
# This program is distributed in the hope that it will be useful,
# but WITHOUT ANY WARRANTY; without even the implied warranty of
# MERCHANTABILITY or FITNESS FOR A PARTICULAR PURPOSE.  See the
# GNU General Public License for more details, published at 
# http://www.gnu.org/copyleft/gpl.html
#
package Foswiki::Plugins::FilterPlugin;

=begin TML

---+ package Foswiki::Plugins::FilterPlugin

base class to hook into the foswiki core

=cut

use strict;
use warnings;

use Foswiki::Func();

our $VERSION = '7.11';
our $RELEASE = '%$RELEASE%';
our $NO_PREFS_IN_TOPIC = 1;
our $SHORTDESCRIPTION = 'Substitute and extract information from content by using regular expressions';
our $LICENSECODE = '%$LICENSECODE%';
our $core;

=begin TML

---++ initPlugin($topic, $web, $user) -> $boolean

initialize the plugin, automatically called during the core initialization process

=cut

sub initPlugin {
  my ($currentTopic, $currentWeb) = @_;

  Foswiki::Func::registerTagHandler('FORMATLIST', sub {
    return getCore(shift)->handleFormatList(@_);
  });

  Foswiki::Func::registerTagHandler('MAKEINDEX', sub {
    return getCore(shift)->handleMakeIndex(@_);
  });

  Foswiki::Func::registerTagHandler('SUBST', sub {
    return getCore(shift)->handleSubst(@_);
  });

  Foswiki::Func::registerTagHandler('EXTRACT', sub {
    return getCore(shift)->handleExtract(@_);
  });

  Foswiki::Func::registerTagHandler('DECODE', sub {
    return getCore(shift)->handleDecode(@_);
  });

  return 1;
}

=begin TML

---++ finishPlugin

finish the plugin and the core if it has been used,
automatically called during the core initialization process

=cut

sub finishPlugin {
  undef $core;
}

=begin TML

---++ getCore() -> $core

returns a singleton Foswiki::Plugins::Foswiki::Core object for this plugin; a new core is allocated 
during each session request; once a core has been created it is destroyed during =finishPlugin()=

=cut

sub getCore {
  my $session = shift;

  unless (defined $core) {
    require Foswiki::Plugins::FilterPlugin::Core;
    $core = new Foswiki::Plugins::FilterPlugin::Core($session)
  }

  return $core;
}

=begin TML

---++ commonTagsHandler($text, $topic, $web, $included, $meta) 

hooks into the makro parser

=cut

sub commonTagsHandler {
# my ($text, $topic, $web, $included, $meta ) = @_;

  my $theTopic = $_[1];
  my $theWeb = $_[2];

  while($_[0] =~ s/%STARTSUBST\{(?!.*%STARTSUBST)(.*?)\}%(.*?)%STOPSUBST%/&handleFilterArea($1, 1, $2, $theWeb, $theTopic)/ges) {
    # nop
  }
  while($_[0] =~ s/%STARTEXTRACT\{(?!.*%STARTEXTRACT)(.*?)\}%(.*?)%STOPEXTRACT%/&handleFilterArea($1, 0, $2, $theWeb, $theTopic)/ges) {
    # nop
  }
}

=begin TML

---++ ObjectMethod handleFilterArea()

handles STARTSUBST and STARTEXTRACT sections

=cut

sub handleFilterArea {
  return getCore()->handleFilterArea(@_);
}

1;
