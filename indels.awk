function abs(v) {return v < 0 ? -v : v}	# guess what

# returns with a random coordinate that is 
# -+ "distance" bps to the original, but 
# is at least 3 bps far
function nearby(coord,distance) {
	start = int(coord + 2.0*distance*rand()-distance);	# random coords +- 10 bps to the original 
	if( abs(start-coord)<3 )
					start = nearby(coord,distance);	# try again
	return start
}

# returns with a random ACGT string with max 10 length
function random_insert() {
	slen = int(10*rand());
	insert="";
	while(length(insert)<=slen) {
		str_to_add = rand();
		if(str_to_add<=0.25)
						insert = insert "A";
		else if(str_to_add<=0.5)
						insert = insert "C";
		else if(str_to_add<=0.75)
						insert = insert "G";
		else
						insert = insert "T";
	}
	return insert
}


BEGIN{srand()}
{
	if(rand()<0.2) {	# we are adding indels only for 20% of SNPs
			where = rand()
			if(where<=0.25) {
					start = nearby($2,10.0)
					print $1,start,start+1,"0.5 INS",random_insert()
			} else if(where<=0.5) {
					start = nearby($2,100.0)
					print $1,start,start+1,"0.5 INS",random_insert()
			} else if(where<=0.75) {
					start = nearby($2,10.0)
					# small deletion with length that is somehow proportional to the distance from the snp
					del_len = int( rand()*abs(start-$2)/2.0 )+1
					print $1,start,start+del_len,"0.5 DEL"
			} else {
					del_len = int( rand()*10)+1
					start = nearby($2,100.0)
					while( abs(start-$2)<del_len*2 )
						start = nearby($2,100.0)
					print $1,start,start+del_len,"0.5 DEL"
			}
	}
}
