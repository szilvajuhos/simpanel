#! /usr/bin/env python

import click
import sys
from Bio import SeqIO
from Bio.Seq import Seq
from Bio.Alphabet import generic_dna
from Bio.SeqRecord import SeqRecord

@click.command(context_settings = dict( help_option_names = ['-h', '--help'] ))
@click.option('--target',      '-t', type=str, help='Target FASTQ (qualities will be replaced)', required=True)
@click.option('--source',      '-s', type=str, help='Source FASTQ (source of qualities)', required=True)

def exchangeQualities(target,source):
    # this is the main processing routine
    print target, source
    with open(source, "rU") as sourceHandle, open(target, "rU") as targetHandle:
        for sourceRecord,targetRecord in zip(SeqIO.parse(sourceHandle, "fastq"),SeqIO.parse(targetHandle, "fastq")) :
#            print(sourceRecord.id, targetRecord.id)
#            print(type(targetRecord.seq)) 
            newRead = SeqRecord(targetRecord.seq,id=targetRecord.id)
            newRead.description=""
            newRead.letter_annotations["phred_quality"]=sourceRecord.letter_annotations["phred_quality"]
            print(newRead.format("fastq"))

if __name__ == "__main__":
    exchangeQualities()

