use Hook::LexWrap;
print "1..33\n";

sub ok   { print "ok $_[0]\n" }
sub fail(&) { print "not " if $_[0]->() }

sub actual { ok $_[0]; }


actual 1;

{ 
	my $lexical = wrap actual,
			pre  => sub { ok 2 },
			post => sub { ok 4 };

	wrap actual, pre => sub { $_[0]++ };

	my $x = 2;
	actual $x;
	1;	# delay destruction
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

{
	local $SIG{__WARN__} = sub { ok 15 };
	eval { wrap \&temp, pre => sub { ok $_[0]-1 }; 1 } and ok 16;
}

use Carp;

sub wrapped_callee {
	return join '|', caller(0);
}

wrap wrapped_callee,
	pre =>sub{
		print "not " unless $_[0] eq join '|', caller(0);
		ok 17
	},
	post=>sub{
		print "not " unless $_[0] eq join '|', caller(0);
		ok 18
	};

sub raw_callee {
	return join '|', caller(0);
}

print "not " unless wrapped_callee(scalar raw_callee); ok 19;

sub scalar_return { return 'string' }
wrap scalar_return, post => sub { $_[-1] .= 'ent' };
print "not " unless scalar_return eq 'stringent'; ok 20;

sub list_return { return (0..9) }
wrap list_return, post => sub { @{$_[-1]} = reverse @{$_[-1]} };
my @result = list_return;
for (0..9) {
	print "not " and last unless $_ + $result[$_] == 9;
}
ok 21;

sub shorted_scalar { return 2 };
wrap shorted_scalar, pre => sub { $_[-1] = 1 };
fail { shorted_scalar != 1 }; ok 22;

sub shorted_list { return (2..9) };
{
	my $lexical = wrap shorted_list, pre => sub { $_[-1] = [1..9] };
	fail { (shorted_list)[0] != 1 }; ok 23;
}
{
	my $lexical = wrap shorted_list, pre => sub { $_[-1] = 1 };
	fail { (shorted_list)[0] != 1 }; ok 24;
}
{
	my $lexical = wrap shorted_list, pre => sub { @{$_[-1]} = (1..9) };
	fail { (shorted_list)[0] != 1 }; ok 25;
}
{
	my $lexical = wrap shorted_list, pre => sub { @{$_[-1]} = [1..9] };
	fail { (shorted_list)[0]->[0] != 1 }; ok 26;
}
{
	my $lexical = wrap shorted_list, post => sub { $_[-1] = [1..9] };
	fail { (shorted_list)[0] != 1 }; ok 27;
}
{
	my $lexical = wrap shorted_list, post => sub { $_[-1] = 1 };
	fail { (shorted_list)[0] != 1 }; ok 28;
}
{
	my $lexical = wrap shorted_list, post => sub { @{$_[-1]} = (1..9) };
	fail { (shorted_list)[0] != 1 }; ok 29;
}
{
	my $lexical = wrap shorted_list, post => sub { @{$_[-1]} = [1..9] };
	fail { (shorted_list)[0]->[0] != 1 }; ok 30;
}

sub howmany { ok 32 if @_ == 3 }

wrap howmany,
	pre  => sub { ok 31 if @_ == 4 },
	post => sub { ok 33 if @_ == 4 };

howmany(1..3);
