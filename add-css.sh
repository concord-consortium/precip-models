cp ./input/*.html ./output

rm ./index.txt
touch ./index.txt

URL_BASE="https://models-resources.concord.org/precip-models/"
for f in output/*.html
do
	echo "Adding CSS to file named: $f"
  cat ./extra-css.html >> $f
  echo "${URL_BASE}/${f}" >> ./index.txt
done
