message=$(git -C $1 pull --rebase 2>&1)
if [ $? = 0 ]; then
	
fi
