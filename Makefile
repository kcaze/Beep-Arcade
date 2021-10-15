.PHONY: clean all update-sprites

all: 0.p8 0.html

clean:
	rm -f 0.p8 0.html 0.js celestial.zip

update-sprites:
	pico8 -x sprites.p8

0.p8: code.lua pack.p8 sprites.p8 label.p8 1_in.p8 2_in.p8 3_in.p8 4_in.p8 5_in.p8
	rm -f 0.p8
	pico8 -x pack.p8
	cat label.p8 >> 0.p8
	sed -i '/__lua__/d' 0.p8
	echo '__lua__' >> 0.p8
	cat code.lua >> 0.p8

0.html: 0.p8
	pico8 -export 0.html 0.p8
	sed -i '/class="p8_menu_button"/d' 0.html
	zip -r celestial.zip 0.html 0.js
