# Use intellij java-decompiler.jar to decompile a folder of class files, then transfer results(java files) to another folder. 

if [ -z $1 ] || [ -z $2 ] || [ -z $3 ]; then
    echo "\033[31mMissing params.\033[0m Usage: this-script java-decompiler.jar src dst" && exit
fi
java -cp $1 org.jetbrains.java.decompiler.main.decompiler.ConsoleDecompiler  -hdc=0 -dgs=1 -rsy=1 -rbr=1 -lit=1 -nls=1 -mpm=60 $2 $3