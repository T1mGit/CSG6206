# CSG6206
<h2>sortfiles.sh</h2>
This bash script was designed to sort files downloaded from http://sipi.usc.edu/database/misc.zip<br>
It works in combination with sqlite_files.sh
<h2>sqlite_files.sh</h2>
This bash script stores the filename and size attributes of the files from http://sipi.usc.edu/database/misc.zip in to an sqlite database.<br>
It works in combination with sortfiles.sh
<h2>webget.rb</h2>
This ruby script uses a raw socket to download a single webpage specified on the command line and removed all the HTML tags leaving clean text which is written to an output file.<br>
<pre>
Usage: webget HOST DIRECTORY
  webget will attempt a raw TCP socket HTTP request, if that fails it will attempt an HTTPS request using the Ruby Net library.
  Directory should include leading slash.
</pre>
<h2>wordstat.php</h2>
wordstat.php counts approximately the workds, letters and aplhanumeric characters in a text file.<br>
When run from a webserver it displays in the web browser in put form for the file path and upon recieving a valid path displays a heatmap and statistic table.<br>
When run from the command line it prints only a statistics table.<br>
In both cases it creates and writes an new html file showing the heatmap.<br>
<pre>
Comand Line Usage:    wordstat FILE
</pre>
