#!/usr/bin/perl

use strict;
use warnings;

use YAML::XS qw/LoadFile/;
use Data::Dumper;

{
		package Field;

		sub new{
				my ($class,%args) = @_;
				bless +{
						%args
				},$class;
		}

		sub getField{
				my ($self,$address) = @_;
		}
}

{
		package subField;

		sub new{
				my ($class,%args) = @_;
				bless +{
						%args
				},$class;
		}

		sub getElements{
				my $self = shift;
				my $elements = +{
						'addr'      => $self->{'addr'},
						'name'      => $self->{'config'}->{'name'},
						'attribute' => $self->{'config'}->{'attribute'},
						'value'     => $self->{'value'}
				};
				return $elements;
		}
}

open my $fh, '<',"sample.txt" or die "$!\n";

my @lines = <$fh>;

close $fh or die "$!\n";

my @data;

foreach my $line (@lines){
		$line =~ s/\x0D?\x0A$//g; #改行削除
		my @byte = split / /,$line;  
		my $offset = shift @byte;
		push @data,\@byte;

}

my $config = LoadFile('config.yaml');

my $fields = []; #Fieldオブジェクトのリファレンスの配列へのリファレンス
foreach my $addr (sort keys(%$config)){

#		&show_register_info($addr,$config);

		my $value = &get_register_info($addr,$config);
		my %data = (
				'addr'  => $addr,
				'value' => $value,
				'config'  => $config->{$addr}
		);
		my $field_ref = Field->new(%data);
		push @$fields,$field_ref;
}

print Dumper $fields;


sub print_header{
		foreach my $field_i (@$fields){
				my $elements = $field_i->getFields();
				&print_field($elements);
		}
}

sub print_field{
		my $elements = shift;
}

#ここからポインタを辿る
print "PCI Extended Capability\n";
my $next_pointer = &get_byte(0x034,\@data);
while(1){
		my $id   = &get_byte($next_pointer,\@data);
		printf "Offset:%0xh ID:%0xh\n",$next_pointer,$id;
		$next_pointer = &get_byte($next_pointer+1,\@data);
#		my $tmp = <STDIN>;
		last if $next_pointer == 0;
}

print "PCI express Capability\n";
$next_pointer = 0x100;
while(1){
		my $capability   = &get_dword($next_pointer,\@data);
		my $id = $capability & 0x00ff;
		printf "Offset:%0xh ID:%0xh \n",$id,$next_pointer;
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
		my $value = &get_register_info($addr,$config);
		
		printf "%08x",$value  if($width == 4);
		printf "%06x",$value  if($width == 3); 
		printf "%04x",$value  if($width == 2);
		printf "%02x",$value  if($width == 1);

		print "h\n";

		if($config->{$addr}->{'subField'}){
				show_binary(&get_byte(hex $addr,\@data),1);
				print " \n";
		}

}

sub get_register_info{
		my ($addr,$config) = @_;

		my $width = $config->{$addr}->{'width'};
		
		return &get_dword(hex $addr,\@data) if($width == 4);
		return &get_3byte(hex $addr,\@data) if($width == 3); 
		return &get_word(hex $addr,\@data)  if($width == 2);
		return &get_byte(hex $addr,\@data)  if($width == 1);

}

sub show_binary{
		my ($byte,$width) = @_;
		my $len = sprintf "B%d",$width * 8;
		print unpack($len,pack("C",$byte));
}

__END__
#こういう雰囲気のレジスタマップとして出力したい
#Addr	name	description	ByteWidth	bit	attr	default	bit name	reset	description
#0x00	Vendor_ID	ベンダID	2	63:0	RO	8086		-	ベンダID
#0x02	Device_ID	デバイスID	2	63:0	RO	0000		-	???
#0x04	Command	コマンド	2	0	RO	0	I/O Space		
#				1	RO	0	Memory Space		
