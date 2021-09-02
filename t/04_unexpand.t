use v5.14;
use warnings;
use Test::More 0.98;
use utf8;
use open IO => ':utf8', ':std';
use Encode;

use Text::ANSI::Fold::Util qw(ansi_expand ansi_unexpand);
use Text::Tabs;
use Data::Dumper;
{
    no warnings 'redefine';
    *Data::Dumper::qquote = sub { qq["${\(shift)}"] };
    $Data::Dumper::Useperl = 1;
}

Text::ANSI::Fold->configure(expand => 1);

sub r { $_[0] =~ s/(\S+)/\e[31m$1\e[m/gr }

my $pattern = <<"END";
#12345670123456701
0       01      01
        0       01
0123            01
01234567        01
                01
END

for my $t (split "\n", $pattern) {
    next if $t =~ /^#/;
    my $u = unexpand $t;
    for my $p (
	[ $t => $u ],
	[ r($t) => r($u) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_unexpand($s), $a,
	   sprintf("ansi_unexpand(\"%s\") -> \"%s\"", $s, $a));
    }
}

for my $t ($pattern) {
    my $u = unexpand $t;
    for my $p (
	[ $t => $u ],
	[ r($t) => r($u) ],
	)
    {
	my($s, $a) = @$p;
	is(ansi_unexpand($s), $a,
	   sprintf("ansi_unexpand(\"%s\") -> \"%s\"", $s, $a));
    }

    my @t = split /^/m, $t;
    my @u = unexpand @t;
    my @rt = map r($_), @t;
    my @ru = map r($_), @u;
    for my $p (
	[ \@t => \@u ],
	[ \@rt => \@ru ],
	)
    {
	my($s, $a) = @$p;
	is_deeply([ ansi_unexpand(@$s) ], $a,
		  sprintf("expand(\"%s\") -> \"%s\"", Dumper $s, Dumper $a));
    }
}

binmode STDOUT, ':encoding(utf8)';
binmode STDERR, ':encoding(utf8)';

for (
     [ '一' => '一', 'no tab' ],
     [ '        x' => "\tx", 'head' ],
     [ '一      x' => "一\tx", 'middle' ],
     [ '一二三  x' =>
       "一二三\tx",'middle' ],
     [ '一二三四        x' =>
       "一二三四\tx", 'boundary' ],
     [ 'x一二三四       x' =>
       "x一二三四\tx", 'wide char on the boundary' ],
     [ 'x一二三四一二三四       x' =>
       "x一二三四一二三四\tx", 'double wide boundary' ],
    ) {
    my($s, $a, $msg) = @$_;
    is(ansi_unexpand($s), $a, $msg);
}

done_testing;
