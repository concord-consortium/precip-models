cp ./input/*.html ./output

for f in output/*.html
do
	echo "Adding CSS to file named: $f"
  cat ./extra-css.html >> $f
done
