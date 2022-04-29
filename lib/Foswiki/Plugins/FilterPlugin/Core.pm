# Plugin for Foswiki - The Free and Open Source Wiki, http://foswiki.org/
#
# Copyright (C) 2005-2022 Michael Daum http://michaeldaumconsulting.com

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

package Foswiki::Plugins::FilterPlugin::Core;

use strict;
use warnings;

use Foswiki::Plugins();
use Foswiki::Func();
use Text::Unidecode();

use constant TRACE => 0; # toggle me

sub new {
  my ($class, $session) = @_;

  $session ||= $Foswiki::Plugins::SESSION;

  my $this = bless({
    session => $session,
    seenAnchorNames => {},
    makeIndexCounter => 0,
    filteredTopic => {},
  }, $class);

  Foswiki::Func::addToZone('head', 'FILTERPLUGIN',
   '<link rel="stylesheet" type="text/css" href="%PUBURLPATH%/%SYSTEMWEB%/FilterPlugin/filter.css" media="all" />');

  return $this;
}

sub handleFilterArea {
  my ($this, $theAttributes, $theMode, $theText, $theWeb, $theTopic) = @_;

  $theAttributes //= '';
  writeDebug("called handleFilterArea($theAttributes)");

  my %params = Foswiki::Func::extractParameters($theAttributes);
  return $this->handleFilter(\%params, $theMode, $theText, $theWeb, $theTopic);
}

# filter a topic or url thru a regular expression
# attributes
#    * pattern
#    * format
#    * hits
#    * topic
#    * expand
#
sub handleFilter {
  my ($this, $params, $theMode, $theText, $theWeb, $theTopic) = @_;

  writeDebug("called handleFilter()");
  writeDebug("theMode = '$theMode'");

  # get parameters
  my $thePattern = $params->{pattern} // '';
  my $theFormat = $params->{format} // '';
  my $theNullFormat = $params->{null} // '';
  my $theHeader = $params->{header} // '';
  my $theFooter = $params->{footer} // '';
  my $theLimit = $params->{limit} // $params->{hits} // 100000; 
  my $theSkip = $params->{skip} // 0;
  my $theExpand = Foswiki::Func::isTrue($params->{expand}, 1);
  my $theSeparator = $params->{separator};
  my $theExclude = $params->{exclude} // '';
  my $theInclude = $params->{include} // '';
  my $theSort = $params->{sort} // 'off';
  my $theReverse = $params->{reverse} // '';
  my $theRev = $params->{rev};

  my $thisTopic = $params->{_DEFAULT} // $params->{topic} // $theTopic;
  ($theWeb, $theTopic) = Foswiki::Func::normalizeWebTopicName($theWeb, $thisTopic);
  $theWeb =~ s/\//\./g;
  
  $theText //= $params->{text};

  $theSeparator //= '';

  # get the source text
  my $text = '';
  if (defined $theText) { # direct text
    if ($theExpand) {
      $text = Foswiki::Func::decodeFormatTokens($theText);
      $text = Foswiki::Func::expandCommonVariables($text) if $text =~ /%/;
    }
  } else { # topic text
    return '' if $this->{filteredTopic}{"$theWeb.$theTopic"};
    $this->{filteredTopic}{"$theWeb.$theTopic"} = 1;
    (undef, $text) = Foswiki::Func::readTopic($theWeb, $theTopic, $theRev);
    $text //= '';
    if ($text =~ /^No permission to read topic/) {
      return inlineError("$text");
    }
    if ($text =~ /%STARTINCLUDE%(.*)%STOPINCLUDE%/gs) {
      $text = $1;
      if ($theExpand) {
	$text = Foswiki::Func::expandCommonVariables($text) if $text =~ /%/;
	$text = Foswiki::Func::renderText($text);
      }
    }
  }
  #writeDebug("text = '$text'");

  my $result = '';
  my $hits = $theLimit;
  my $skip = $theSkip;
  if ($theMode == 0) {
    # extraction mode

    my @result = ();
    while($text =~ /$thePattern/gmsc) {
      my $arg1 = $1 // '';
      my $arg2 = $2 // '';
      my $arg3 = $3 // '';
      my $arg4 = $4 // '';
      my $arg5 = $5 // '';
      my $arg6 = $6 // '';
      my $arg7 = $7 // '';
      my $arg8 = $8 // '';
      my $arg9 = $9 // '';
      my $arg10 = $10 // '';
      my $arg11 = $11 // '';
      my $arg12 = $12 // '';
      my $arg13 = $13 // '';
      my $arg14 = $14 // '';
      my $arg15 = $15 // '';
      my $arg16 = $16 // '';
      my $arg17 = $17 // '';
      my $arg18 = $18 // '';
      my $arg19 = $19 // '';
      my $arg20 = $20 // '';

      my $match = $theFormat;
      $match =~ s/\$20/$arg20/g;
      $match =~ s/\$19/$arg19/g;
      $match =~ s/\$18/$arg18/g;
      $match =~ s/\$17/$arg17/g;
      $match =~ s/\$16/$arg16/g;
      $match =~ s/\$15/$arg15/g;
      $match =~ s/\$14/$arg14/g;
      $match =~ s/\$13/$arg13/g;
      $match =~ s/\$12/$arg12/g;
      $match =~ s/\$11/$arg11/g;
      $match =~ s/\$10/$arg10/g;
      $match =~ s/\$1/$arg1/g;
      $match =~ s/\$2/$arg2/g;
      $match =~ s/\$3/$arg3/g;
      $match =~ s/\$4/$arg4/g;
      $match =~ s/\$5/$arg5/g;
      $match =~ s/\$6/$arg6/g;
      $match =~ s/\$7/$arg7/g;
      $match =~ s/\$8/$arg8/g;
      $match =~ s/\$9/$arg9/g;

      next if $theExclude && $match =~ /^($theExclude)$/;
      next if $theInclude && $match !~ /^($theInclude)$/;
      next if $skip-- > 0;

      push @result,$match;
      $hits--;

      last if $theLimit > 0 && $hits <= 0;
    }

    if ($theSort ne 'off') {
      my $isNumeric;
      my %sorting = ();
      if ($theSort eq 'alpha' || $theSort eq 'on') {
        %sorting = map {$_ => uc($_)} @result;
        $isNumeric = 0;
      } elsif ($theSort eq 'num') {
        %sorting = map {my $item = $_; my $num = ($item =~ /([+-]?\d+(?:\.\d+)?)/ ? $1:0) ; $item => $num} @result;
        $isNumeric = 1;
      } elsif ($theSort eq 'random') {
        %sorting = map {$_ => rand()} @result;
        $isNumeric = 1;
      }
      if (defined $isNumeric) {
        if ($isNumeric) {
          @result = sort { $sorting{$a} <=> $sorting{$b} } @result;
        } else {
          @result = sort { $sorting{$a} cmp $sorting{$b} } @result;
        }
      }
    }
    @result = reverse @result if $theReverse;
    $result = join($theSeparator, @result);
  } elsif ($theMode == 1) {
    # substitution mode
    $result = '';
    while($text =~ /(.*?)$thePattern/gcs) {
      my $prefix = $1 // '';
      my $arg1 = $2 // '';
      my $arg2 = $3 // '';
      my $arg3 = $4 // '';
      my $arg4 = $5 // '';
      my $arg5 = $6 // '';
      my $arg6 = $7 // '';
      my $arg7 = $8 // '';
      my $arg8 = $9 // '';
      my $arg9 = $10 // '';
      my $arg10 = $11 // '';
      my $arg11 = $12 // '';
      my $arg12 = $13 // '';
      my $arg13 = $14 // '';
      my $arg14 = $15 // '';
      my $arg15 = $16 // '';
      my $arg16 = $17 // '';
      my $arg17 = $18 // '';
      my $arg18 = $19 // '';
      my $arg19 = $20 // '';
      my $arg20 = $21 // '';

      my $match = $theFormat;
      $match =~ s/\$20/$arg20/g;
      $match =~ s/\$19/$arg19/g;
      $match =~ s/\$18/$arg18/g;
      $match =~ s/\$17/$arg17/g;
      $match =~ s/\$16/$arg16/g;
      $match =~ s/\$15/$arg15/g;
      $match =~ s/\$14/$arg14/g;
      $match =~ s/\$13/$arg13/g;
      $match =~ s/\$12/$arg12/g;
      $match =~ s/\$11/$arg11/g;
      $match =~ s/\$10/$arg10/g;
      $match =~ s/\$1/$arg1/g;
      $match =~ s/\$2/$arg2/g;
      $match =~ s/\$3/$arg3/g;
      $match =~ s/\$4/$arg4/g;
      $match =~ s/\$5/$arg5/g;
      $match =~ s/\$6/$arg6/g;
      $match =~ s/\$7/$arg7/g;
      $match =~ s/\$8/$arg8/g;
      $match =~ s/\$9/$arg9/g;

      next if $theExclude && $match =~ /^($theExclude)$/;
      next if $theInclude && $match !~ /^($theInclude)$/;
      next if $skip-- > 0;

      #writeDebug("match=$match");
      $result .= $prefix.$match;
      #writeDebug("($hits) result=$result");
      $hits--;
      last if $theLimit > 0 && $hits <= 0;
    }
    if ($text =~ /\G(.*)$/s) {
      $result .= $1;
    }
  }
  $result = $theNullFormat unless $result;
  $result = $theHeader.$result.$theFooter;
  expandVariables($result);

  delete $this->{filteredTopic}{"$theWeb.$theTopic"};

  #writeDebug("result='$result'");
  return $result;
}

sub handleSubst {
  my ($this, $params, $theTopic, $theWeb) = @_;
  return $this->handleFilter($params, 1, undef, $theWeb, $theTopic);
}

sub handleExtract {
  my ($this, $params, $theTopic, $theWeb) = @_;
  return $this->handleFilter($params, 0, undef, $theWeb, $theTopic);
}

sub handleDecode {
  my ($this, $params, $theTopic, $theWeb) = @_;

  my $type = $params->{type} // "url";
  my $text = $params->{_DEFAULT} // "";

  return "" if $text eq "";
  return $text if $type =~ /^(off|none)$/i;

  return Foswiki::entityDecode($text) if $type =~ /^entit(y|ies)$/i;
  return Foswiki::entityDecode($text, "\n\r") if $type =~ /^html$/i;
  return Foswiki::urlDecode($text) if $type =~ /^url$/i;

  if ($type =~ /^quotes?$/i) {
    $text =~ s/\\"/"/g;
    return $text;
  }

  if ($type =~ /^safe$/i) {
    $text =~ s/(&#(39|34|60|62|37);)/chr($2)/ge;
    return $text;
  }
  
  return $text;
}

sub handleMakeIndex {
  my ($this, $params, $theTopic, $theWeb) = @_;

  my $theList = $params->{_DEFAULT} // $params->{list} // '';
  my $theFormat = $params->{format};
  my $theCols = $params->{cols} // "automatic";
  my $theColWidth = $params->{colwidth};
  my $theColGap = $params->{colgap};
  my $theSort = $params->{sort} // 'on';
  my $theSplit = $params->{split};
  $theSplit //= '\s*,\s*';

  my $theUnique = Foswiki::Func::isTrue($params->{unique}, 0);
  my $theExclude = $params->{exclude} // '';
  my $theInclude = $params->{include} // '';
  my $theCaseSensitive = Foswiki::Func::isTrue($params->{casesensitive}, 1);
  my $theReverse = Foswiki::Func::isTrue($params->{reverse}, 0);
  my $theHideEmpty = Foswiki::Func::isTrue($params->{hideempty}, 0);
  my $thePattern = $params->{pattern} // '';
  my $theHeader = $params->{header} // '';
  my $theFooter = $params->{footer} // '';
  my $theGroup = $params->{group};
  my $theAnchorThreshold = $params->{anchorthreshold} // 0;
  my $theTransliterate = $params->{transliterate};
  my $theSeparator = $params->{separator};
  $theSeparator //= "\n";

  my %map = ();
  if (defined $theTransliterate) {
    if ($theTransliterate =~ /^on|yes|true|1$/) {
      $theTransliterate = 1;
    } elsif ($theTransliterate =~ /^off|no|false|0$/) {
      $theTransliterate = 0;
    }  else {
      %map = map {$_ =~ /^(.*)=(.*)$/, $1=>$2} split(/\s*,\s*/, $theTransliterate);
      $theTransliterate = 1;
    }
  }

  # sanitize params
  $theAnchorThreshold =~ s/[^\d]//g;
  $theAnchorThreshold = 0 unless $theAnchorThreshold;
  $theGroup //= "<h3 \$anchor'>\$group</h3>";
  $theFormat //= '$item';

  # compute the list
  $theList = Foswiki::Func::expandCommonVariables($theList, $theTopic, $theWeb)
    if expandVariables($theList);

  # create the item descriptors for each list item
  my @theList = ();
  my %seen = ();
  foreach my $item (split(/$theSplit/, $theList)) {
    if ($theCaseSensitive) {
      next if $theExclude && $item =~ /^($theExclude)$/;
      next if $theInclude && $item !~ /^($theInclude)$/;
    } else {
      next if $theExclude && $item =~ /^($theExclude)$/i;
      next if $theInclude && $item !~ /^($theInclude)$/i;
    }

    $item =~ s/<nop>//g;
    $item =~ s/^\s+|\s+$//g;
    next unless $item;

    #writeDebug("item='$item'");

    if ($theUnique) {
      next if $seen{$item};
      $seen{$item} = 1;
    }

    my $crit = $item;
    if ($crit =~ /\((.*?)\)/) {
      $crit = $1;
    }
    $crit = transliterate($crit, \%map) if $theTransliterate;

    if ($theSort eq 'nocase') {
      $crit = uc($crit);
    }
    #$crit =~ s/[^$Foswiki::regex{'mixedAlphaNum'}]//g;

    my $group = $crit;
    $group = substr($crit, 0, 1) unless $theSort eq 'num';

    my $itemFormat = $theFormat;
    if ($thePattern && $item =~ m/$thePattern/) {
      my $arg1 = $1 // '';
      my $arg2 = $2 // '';
      my $arg3 = $3 // '';
      my $arg4 = $4 // '';
      my $arg5 = $5 // '';
      my $arg6 = $6 // '';
      my $arg7 = $7 // '';
      my $arg8 = $8 // '';
      my $arg9 = $9 // '';
      my $arg10 = $10 // '';
      my $arg11 = $11 // '';
      my $arg12 = $12 // '';
      my $arg13 = $13 // '';
      my $arg14 = $14 // '';
      my $arg15 = $15 // '';
      my $arg16 = $16 // '';
      my $arg17 = $17 // '';
      my $arg18 = $18 // '';
      my $arg19 = $19 // '';
      my $arg20 = $20 // '';

      $item = $arg1 if $arg1;
      $itemFormat =~ s/\$20/$arg20/g;
      $itemFormat =~ s/\$19/$arg19/g;
      $itemFormat =~ s/\$18/$arg18/g;
      $itemFormat =~ s/\$17/$arg17/g;
      $itemFormat =~ s/\$16/$arg16/g;
      $itemFormat =~ s/\$15/$arg15/g;
      $itemFormat =~ s/\$14/$arg14/g;
      $itemFormat =~ s/\$13/$arg13/g;
      $itemFormat =~ s/\$12/$arg12/g;
      $itemFormat =~ s/\$11/$arg11/g;
      $itemFormat =~ s/\$10/$arg10/g;
      $itemFormat =~ s/\$1/$arg1/g;
      $itemFormat =~ s/\$2/$arg2/g;
      $itemFormat =~ s/\$3/$arg3/g;
      $itemFormat =~ s/\$4/$arg4/g;
      $itemFormat =~ s/\$5/$arg5/g;
      $itemFormat =~ s/\$6/$arg6/g;
      $itemFormat =~ s/\$7/$arg7/g;
      $itemFormat =~ s/\$8/$arg8/g;
      $itemFormat =~ s/\$9/$arg9/g;
    }

    my %descriptor = (
      crit=>$crit,
      item=>$item,
      group=>$group,
      format=>$itemFormat,
    );
    #writeDebug("group=$descriptor{group}, item=$descriptor{item} crit=$descriptor{crit}");
    push @theList, \%descriptor;
  }

  my $listSize = scalar(@theList);
  return '' unless $listSize;

  # sort it
  @theList = sort {$a->{crit} cmp $b->{crit}} @theList if $theSort =~ /nocase|on/;
  @theList = sort {$a->{crit} <=> $b->{crit}} @theList if $theSort eq 'num';
  @theList = reverse @theList if $theReverse;

  my $index = 0;
  my $group = '';
  my @anchors = ();

  my @result;
  foreach my $descriptor (@theList) {
    my $format = $descriptor->{format};
    my $item = $descriptor->{item};
    #writeDebug("index=$indexformat");

    # construct group format
    my $thisGroup = $descriptor->{group};
    my $groupFormat = '';
    if ($theGroup && $group ne $thisGroup) {
      $group = $thisGroup;

      # create an anchor to this group
      my $anchor = '';
      if ($theGroup =~ /\$anchor/) {
        $anchor = $this->getAnchorName($theTransliterate ? transliterate($group, \%map) : $group);
        if ($anchor) {
          push @anchors,
            {
            name => $anchor,
            title => $group,
            };
          $anchor = "id='$anchor'";
        }
      }

      $groupFormat = $theGroup;
      expandVariables(
        $groupFormat,
        anchor => $anchor,
        group => $group,
        index => $index + 1,
        count => $listSize,
        item => $item,
      );
    }
    # construct line
    my $text = $format;
    expandVariables(
      $text,
      group => $group,
      index => $index + 1,
      count => $listSize,
      item => $item,
    );

    # add to result
    push @result, "<div class='fltMakeIndexItem'>$groupFormat$text</div>";

    # keep track if indexes
    $index++;
  }

  return "" if $theHideEmpty && !@result;

  my $anchors = '';
  if (@anchors > $theAnchorThreshold) {
    if ($theHeader =~ /\$anchors/ || $theFooter =~ /\$anchors/) {
      $anchors = 
        "<div class='fltAnchors'>".
        join(' ', 
          map("<a href='#$_->{name}'>$_->{title}</a>", @anchors)
        ).
        '</div>';
    }
  }
  #writeDebug("anchors=$anchors");
  expandVariables($theHeader, count=>$listSize, anchors=>$anchors);
  expandVariables($theFooter, count=>$listSize, anchors=>$anchors);

  my @styles = ();
  push @styles, "column-count:$theCols" if $theCols && $theCols ne "automatic";
  push @styles, "column-width:$theColWidth" if $theColWidth;
  push @styles, "column-gap:$theColGap" if $theColGap;
  my $styles = @styles ? "style='".join(";", @styles)."'" : "";

  my $result = 
    "<div class='fltMakeIndexWrapper'>".
      $theHeader.
      "<div class='fltMakeIndexContainer' $styles>".
      join($theSeparator, @result).
      "</div>".
      $theFooter.
    "</div>";

  #writeDebug("result=$result");

  # count MAKEINDEX calls
  $this->{makeIndexCounter}++;

  return $result;
}

sub handleFormatList {
  my ($this, $params, $theTopic, $theWeb) = @_;
 
  #writeDebug("handleFormatList()");

  my $theList = $params->{_DEFAULT} // $params->{list} // '';
  my $thePattern = $params->{pattern} // '^\s*(.*?)\s*$';
  my $theFormat = $params->{format};
  my $theHeader = $params->{header} // '';
  my $theFooter = $params->{footer} // '';
  my $theSplit = $params->{split};
  my $theSeparator = $params->{separator};
  my $theLastSeparator = $params->{lastseparator};
  my $theLimit = $params->{limit};
  my $theSkip = $params->{skip} // 0; 
  my $theSort = $params->{sort} // 'off';
  my $theUnique = Foswiki::Func::isTrue($params->{unique}, 0);
  my $theExclude = $params->{exclude} // '';
  my $theInclude = $params->{include} // '';
  my $theCaseSensitive = Foswiki::Func::isTrue($params->{casesensitive}, 1);
  my $theReverse = Foswiki::Func::isTrue($params->{reverse}, 0);
  my $theSelection = $params->{selection};
  my $theMarker = $params->{marker};
  my $theMap = $params->{map};
  my $theNullFormat = $params->{null};
  my $theTokenize = $params->{tokenize};
  my $theHideEmpty = Foswiki::Func::isTrue($params->{hideempty}, 1);
  my $theReplace = $params->{replace};

  $theLimit //= -1;
  $theFormat //= '$1';
  $theSplit //= '\s*,\s*';
  $theMarker //= ' selected ';
  $theSeparator //= ', ';

  $theList = Foswiki::Func::expandCommonVariables($theList, $theTopic, $theWeb)
    if expandVariables($theList);

  #writeDebug("theList='$theList'");
  #writeDebug("thePattern='$thePattern'");
  #writeDebug("theFormat='$theFormat'");
  #writeDebug("theSplit='$theSplit'");
  #writeDebug("theSeparator='$theSeparator'");
  #writeDebug("theLastSeparator='$theLastSeparator'");
  #writeDebug("theLimit='$theLimit'");
  #writeDebug("theSkip='$theSkip'");
  #writeDebug("theSort='$theSort'");
  #writeDebug("theUnique='$theUnique'");
  #writeDebug("theExclude='$theExclude'");
  #writeDebug("theInclude='$theInclude'");

  my %map = ();
  if ($theMap) {
    %map = map {$_ =~ /^(.*)=(.*)$/, $1=>$2} split(/\s*,\s*/, $theMap);
  }

  my %tokens = ();
  my $tokenNr = 0;
  if ($theTokenize) {
    $theList =~ s/($theTokenize)/$tokenNr++; $tokens{'token_'.$tokenNr} = $1; 'token_'.$tokenNr/gems;
  }

  my @theList = split(/$theSplit/, $theList);

  if ($theReplace) {
    my %replace = map {$_ =~ /^(.*)=(.*)$/, $1=>$2} split(/\s*,\s*/, $theReplace);
    
    foreach my $item (@theList) {
      foreach my $pattern (keys %replace) {
        $item =~ s/$pattern/$replace{$pattern}/g;
      }
    }
  }


  if ($theTokenize && $tokenNr) {
    foreach my $item (@theList) {
      foreach my $token (keys %tokens) {
        $item =~ s/$token/$tokens{$token}/g;
      }
    }
  }

  if ($theSort ne 'off') {
    my $isNumeric;
    my %sorting = ();
    if ($theSort eq 'alpha' || $theSort eq 'on') {
      %sorting = map {$_ => uc($_)} @theList;
      $isNumeric = 0;
    } elsif ($theSort eq 'num') {
      %sorting = map {my $item = $_; my $num = ($item =~ /([+-]?\d+(?:\.\d+)?)/ ? $1:0) ; $item => $num} @theList;
      $isNumeric = 1;
    } elsif ($theSort eq 'random') {
      %sorting = map {$_ => rand()} @theList;
      $isNumeric = 1;
    }
    if (defined $isNumeric) {
      if ($isNumeric) {
        @theList = sort { $sorting{$a} <=> $sorting{$b} } @theList;
      } else {
        @theList = sort { $sorting{$a} cmp $sorting{$b} } @theList;
      }
    }
  }
  @theList = reverse @theList if $theReverse;

  my $index = 0;
  my $hits = 0;
  my @result;

  if ($theLimit) {
    my %seen = ();
    foreach my $item (@theList) {
      next if $item =~ /^$/; # skip empty elements

      #writeDebug("found '$item'");
      if ($theCaseSensitive) {
        next if $theExclude && $item =~ /^($theExclude)$/;
        next if $theInclude && $item !~ /^($theInclude)$/;
      } else {
        next if $theExclude && $item =~ /^($theExclude)$/i;
        next if $theInclude && $item !~ /^($theInclude)$/i;
      }


      $index++;
      next if $index <= $theSkip;
      last if $theLimit > 0 && $hits >= $theLimit;

      my $line = $theFormat;

      if ($item =~ m/$thePattern/) {
        my $arg1 = $1 // '';
        my $arg2 = $2 // '';
        my $arg3 = $3 // '';
        my $arg4 = $4 // '';
        my $arg5 = $5 // '';
        my $arg6 = $6 // '';
        my $arg7 = $7 // '';
        my $arg8 = $8 // '';
        my $arg9 = $9 // '';
        my $arg10 = $10 // '';
        my $arg11 = $11 // '';
        my $arg12 = $12 // '';
        my $arg13 = $13 // '';
        my $arg14 = $14 // '';
        my $arg15 = $15 // '';
        my $arg16 = $16 // '';
        my $arg17 = $17 // '';
        my $arg18 = $18 // '';
        my $arg19 = $19 // '';
        my $arg20 = $20 // '';


        $line =~ s/\$20/$arg20/g;
        $line =~ s/\$19/$arg19/g;
        $line =~ s/\$18/$arg18/g;
        $line =~ s/\$17/$arg17/g;
        $line =~ s/\$16/$arg16/g;
        $line =~ s/\$15/$arg15/g;
        $line =~ s/\$14/$arg14/g;
        $line =~ s/\$13/$arg13/g;
        $line =~ s/\$12/$arg12/g;
        $line =~ s/\$11/$arg11/g;
        $line =~ s/\$10/$arg10/g;
        $line =~ s/\$1/$arg1/g;
        $line =~ s/\$2/$arg2/g;
        $line =~ s/\$3/$arg3/g;
        $line =~ s/\$4/$arg4/g;
        $line =~ s/\$5/$arg5/g;
        $line =~ s/\$6/$arg6/g;
        $line =~ s/\$7/$arg7/g;
        $line =~ s/\$8/$arg8/g;
        $line =~ s/\$9/$arg9/g;

      } else {
        next;
      }

      $line =~ s/\$map\((.*?)\)/($map{$1}||$1)/ge;

      #writeDebug("after susbst '$line'");
      if ($theUnique) {
        next if $seen{$line};
        $seen{$line} = 1;
      }

      $line =~ s/\$index/$index/ge;
      if ($theSelection && $item =~ /$theSelection/) {
        $line =~ s/\$marker/$theMarker/g 
      } else {
        $line =~ s/\$marker//g;
      }
      push @result, $line unless ($theHideEmpty && $line eq '');
      $hits++;
    }
  }

  my $result = '';
  if ($hits == 0) {
    return '' unless defined $theNullFormat;
    $result = $theNullFormat;
  } else {
    if (defined($theLastSeparator) && ($index > 1)) {
      my $lastElement = pop(@result);
      $result = join($theSeparator, @result) . $theLastSeparator . $lastElement;
    } else {
      $result = join($theSeparator, @result);
    }
  }

  my $count = scalar(@theList);

  $result = $theHeader.$result.$theFooter;
  $result =~ s/\$hits/$hits/g;
  $result =~ s/\$count\b/$count/g;

  expandVariables($result);
  return $result;
}

sub getAnchorName {
  my ($this, $text) = @_;

  my $anchor = substr($text, 0, 1);
  $anchor = $anchor.'_'.$this->{makeIndexCounter};
  return '' if $this->{seenAnchorNames}{$anchor};
  $this->{seenAnchorNames}{$anchor} = 1;

  return $anchor;
}

sub expandVariables {
  my ($text, %params) = @_;

  return 0 unless $text;

  my $found = 0;

  foreach my $key (keys %params) {
    $found = 1 if $text =~ s/\$$key\b/$params{$key}/g;
  }

  $found = 1 if $text =~ s/\$perce?nt/\%/g;
  $found = 1 if $text =~ s/\$nop//g;
  $found = 1 if $text =~ s/\$n/\n/g;
  $found = 1 if $text =~ s/\$dollar/\$/g;

  $_[0] = $text if $found;

  return $found;
}

sub transliterate {
  my ($string, $map) = @_;

  # apply own decoding if present
  if ($map) {
    my $found = 0;
    foreach my $pattern (keys %$map) {
      my $replace = $map->{$pattern} // ''; 
      if ($string =~ s/^$pattern/$replace/g) {
        $found = 1;
      }
    }
    return $string if $found;
  } else {
    $string = Text::Unidecode::unidecode($string);
  }

  return $string;
}

sub inlineError {
  return "<span class='foswikiAlert'>".$_[0]."</span>";
}

sub writeDebug {
  print STDERR "- FilterPlugin - $_[0]\n" if TRACE;
}

1;
