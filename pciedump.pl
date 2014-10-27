#!/usr/bin/perl

use strict;
use warnings;

use YAML::XS qw/LoadFile/;
use Data::Dumper;

open my $fh, '<',"sample.txt" or die "$!\n";

my @lines = <$fh>;

close $fh or die "$!\n";

my @data   = ();

foreach my $line (@lines){
		$line =~ s/\x0D?\x0A$//g; #改行削除
		my @byte = split / /,$line;  
		my $offset = shift @byte;
		push @data,\@byte;

}

my $config = LoadFile('config.yaml');

foreach my $addr (sort keys(%$config)){

		&show_register_info($addr,$config);
}




#ここからポインタを辿る
print "PCI Extended Capability\n";
my $next_pointer = &get_byte(0x034,\@data);
while(1){
		my $id   = &get_byte($next_pointer,\@data);
		print sprintf "Offset:%0xh ID:%0xh\n",$next_pointer,$id;
		$next_pointer = &get_byte($next_pointer+1,\@data);
#		my $tmp = <STDIN>;
		last if $next_pointer == 0;
}

print "PCI express Capability\n";
$next_pointer = 0x100;
while(1){
		my $capability   = &get_dword($next_pointer,\@data);
		my $id = $capability & 0x00ff;
		print sprintf "Offset:%0xh ID:%0xh \n",$id,$next_pointer;
		$next_pointer = $capability >> 20;
#		my $tmp = <STDIN>;	
		last if $next_pointer == 0;
}

sub get_byte{
		my ($addr,$root)  = @_;
		my $upper = $addr >> 4;
		my $lower = $addr & 0x000f;
		return hex $root->[$upper]->[$lower];
}

sub get_word{
		my ($addr,$root)  = @_;
		my ($byte0,$byte1) = (&get_byte($addr,$root),&get_byte($addr+1,$root));
		return $byte0 + ($byte1 << 8) ;
}

sub get_3byte{
		my ($addr,$root)  = @_;
		my ($byte0,$byte1) = (&get_byte($addr,$root),&get_word($addr+1,$root));
		return $byte0 + ($byte1 << 8);
}

sub get_dword{
		my ($addr,$root)  = @_;
		my ($word0,$word1) = (&get_word($addr,$root),&get_word($addr+2,$root));
		return $word0 + ($word1 << 16);
}

sub get_bit{
		my ($addr,$root,$bitloc) = @_;
		my $byte = &get_byte($addr,$root);
		return 0x01 & ($byte >> $bitloc);
}

sub show_register_info{
		my ($addr,$config) = @_;
		print $addr;
		print "\t";
		print $config->{$addr}->{'name'};
		print "\t";
		print $config->{$addr}->{'attribute'};
		print "\t";

		my $width = $config->{$addr}->{'width'};
		
		print sprintf "%08x",&get_dword(hex $addr,\@data) if($width == 4);
		print sprintf "%06x",&get_3byte(hex $addr,\@data) if($width == 3); 
		print sprintf "%04x", &get_word(hex $addr,\@data)  if($width == 2);
		print sprintf "%02x", &get_byte(hex $addr,\@data)  if($width == 1);

		print "h\n";

		if($config->{$addr}->{'subField'}){
				show_binary(&get_byte(hex $addr,\@data),1);
				print " \n";
		}

}

sub show_binary{
		my ($byte,$width) = @_;
		my $len = sprintf "B%d",$width * 8;
		print unpack($len,pack("C",$byte));
}
__END__