JARPATH = .
all:
	javac Assembler/*.java
	jar -cvfm a1.jar manifest.txt Assembler/*.class
%.hex: %.asm
	java -jar $(JARPATH)/a1.jar $*.asm $*.code $*.data $*.err $*.log


