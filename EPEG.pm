package Image::EPEG;

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
our $VERSION = '0.01';

bootstrap Image::EPEG $VERSION;

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
		$self->{ img } = Image::EPEG::_epeg_memory_open( $$input, length($$input) );
	}
	elsif( $input )
	{
		# new from file
		$self->{ img } = Image::EPEG::_epeg_file_open( $input );
	}

	# return undef on a failed open
	return ref $self->img eq 'Epeg_Image' 
		? $self : undef;
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
		Image::EPEG::_epeg_size_get( $self->img );
}


sub set_quality
{
	my $self = shift;
	my $quality = shift;
	Image::EPEG::_epeg_quality_set( $self->img, $quality );
}


sub set_comment
{
	my $self = shift;
	my $comment = shift;
	Image::EPEG::_epeg_comment_set( $self->img, $comment );
}


sub get_comment
{
	my $self = shift;
	return Image::EPEG::_epeg_comment_get( $self->img );
}


sub resize
{
	my $self = shift;
	my $width = shift;
	my $height = shift;
	my $aspect_ratio_mode = shift || IGNORE_ASPECT_RATIO;
	
	# ignore the aspect ratio
	if( $aspect_ratio_mode == IGNORE_ASPECT_RATIO )
	{
		Image::EPEG::_epeg_decode_size_set( $self->img, $width, $height );
		return 1;
	}

	# maintain the aspect ratio
	my ($w, $h) = ($self->get_width(), $self->get_height());
	my ($new_w, $new_h) = (0, 0);

	if( $w * $height > $h * $height )
	{
		$new_w = $width;
		$new_h = $height * $h / $w;
	}
	else
	{
		$new_h = $height;
		$new_w = $width * $w / $h;
	}

	Image::EPEG::_epeg_decode_size_set( $self->img, $new_w, $new_h );
	return 1;
}


sub get_data
{
	my $self = shift;
	my $data = Image::EPEG::_epeg_get_data( $self->img );
	Image::EPEG::_epeg_close( $self->img );
	return $data; 
}


sub write_file
{
	my $self = shift;
	my $path = shift;
	Image::EPEG::_epeg_write_file( $self->img, $path );
	Image::EPEG::_epeg_close( $self->img );
	return 1;
}


1;

__END__


=head1 NAME

EPEG - Perl extension for EPEG

=head1 SYNOPSIS

  use Image::EPEG qw(:constants);
  my $epg = new Image::EPEG( "test.jpg" );
  $epg->resize( 150, 150, MAINTAIN_ASPECT_RATIO );
  $epg->write_file( "test_resized.jpg" );

=head1 DESCRIPTION

Perl wrapper to the alarmingly fast jpeg manipulation library "Epeg".

=head2 Methods

=over 4

=item * new( [FILENAME|DATA REFERENCE] )

=item * get_height()

=item * get_width()

=item * set_quality( [0-100] )

=item * resize( WIDTH, HEIGHT, [Aspect Ratio Mode] )

=item * write_file( FILENAME )

=item * get_data()

=back

=head1 AUTHOR

Michael Curtis E<lt>mcurtis@yahoo-inc.com<gt>

=head1 SEE ALSO

L<http://gatekeeper.dec.com/pub/BSD/NetBSD/NetBSD-current/pkgsrc/graphics/epeg/README.html>

=cut
