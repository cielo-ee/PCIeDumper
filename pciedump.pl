#!/usr/bin/perl

use strict;
use warnings;

use Data::Dumper;

open my $fh, '<',"sample.txt" or die "$!\n";

my @lines = <$fh>;
my @data   = ();

foreach my $line (@lines){
		$line =~ s/\x0D?\x0A$//g; #改行削除
		my @byte = split / /,$line;  
		my $offset = shift @byte;
		push @data,\@byte;

}

#print Dumper @data;

#my $hoge = &get_byte(0x000,\@data);
#print unpack("B8",pack("H2",$hoge));

#ここからポインタをたどるよ
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

sub get_dword{
		my ($addr,$root)  = @_;
		my ($word0,$word1) = (&get_word($addr,$root),&get_word($addr+2,$root));
		return $word0 + ($word1 << 16);
}




__END__