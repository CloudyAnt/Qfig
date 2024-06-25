# Use intellij java-decompiler.jar to decompile a folder of class files, then transfer results(java files) to another folder. 
# That jar may be found under $ideaFolder/plugins/java-decompiler/lib

if [ -z "$1" ] || [ -z "$2" ] || [ -z "$3" ]; then
    echo "\033[31mMissing params.\033[0m Usage: this-script java-decompiler.jar src dst" && exit
fi
if [ -f $2 ] || [ -f $3 ]; then
    echo "\033[31mSource or destination is file!" && exit
fi
if [ ! -d $3 ]; then
    mkdir -p $3
fi
java -cp $1 org.jetbrains.java.decompiler.main.decompiler.ConsoleDecompiler  -hdc=0 -dgs=1 -rsy=1 -rbr=1 -lit=1 -nls=1 -mpm=60 $2 $3
