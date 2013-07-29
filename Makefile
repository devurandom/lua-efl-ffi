all: pre/evas/Evas_GL.E pre/evas/Evas_GL.D

clean:
	$(RM) -r pre

pre/evas:
	mkdir -p $@

pre/evas/Evas_GL.E: /usr/include/evas-1/Evas_GL.h pre/evas Makefile
	./preprocess.sh $<

pre/evas/Evas_GL.D: /usr/include/evas-1/Evas_GL.h pre/evas Makefile
	echo 'local d = {' > $@
	sed -nre 's/^#\s*define\s+(GL_\S+)\s+(\S+).*$$/\1 = \2,/p' >> $@ $<
	echo '}' >> $@
	echo 'return d' >> $@
