#!/usr/bin/perl -w
use strict;
use Getopt::Long;

my $mule_fasta = shift or &getHelp;
my $db_file = shift or &getHelp; #same file used as a database in the above blast
my $db2 = shift or &getHelp; # nr, species specific of the above organsims

my $min_insert = 2000;
my $max_insert = 10000;
my $min_ident  =  0.60;
my $min_aligned = 0.60;
my $dir = '~/project/findPackMule';
#my $dir = '/srv/zpools/tern.ib_bigdata/home/wesslerlab/shared/findPackMule';

GetOptions(
    'h|help'  => \&getHelp,
    'm|min_insert:i' => \$min_insert,
    'x|max_insert:i' => \$max_insert,
    'i|min_ident:f'  => \$min_ident,
    'a|min_aligned:f' => \$min_aligned,
);

sub getHelp {
    print "

-------------------------------------------------------------------------------------------
-------------------------------------------------------------------------------------------
usage:
./find_packmule.pl mule.nt.fa genome.fa species.nt.fa -m 2000 -x 10000 -i 0.60 -a 0.60  [-h] 

-------------------------------------------------------------------------------------------
options:
-------------------------------------------------------------------------------------------
-h this message
-m INT min insert size [default 2000]
-x INT max insert size [default 10000]
-i FRAC min blat %identity [0.6]
-a FRAC the proportion of the TIR-TIR that must be aligned (matches + mismatches) [0.6]


-------------------------------------------------------------------------------------------
mule.nt.fa 
-------------------------------------------------------------------------------------------
a fasta file that needs to contain the TIR1-TIR2 of the mule elements


sample fasta  
>mule_autonomous TSD=CTTCAAATG
GGGTCTACCCCGTTTGGCATAATGCCGTTTGGCATAATGCCGTTTGGCATACAGTCGTTTGGCATAAAGTCGTTTGGCATAATAGTC
ATTTGGCATAACAGTCGTTTGGCATAATGGTCATTTGGCATAATGGTCGTTTGGCATAATTATGCCAAACGACTATTATGCCAAATG
ACCATTATGCCAAATGACTATTATGCCAAATGGCATTATGCCAAACGACTATTATGCCAAACGACTGTATGCCAAACGGCATTATGC
CAAACGGCATTATGCCAAACGGGGTAGACCC

-------------------------------------------------------------------------------------------
genome.fa
-------------------------------------------------------------------------------------------
a fasta file of the genome or supercontigs of the species you want to search in

-------------------------------------------------------------------------------------------
species.nt.fa
-------------------------------------------------------------------------------------------

a fasta of nt sequences to use as a blast database to search the packmule inserts against
this file can be blast formatted, but if not, the script will format it 

";
    exit 1;
}


my $blat = "mule_vs_genome.blatout";
my $minIdentity = ($min_ident < 1 ?  $min_ident * 100 : $min_ident);
print "Running blat of $mule_fasta against $db_file:
running: blat -maxIntron=$max_insert -minIdentity=$minIdentity $db_file $mule_fasta $blat\n\n";
`blat -maxIntron=$max_insert -minIdentity=$minIdentity $db_file $mule_fasta $blat`;

print "Finding potential PackMule elements, this might take a minute\n\n";
`perl $dir/parseBlat_mule.pl $blat $db_file $minIdentity $min_aligned $min_insert $max_insert > parseBlat_mule.generalOutput.txt`;

if (!-e "$db2.nin"){
  print "formating $db2 for blast\n\n";
  `formatdb -i $db2 -p F -o T`;
}
my $inserts_blastout = "inserts_vs_species.blastout";
#if (!-e $inserts_blastout or -z $inserts_blastout){ 
  print "Running blastn of inserts against $db2\n\n";
  `blastall -p blastn -d $db2 -i insertOnly.fa -o $inserts_blastout`;
#}else{
#  print "Found: $inserts_blastout already exists.  Will use this file to search\n";
#}

print "Parsing blast results and creating image files\n\n";
#`perl $dir/parseBlast_packmule_inserts.pl $inserts_blastout > inserts_blastHits.table.txt`;
`perl $dir/parseBlast_inserts_png.pl $inserts_blastout`;

print "Output files:
blat output of mules vs genome:                    mule_vs_genome.blatout
fasta containing inserts:                          insertsOnly.fa
fasta containing potential packmule elements:      packmule.fa
blast output of inserts vs species nt seqs:        inserts_vs_species.blastout
table of insert blast hits:                        inserts_vs_species_blastout.parsed.txt 	
";
