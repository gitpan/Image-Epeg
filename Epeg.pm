package Image::Epeg;

use 5.006;
use strict;
use warnings;
use Carp;

require Exporter;
require DynaLoader;
use AutoLoader;

our @ISA = qw(Exporter DynaLoader);
our %EXPORT_TAGS = ( 'constants' => [ qw(MAINTAIN_ASPECT_RATIO IGNORE_ASPECT_RATIO) ] );
our @EXPORT_OK = ( @{ $EXPORT_TAGS{'constants'} } );
our @EXPORT = qw();
our $VERSION = '0.07';

bootstrap Image::Epeg $VERSION;

use constant MAINTAIN_ASPECT_RATIO => 1;
use constant IGNORE_ASPECT_RATIO => 2;

sub new
{
	my $class = shift;
	my $self = bless { img => undef }, $class;
	
	my $input = shift;
	if( ref $input eq 'SCALAR' )
	{
		# new from data
		$self->{ img } = Image::Epeg::_epeg_memory_open( $$input, length($$input) );
	}
	elsif( $input )
	{
		# new from file
		$self->{ img } = Image::Epeg::_epeg_file_open( $input );
	}

	# return undef on a failed open
	return ref $self->img eq 'Epeg_Image' 
		? $self : undef;
}


sub DESTROY
{
	my $self = shift;

	Image::Epeg::_epeg_close( $self->img )
		if( ref($self->img) eq 'Epeg_Image' &&
			!exists $self->{ failed } );
}


sub img		{ return $_[0]->{ img }; }
sub height	{ return $_[0]->{ height }; }
sub width	{ return $_[0]->{ width }; }


sub get_height
{
	my $self = shift;
	$self->_init_size() unless( $self->height );
	return $self->height;
}


sub get_width
{
	my $self = shift;
	$self->_init_size() unless( $self->width );
	return $self->width;
}


sub _init_size
{
	my $self = shift; 
	($self->{ width }, $self->{ height }) =
		Image::Epeg::_epeg_size_get( $self->img );
}


sub set_quality
{
	my $self = shift;
	my $quality = shift;
	$quality = 100 if( $quality < 0 || $quality > 100 );
	Image::Epeg::_epeg_quality_set( $self->img, $quality );
}


sub set_comment
{
	my $self = shift;
	my $comment = shift;
	Image::Epeg::_epeg_comment_set( $self->img, $comment );
}


sub get_comment
{
	my $self = shift;
	return Image::Epeg::_epeg_comment_get( $self->img );
}


sub resize
{
	my $self = shift;
	my $bw = shift;		# boundary width
	my $bh = shift;		# boundary height
	my $aspect_ratio_mode = shift || IGNORE_ASPECT_RATIO;
	
	# make sure we can resize to this wxh
	my ($w, $h) = ($self->get_width(), $self->get_height());
	if( ($w <= 0 || $h <= 0) ||
		($bw > $w && $bh > $h) )
	{
		return undef;
	}

	# ignore the aspect ratio
	if( $aspect_ratio_mode == IGNORE_ASPECT_RATIO )
	{
		Image::Epeg::_epeg_decode_size_set( $self->img, $bw, $bh );
		return 1;
	}

	# maintain the aspect ratio
	my ($new_w, $new_h) = (0, 0);
	if( $w * $bh < $bw * $h )
	{
		$new_w = int($w * $bh/$h + .5);
		$new_h = $bh;
	}
	else
	{
		$new_w = $bw;
		$new_h = int($h * $bw/$w + .5);
	}

	Image::Epeg::_epeg_decode_size_set( $self->img, $new_w, $new_h );
	return 1;
}


sub get_data
{
	my $self = shift;
	my $data = Image::Epeg::_epeg_get_data( $self->img );

	if( !defined $data )
	{
		$self->{ failed } = 1;
		return undef;
	}

	return $data;
}


sub write_file
{
	my $self = shift;
	my $path = shift;
	my $rv = Image::Epeg::_epeg_write_file( $self->img, $path );
	
	if( !$rv )
	{
		$self->{ failed } = 1;
		return undef;
	}

	return 1;
}


1;

__END__


=head1 NAME

Epeg - Thumbnail jpegs at lightning speed

=head1 SYNOPSIS

  use Image::Epeg qw(:constants);
  my $epg = new Image::Epeg( "test.jpg" );
  $epg->resize( 150, 150, MAINTAIN_ASPECT_RATIO );
  $epg->write_file( "test_resized.jpg" );

=head1 DESCRIPTION

Perl wrapper to the ultra-fast jpeg manipulation library "Epeg". This library can be used to thumbnail (resize down) jpegs, set comments and quality. NOTE: The resize() method *must* be called with valid arguments or get_data() and write_file() will fail.

=head2 Methods

=over 4

=item * new( [filname|data ref] )

=item * get_height()

=item * get_width()

=item * set_quality( [0-100] )

=item * set_comment( [comment] )

=item * get_comment()

=item * resize( [width], [height], [Aspect Ratio Mode] )

The resize() method can only be used to downsize images. If neither the width or height specified is less than the source image it will return undef.

=item * write_file( [filename] )

=item * get_data()

=back

=head1 AUTHOR

Michael Curtis E<lt>mike@beatbot.comE<gt>

=head1 SEE ALSO

L<http://gatekeeper.dec.com/pub/BSD/NetBSD/NetBSD-current/pkgsrc/graphics/epeg/README.html>

=cut
