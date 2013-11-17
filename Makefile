map.png: map.dot
	circo -Tpng -o map.png map.dot

map.dot:
	./lldp-map.pl

clean:
	rm -f map.dot map.png
