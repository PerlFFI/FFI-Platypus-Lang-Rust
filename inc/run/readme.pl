use strict;
use warnings;
use autodie;
use Pod::Abstract;
use Pod::Simple::Text;

my $root = Pod::Abstract->load_file('lib/FFI/Platypus/Lang/Rust.pm');

$_->detach for $root->select('//#cut');

pod2txt( $root => 'README' );

sub pod2txt
{
  my($pod, $filename) = @_;
  
  my $parser = Pod::Simple::Text->new;
  my $text;
  $parser->output_string( \$text );
  $parser->parse_string_document( $pod->pod );
  
  open my $fh, '>', $filename;
  print $fh $text;
  close $fh;
}
