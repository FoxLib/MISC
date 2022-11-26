all: 
	iverilog -g2005-sv -DICARUS=1 -o tb.qqq tb.v sdram.v
	vvp tb.qqq >> /dev/null
	rm tb.qqq
vcd:
	gtkwave tb.vcd
wave:
	gtkwave tb.gtkw
clean:
	rm -rf tb out *.o *.vcd *.qqq obj_dir record.mp4
