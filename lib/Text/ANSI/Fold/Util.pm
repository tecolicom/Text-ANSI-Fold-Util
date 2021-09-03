package Text::ANSI::Fold::Util;
our $VERSION = "0.05";

use v5.14;
use utf8;
use warnings;
use Data::Dumper;

use Exporter qw(import);
our @EXPORT_OK;
our %EXPORT_TAGS = ( all => [ @EXPORT_OK ] );

use List::Util qw(max);
use Text::ANSI::Fold qw(ansi_fold);

=encoding utf-8

=head1 NAME

Text::ANSI::Fold::Util - Text::ANSI::Fold utilities (width, substr, expand)

=head1 VERSION

Version 0.05

=head1 SYNOPSIS

    use Text::ANSI::Fold::Util qw(:all);
    use Text::ANSI::Fold::Util qw(ansi_width ansi_substr ansi_expand);
    ansi_width($text);
    ansi_substr($text, $offset, $width [, $replacement]);
    ansi_expand($text);
    ansi_unexpand($text);

    use Text::ANSI::Fold::Util;
    Text::ANSI::Fold::Util::width($text);
    Text::ANSI::Fold::Util::substr($text, ...);
    Text::ANSI::Fold::Util::expand($text);
    Text::ANSI::Fold::Util::unexpand($text);

=head1 DESCRIPTION

This is a collection of utilities using Text::ANSI::Fold module.  All
functions are aware of ANSI terminal sequence.

=head1 FUNCTION

There are exportable functions start with B<ansi_> prefix, and
unexportable functions without them.

=over 7

=cut


=item B<width>(I<text>)

=item B<ansi_width>(I<text>)

Returns visual width of given text.

=cut

BEGIN { push @EXPORT_OK, qw(&ansi_width) }
sub ansi_width { goto &width }

sub width {
    (ansi_fold($_[0], -1))[2];
}


=item B<substr>(I<text>, I<offset>, I<width> [, I<replacement>])

=item B<ansi_substr>(I<text>, I<offset>, I<width> [, I<replacement>])

Returns substring just like Perl's B<substr> function, but string
position is calculated by the visible width on the screen instead of
number of characters.

If an optional I<replacement> parameter is given, replace the substring
by the replacement and return the entire string.

It does not cut the text in the middle of multi-byte character, of
course.  Its behavior depends on the implementation of lower module.

=cut

BEGIN { push @EXPORT_OK, qw(&ansi_substr) }
sub ansi_substr { goto &substr }

sub substr {
    my($text, $offset, $length, $replacement) = @_;
    if ($offset < 0) {
	$offset = max(0, $offset + ansi_width($text));
    }
    my @s = Text::ANSI::Fold
	->new(text => $text, width => [ $offset, $length // -1, -1 ])
	->chops;
    if (defined $replacement) {
	$s[0] . $replacement . ($s[2] // '');
    } else {
	$s[1];
    }
}


=item B<expand>(I<text>, ...)

=item B<ansi_expand>(I<text>, ...)

Expand tabs.  Interface is compatible with L<Text::Tabs>::expand().

Default tabstop is 8, and can be accessed through
C<$Text::ANSI::Fold::Util::tabstop> variable.

Option for underlying B<ansi_fold> can be passed by first parameter as
an array reference, as well as C<< Text::ANSI::Fold->configure >> call.

    my $opt = [ tabhead => 'T', tabspace => '_' ];
    ansi_expand($opt, @text);

    Text::ANSI::Fold->configure(tabhead => 'T', tabspace => '_');
    ansi_expand(@text);

=cut

BEGIN { push @EXPORT_OK, qw(&ansi_expand $tabstop) }
sub ansi_expand { goto &expand }

our $tabstop = 8;
our $spacechar = ' ';

sub expand {
    my @opt = ref $_[0] eq 'ARRAY' ? @{+shift} : ();
    my @l = map {
	s{^(.*\t)}{
	    (ansi_fold($1, -1, expand => 1, tabstop => $tabstop, @opt))[0];
	}mger;
    } @_;
    wantarray ? @l : $l[0];
}

=item B<unexpand>(I<text>, ...)

=item B<ansi_unexpand>(I<text>, ...)

Unexpand tabs.  Interface is compatible with
L<Text::Tabs>::unexpand().  Default tabstop is same as C<ansi_expand>.

Please be aware that, current implementation may leave some redundant
color designation code.

=cut

BEGIN { push @EXPORT_OK, qw(&ansi_unexpand) }
sub ansi_unexpand { goto &unexpand }

my $reset_re    = qr{ \e \[ [0;]* m }x;
my $erase_re    = qr{ \e \[ [\d;]* K }x;
my $end_re      = qr{ $reset_re | $erase_re }x;
my $csi_re      = qr{
    # see ECMA-48 5.4 Control sequences
    \e \[		# csi
    [\x30-\x3f]*	# parameter bytes
    [\x20-\x2f]*	# intermediate bytes
    [\x40-\x7e]		# final byte
}x;

our $REMOVE_REDUNDANT = 1;

sub unexpand {
    my @opt = ref $_[0] eq 'ARRAY' ? @{+shift} : ();
    my @l = map {
	s{ (.*[ ].*) }{ _unexpand($1) }xmger
    } @_;
    if ($REMOVE_REDUNDANT) {
	for (@l) {
	    1 while s{ (?<c>$csi_re+) \K (?<s>[^\e]*) $end_re \g{c} }{$+{s}}xg;
	}
    }
    wantarray ? @l : $l[0];
}

sub _unexpand {
    my $s = shift;
    my $ret = '';
    my $width = $tabstop;
    state $fold = Text::ANSI::Fold->new;
    while (length $s) {
	my($a, $b, $w) = $fold->fold($s, width => $width);
	if ($w == $width) {
	    $s = $b;
	    $ret .= $a =~ s/([ ]+)(?= $end_re* $)/\t/xr;
	    $width = $tabstop;
	} else {
	    if ($b eq '') {
		$ret .= $a;
		last;
	    }
	    $width += $tabstop;
	}
    }
    $ret;
}

=back

=cut

1;

__END__

=head1 SEE ALSO

L<Text::ANSI::Fold::Util>, L<https://github.com/kaz-utashiro/Text-ANSI-Fold-Util>

L<Text::ANSI::Fold>, L<https://github.com/kaz-utashiro/Text-ANSI-Fold>

L<Text::Tabs>

=head1 LICENSE

Copyright 2020 Kazumasa Utashiro.

This library is free software; you can redistribute it and/or modify
it under the same terms as Perl itself.

=head1 AUTHOR

Kazumasa Utashiro E<lt>kaz@utashiro.comE<gt>

=cut

#  LocalWords:  ansi utf substr unexpand exportable unexportable
#  LocalWords:  tabstop tabhead tabspace Kazumasa Utashiro
