package Hook::LexWrap;
our $VERSION = '0.01';
use 5.006;
use Carp;

sub import { *{caller()."::wrap"} = \&wrap }

sub wrap (*@) {
	my ($typeglob, %wrapper) = @_;
	$typeglob = (ref $typeglob || $typeglob =~ /::/)
		? $typeglob
		: caller()."::$typeglob";
	my $original = ref $typeglob eq 'CODE' && $typeglob
		     || *$typeglob{CODE}
		     || croak "Can't wrap non-existent subroutine ", $typeglob;
	croak "'$_' value is not a subroutine reference"
		foreach grep {$wrapper{$_} && ref $wrapper{$_} ne 'CODE'}
			qw(pre post);
	my ($dtor, $unwrap, $args, $imposter);
	no warnings 'redefine';
	$imposter = sub { goto &$original unless *$dtor{CODE};
			     &{$wrapper{pre}} if $wrapper{pre}; $args = \@_;
			     goto &{bless sub { goto &$original }, "$imposter"}
			   };
	$dtor = $imposter."::DESTROY";
	*$dtor = sub { $wrapper{post}->(@$args) if $wrapper{post};
		       undef *$dtor if $unwrap
		     };
	ref $typeglob eq 'CODE' and return defined wantarray
		? $imposter
		: carp "Uselessly wrapped subroutine reference in void context";
	*{$typeglob} = $imposter;
	return unless defined wantarray;
	return bless sub{ $unwrap=1 }, 'Hook::LexWrap::Unwrap';
}

sub Hook::LexWrap::Unwrap::DESTROY { $_[0]->() }

1;

__END__


=head1 NAME

Hook::LexWrap - Lexically scoped subroutine wrappers

=head1 VERSION

This document describes version 0.01 of Hook::LexWrap,
released September 17, 2001.

=head1 SYNOPSIS

	use Hook::LexWrap;

	sub doit { print "[doit:", caller, "]"; return {my=>"data"} }

	SCOPED: {
		wrap doit,
			pre  => sub { print "[pre1: @_]\n" },
			post => sub { print "[post1:@_]\n"; $_[1]=9; };

		my $temporarily = wrap doit,
			post => sub { print "[post2:@_]\n" },
			pre  => sub { print "[pre2: @_]\n  "};

		@args = (1,2,3);
		doit(@args);	# pre2->pre1->doit->post1->post2
	}

	@args = (4,5,6);
	doit(@args);		# pre2->doit->post2


=head1 DESCRIPTION

Hook::LexWrap allows you to install a pre- or post-wrapper (or both)
around an existing subroutine. Unlike other modules that provide this
capacity (e.g. Hook::PreAndPost and Hook::WrapSub), Hook::LexWrap
implements wrappers in such a way that the standard C<caller> function
works correctly within the wrapped subroutine.

To install a prewrappers, you write:

        use Hook::LexWrap;

        wrap 'subroutine_name', pre => \&some_other_sub;

   #or: wrap *subroutine_name,  pre => \&some_other_sub;

The first argument to C<wrap> is a string containing the name of the
subroutine to be wrapped (or the typeglob containing it, or a
reference to it). The subroutine name may be qualified, and the
subroutine must already be defined. The second argument indicates the
type of wrapper being applied and must be either C<'pre'> or
C<'post'>. The third argument must be a reference to a subroutine that
implements the wrapper.

To install a post-wrapper, you write:

        wrap 'subroutine_name', post => \&yet_another_sub;

   #or: wrap *subroutine_name,  post => \&yet_another_sub;

To install both at once:

        wrap 'subroutine_name',
             pre  => \&some_other_sub,
             post => \&yet_another_sub;

or:

        wrap *subroutine_name,
             post => \&yet_another_sub,  # order in which wrappers are
             pre  => \&some_other_sub;   # specified doesn't matter

Once they are installed, the pre- and post-wrappers will be called before
and after the subroutine itself, and will be passed the same argument list.

The original subroutine is called using the I<magic C<goto>>, so C<wantarray>
and C<caller> behave exactly as they would, if it had not been wrapped.


=head2 Lexically scoped wrappers

Normally, any wrappers installed by C<wrap> remain attached to the 
subroutine until it is undefined. However, it is possible to make
specific wrappers lexically bound, so that they operate only until
the end of the scope in which they're created (or until some other
specific point in the code).

If C<wrap> is called in a I<non-void> context:

        my $lexical = wrap 'sub_name', pre => \&wrapper;

it returns a special object corresponding to the particular wrapper being
placed around the original subroutine. When that object is destroyed
-- when its container variable goes out of scope, or when its
reference count otherwise falls to zero (e.g. C<undef $lexical>), or 
when it is explicitly destroyed (C<$lexical-E<gt>DESTROY>) --
the corresponding wrapper is removed from around
the original subroutine. Note, however, that all other wrappers around the
subroutine are preserved.


=head2 Anonymous wrappers

If the subroutine to be wrapped is passed as a reference (rather than by name
or by typeglob), C<wrap> does not install the wrappers around the 
original subroutine. Instead it generates a new subroutine which acts
as if it were the original with those wrappers around it.
It then returns a reference to that new subroutine. Only calls to the original
through that wrapped reference invoke the wrappers. Direct by-name calls to
the original, or calls through another reference, do not.

If the original is subsequently wrapped by name, the anonymously wrapped
subroutine reference does not see those wrappers. In other words,
wrappers installed via a subroutine reference are completely independent
of those installed via the subroutine's name (or typeglob).

For example:

        sub original { print "ray" }

        # Wrap anonymously...
        my $anon_wrapped = wrap \&original, pre => sub { print "do..." };

        # Show effects...
        original();             # prints "ray"
        $anon_wrapped->();      # prints "do..ray"

        # Wrap nonymously...
        wrap *original,
                pre  => sub { print "fa.." },
                post => sub { print "..mi" };

        # Show effects...
        original();             #   now prints "fa..ray..mi"
        $anon_wrapped->();      # still prints "do...ray"


=head1 LIMITATIONS

=over

=item *

In the current version, the post-wrapper is I<not> passed the subroutine's
return value.

=item *

Although the original subroutine sees C<wantarray> and C<caller> as normal,
the pre- and post-wrappers do not.

=back


=head1 DIAGNOSTICS

=over

=item C<Can't wrap non-existent subroutine %s>

An attempt was made to wrap a subroutine that was not defined at the
point of wrapping.

=item C<'pre' value is not a subroutine reference>

The value passed to C<wrap> after the C<'pre'> flag was not
a subroutine reference. Typically, someone forgot the C<sub> on
the anonymous subroutine:

        wrap 'subname', pre => { your_code_here() };

and Perl interpreted the last argument as a hash constructor.

=item C<'post' value is not a subroutine reference>

The value passed to C<wrap> after the C<'post'> flag was not
a subroutine reference.

=item C<Uselessly wrapped subroutine reference in void context> (warning only)

When the subroutine to be wrapped is passed as a subroutine reference,
C<wrap> does not install the wrapper around the original, but instead
returns a reference to a subroutine which wraps the original
(see L<Anonymous wrappers>). 

However, there's no point in doing this if you don't catch the resulting
subroutine reference.

=back

=head1 AUTHOR

Damian Conway (damian@conway.org)


=head1 BLAME

Schwern made me do this (by implying it wasn't possible ;-)


=head1 BUGS

There are undoubtedly serious bugs lurking somewhere in code this funky :-)

Bug reports and other feedback are most welcome.


=head1 COPYRIGHT

      Copyright (c) 2001, Damian Conway. All Rights Reserved.
    This module is free software. It may be used, redistributed
        and/or modified under the same terms as Perl itself.
