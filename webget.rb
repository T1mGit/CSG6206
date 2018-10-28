#
#           webget - for retrieving clean text from webages
#Name: Tim Hyde
#SID: 10458263
#Year: September 2018
#References:
#Tutorials Point Pvt. Ltd. (2018). Ruby Tutorial. Retrieved September 4, 2018, from https://www.tutorialspoint.com/ruby/index.htm
#Sinclair Gavin, William, W., Lyle, J., & Gray, J. E. (n.d.). Ruby 2.5.1 Standard Library Documentation. Retrieved September 4, 2018, from https://ruby-doc.org/stdlib-2.5.1/
#Chua, H.-C. (2009). HTTP (Hyper Text Transfer Protocol). Retrieved from http://www.ntu.edu.sg/home/ehchua/programming/webprogramming/http_basics.html

require "net/http"	#include http library
require "io/console"
require "socket"

#Convert URL String to URI
#uri=URI("https://en.wikipedia.org/wiki/Alice%27s_Adventures_in_Wonderland")
#en.wikipedia.org/wiki/Alice%27s_Adventures_in_Wonderland")

#command Args for host webpage
host=ARGV[0].to_s 
page=ARGV[1].to_s

#if not enough args dispplay help and exti
if ARGV.length <2
	print "Usage:\nwebget HOST DIRECTORY\n"
	print "webget will attempt a socket HTTP request if that fails it will attempt an HTTPS request\nDirectory should include leading slash.\n\n"
	exit(1)
end

#define the port and the http request
port=80
reqtype="HEAD "
req=page + " HTTP/1.1\r\nHost: "+host+"\r\n\r\n"#+"\r\nUser Agent: Mozilla/5.0\r\nAccept: text/html, application/xhtml+xml, application/xml; q=0.9, */*; q=0.8\r\n\r\n"


#Socket http request start here
#using the reqtype variable to control the loop
#the loop should happen twice first to get the header, second to get the entire page, unless an error occurs
while reqtype!="FIN"
	#attempt to use socket connection on port 80
	socerr=0
	begin
		s=TCPSocket.new(host,port)
		puts "Socket Connection Initiated\n"
	rescue StandardError => e
		puts "Raw Socket Connection could not be established\n"
		puts e.message
		socerr=1
		reqtype="FIN"
	end
	#firt time through the look gets the header second time gets the whole page
	if socerr==0
		begin
			puts "sending "+reqtype+" request\n"
			puts reqtype+req+"\n\n"
			s.print reqtype+req	#printing request string to socket
			result=s.read		#reading entire result at once
			if reqtype=="HEAD "
				puts result			#output to stdout
			end
		rescue StandardError=>e
			socerr=2
			puts "Socket error retrieving "+reqtype+"request\n"
			puts e.message
			reqtype="FIN"
		end
		if socerr==0
			#scan the server resonse to make sure it is successfull
			#if any message other than 20x try again using the NET::HTTP library
			rex=/HTTP\/1.1 20[0-9]/
			strings=result.scan(rex)
			if strings.length==0
				#An HTTP Success header not found
				socerr=3
				puts "Error. Did not recieve the expected HTTP/1.1 20x OK Server Response.\n"
				reqtype="FIN" #Stops the loop repeating
			else
				#if head request has been successfull repeat loop with get request otherwise stop
				if reqtype=="HEAD "
					print "HEAD Request Success.\n"
					reqtype="GET "
				else
					print "GET request Success.\n"
					reqtype="FIN"
				end
			end
		end
		s.close()

	end
end

#If socket request fail try using the net::http library
if socerr!=0
	puts "Download via socket failed, reverting to Net Library.\n"
	#Convert URL String to URI
	uri=URI("https://"+host+page)
	begin
		result=Net::HTTP.get(uri)
		puts "Getting NET::HTTP Success.\n"
	rescue
		puts "Not Available/No Response.\n"
		exit(1)
	end
end
print "Output is saved to file 'Source.txt' and 'Filtered.txt'\n"
#save result to file
path="Source.txt"
IO.write(path,result)

#regular expression only find the text between the html tags >< Does not include the html tags.
rex=/(?!>)([a-z0-9 ,"\(\)\.\-]+)(?=<)/i

#produce array or found matches in html data
strings=result.scan(rex)


#Join strings together and write to file.
text=strings.join(" ")
#repeat filter and join
rex=/[a-z]+/i
strings=text.scan(rex)
text=strings.join()
IO.write("Filtered.txt",text)

#Note because all the HTML tags have been removed there is no longer any formatting.
