use Hook::LexWrap;
print "1..16\n";

sub ok { print "ok $_[0]\n" }

sub actual { ok $_[0] }


actual 1;

{ 
	my $lexical = wrap actual,
			pre  => sub { ok 2 },
			post => sub { ok 4 };

	wrap actual, pre => sub { $_[0]++ };

	my $x = 2;
	actual $x;
}

wrap *main::actual, post => sub { ok 6 };

actual my $x = 4;

no warnings 'bareword';
eval { wrap other, pre => sub { print "not ok 7\n" } } or ok 7;

eval { wrap actual, pre => 1 } and print "not ";
ok 8;

eval { wrap actual, post => [] } and print "not ";
ok 9;

BEGIN { *{CORE::GLOBAL::sqrt} = sub { CORE::sqrt(shift) } }
wrap 'CORE::GLOBAL::sqrt', pre => sub { $_[0]++ };

$x = 99;
ok sqrt($x);

sub temp { ok $_[0] };

my $sub = wrap \&temp,
	pre  => sub { ok $_[0]-1 },
	post => sub { ok $_[0]+1 };

$sub->(12);
temp(14);

$SIG{__WARN__} = sub { ok 15 };
eval { wrap \&temp, pre => sub { ok $_[0]-1 }; 1 } and ok 16;
