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
my $next_pointer = hex &get_byte(0x034,\@data);
while(1){
		my $capability_id   = &get_byte($next_pointer,\@data);
		my $next_pinter_str = &get_byte($next_pointer + 1,\@data);
		print "Capability ID:".$capability_id."h\n";
		print "next Pointer:".$next_pinter_str."h\n";;
		$next_pointer = hex $next_pinter_str;
#		my $hoge = <STDIN>;
		last if $next_pointer == 0;
}

print "PCI express Capability\n";
$next_pointer = 0x100;
while(1){
		my $capability   = &get_dword($next_pointer,\@data);
		$capability =~ s/ //g; #空白削除
		my $capability_val = hex $capability;
		my $id = $capability_val & 0x00ff;
		$next_pointer = $capability_val >> 20;
		print sprintf "ID:%0x next:%0x\n",$id,$next_pointer;
		
		last if $next_pointer == 0;
}

sub get_byte{
		my ($addr,$root)  = @_;
		my $upper = $addr >> 4;
		my $lower = $addr & 0x000f;
		return $root->[$upper]->[$lower];
}

sub get_word{
		my ($addr,$root)  = @_;
		my ($byte0,$byte1) = (&get_byte($addr,$root),&get_byte($addr+1,$root));
		return sprintf "%s %s",$byte0,$byte1;
}

sub get_dword{
		my ($addr,$root)  = @_;
		my ($word0,$word1) = (&get_word($addr,$root),&get_word($addr+2,$root));
		return sprintf "%s %s",$word0,$word1;
}




__END__