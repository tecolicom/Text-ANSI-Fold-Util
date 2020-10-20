use v5.14;
use warnings;
use Test::More 0.98;
use utf8;

use Text::ANSI::Fold::Util qw(ansi_expand);
use Text::Tabs;

Text::ANSI::Fold->configure(expand => 1);

sub r { $_[0] =~ s/(\S+)/\e[31m$1\e[m/gr }

for my $t (split "\n", <<"END"
#1234567890123456789
0	89
0123	89
01234567	67
END
) {
    next if $t =~ /^#/;
    my $x = expand $t;
    for my $p (
	[ $t => expand($x) ],
	[ r($t) => r(expand($x)) ],
	)
    {
	my($s, $a) = @$p;
	is(expand($s), $a, sprintf("expand(\"%s\") -> \"%s\"", $s, $a));
    }
}

done_testing;
