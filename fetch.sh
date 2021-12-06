DIR_NAME=$(printf "%02d" $1)
mkdir -p $DIR_NAME
cp template/*.zig "$DIR_NAME/"
cp template/*.txt "$DIR_NAME/"
curl "https://adventofcode.com/2021/day/$1/input" -H "Cookie: session=$AOC_SESSION" > "$DIR_NAME/input.txt"
