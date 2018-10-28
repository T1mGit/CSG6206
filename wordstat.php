<?php
/****************************************************
      Wordstat - Statistics for book style text
Name: Tim Hyde
SID:	10458263
Year: September 2018
Referernces:
The PHP Group. (2018). PHP: Hypertext Processor. Retrieved September 4, 2018, from http://php.net
Refsnes Data. (2018). W3 Schools Online Web Tutorials. Retrieved September 4, 2018, from https://w3schools.com/
Tutorials Point Pvt. Ltd. (2018). PHP Tutorial. Retrieved September 4, 2018, from https://www.tutorialspoint.com/php/index.htm
*****************************************************/
//Check for paramaters on both command line and http GET
//if no paramaters for display help for both
if(php_sapi_name()=="cli"/*assume cli otherwise assume web interface*/){
	if($argc<2){	echo "\nComand Line Usage: wordstat FILE\n"; exit(1);}
} else {
	echo 	"<form action='wordstat.php' method='get'>
			Input File path:<input type='text' name='fname'><br>
			<input type='submit'>
			</form>";
}



//webpage output to new html file.
$webpage="<!DOCTYPE html><html><head><style>#table1{background-image:linear-gradient(to right, white, red);}</style></head><body>";

//Open the file, calculate size, read file.
if(php_sapi_name()=="cli"){
	$fh=@fopen($argv[1],"r");
	if($fh==false){echo "\n\nCannot Open File : (".$argv[1].")\n";exit(1);}else{$filename=$argv[1];}
} else {
	$fh=@fopen($_GET["fname"],"r"); //"182 - CSG6206 Workshop 7 Alice in Wonderland.txt"
	if($fh==false){ echo "\n\nCannot Open File : (".$_GET['fname'].")\n";exit(1);} else {$filename=$_GET["fname"];}
}
echo "\n\nOpened : (".$filename.")\n\n";
$fs=ftell($fh);
fseek($fh,0,SEEK_END);
$fe=ftell($fh);
fseek($fh,0,SEEK_SET);
$fsize=$fe-$fs;
$text=fread($fh,$fsize);
fclose($fh);


//concatenate all web output to string
$webpage=$webpage."<h1>".$filename."</h1><p>File size(bytes):".$fsize;

//get string length
$text=strtolower($text);
$tlen=strlen($text);
$wcount=str_word_count($text);

preg_match_all("/([\.\!\?](\"|\s))/",$text,$sentences);
$count_sentences=count($sentences[0]);
preg_match_all("/\n?\n|[^a-z]/",$text,$punctuation); //count everything that is not a letter
$count_punctuation=count($punctuation[0]);

//count letters
$webpage=$webpage."<h1>Heat Map</h1><p>";
$webpage=$webpage."<table>";
$lmax=0;
for ($j=97; $j<=122; $j++){if($lmax<substr_count($text,chr($j))){$lmax=substr_count($text,chr($j));}}
$total=0;
$letters=range(0,25,1);
for($i=97; $i<=122; $i++){
	$lcount=substr_count($text,chr($i)); //count of each letter a-z
	$letters[$i-97]=$lcount;
	$total=$total+$lcount; //accumulate total of all letters
	$heat=intval($lcount*255/$lmax);//($tlen-$count_punctuation)); //Total characters - punctuation & whitespace = total letters.
	$x=($i-97)%5;
	if ($x==0){
		$webpage=$webpage."<tr>";
	}
	$webpage=$webpage."<td style='background-color:rgb(255,".(255-$heat).",".(255-$heat).")'>".chr($i)."</td>";
	if($x==4){
		$webpage=$webpage."</tr>";
	}
}
$webpage=$webpage."<tr><td></td></tr></table>";
$webpage=$webpage."<table id='table1'><tr><th>0..........100</th></tr></table>";
//sum of vowels
$vcount=$letters[0]+$letters[4]+$letters[8]+$letters[14]+$letters[20];
$ccount=$total-$vcount;

//print table
$webpage=$webpage."<h1>Statistics</h1><p>";
$webpage=$webpage."<table><tr><th>Statistics</th><th>Count</th></tr>";
$webpage=$webpage."<tr><td>Characters in text:</td><td>".$tlen."</td></tr>";
$webpage=$webpage."<tr><td>Vowel Count</td><td>".$vcount."</td></tr>";
$webpage=$webpage."<tr><td>Word Count</td><td>".$wcount."</td></tr>";
$webpage=$webpage."<tr><td>Consonant Count</td><td>".$ccount."</td></tr>";
$webpage=$webpage."<tr><td>Sentence Count</td><td>".$count_sentences."</td></tr>";
$webpage=$webpage."<tr><td>Punctuation/Whitespace</td><td>".$count_punctuation."</td></tr></table>";

$webpage=$webpage."</body></html>";
//open file to make new webpage
$fh=fopen("stat.html","w+");
fwrite($fh,$webpage);
fclose($fh);
if(php_sapi_name()!="cli"){echo $webpage;}else{
	echo "Statistics           |Count
---------------------------
Characters in text   |".$tlen."
Vowel Count          |".$vcount."
Word Count           |".$wcount."
Consonant Count      |".$ccount."
Sentence Count       |".$count_sentences."
Punction & Whitespace|".$count_punctuation."\n\n";
}
?>