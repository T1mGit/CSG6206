require "io"
socket=require "socket"

--PARSE SOCKET MESSSAGES--
--## 1.create a regular expression parser (?!\$)[\w' ]+
--## 	multiple messages will be separated by a $ symbol which shall not be read
--## 	message components will be separated by a : sumbol which shall not be read
--## 2. if message is empty or nil then
--##		return array{NEG,No Messages}
--## 3.	end
--## 2. separate messages components via regualr expression and put into an array
--## 3. return array

----REQUESTING A SESSION----
--## 1.Open a client Socket Connection with server using 10 second timeout
--## 2.Send the session initiation message 'REQ:nickname'
--## 3.Recieve the response from server 'ACK' or 'NAK:CODE' or NIL (timeout)
--## 4 Parse Response
--## 5.IF RESPONSE==ACK:SESSION_ID THEN
--##	6. close socket connection, return SESSION_ID and exit function
--##   IF RESPONSE==NAK:CODE
--##	7. Print CODE, close socket, return emtpy string, exit function
--## 8.If timeout then
--##	9. Print "request timeout", close socket, return empty string, exit function
--## ENDIF

--------MAIN PROGRAM--------
--## 1. get the users name

--##	BEGIN LOOP
--##	2. Do we  have an active session? If yes goto step 3. If no Goto Step 10.
--##		IF ACTIVE_SESSION==YES THEN
--##			3.Request the server to send message backlog 'GET:nickname'.
--##			4.Recieve Messages
--##			5.Parse server resposne. messages arrive as repeated series'PUT:srcname:message'
--##			6.Then Display the messages.
--##			7.Get text from user. (waits untill text is entered)
--##			8.If special (#exit) Break out of loop close connection an exit 
--##			8.Create a message string to send
--##			9.Send message to server.
--##		ELSE
--##			10.Send session initiatite request
--##			11.if received (ACK:ID) set the session id
--##			12.if received (NAK:UAV) Prompt user for new name and close connection
--##		ENDIF
--##	END LOOP



---------------------------------------
--Function to parse socket message--
function ParseSocketMessage(str)
	regex="[%w ',%-%.]+"
	array={}
	if str==nil or str=="" then
		return {"NEG","No Message","No Message"}
	end
	for i in string.gmatch(str,regex) do
		table.insert(array,i)
	end
	n=table.maxn(array)
	if n<4 then
		for i=n,4,1 do
			table.insert(array," ")
		end
	end
	return array
end

-----------------------------------------------------
----------------MAIN PROGRAM BEGIN-------------------
-----------------------------------------------------
session_id=0
io.write("Enter name:")
name=io.read()
io.write("Enter server IP address:")
connect_ip=io.read()
while true do
	if tonumber(session_id)>0 then
		connection:send("$GET:"..name.."\n")
		unparsed_msg=connection:receive("*l")
		parsed_msg=ParseSocketMessage(unparsed_msg)
		i=1
		while parsed_msg[i]=="PUT" do
			print("["..parsed_msg[i+1].."]:"..parsed_msg[i+2])
			i=i+3
		end
		io.write("[>>")
		input=io.read()
		--create message string
		if string.len(input)>0 then
			if string.sub(input,1,1)=="@" and string.len(input)>1 then
				mark=string.find(input," ",1)
				if mark~=nil then
					message=string.sub(input,mark+1,string.len(input))
					target=string.sub(input,2,mark-1)
					connection:send("$PUT:"..target..":"..name..":"..message.."\n")
				end
			elseif input=="#exit" then
				connection:send("END:"..name.."\n")
				socket.sleep(3)
				break
			else
				connection:send("$PUT:ALL:"..name..":"..input.."\n")
			end
		end
		unparsed_msg=connection:receive("*l")
		parsed_msg=ParseSocketMessage(unparsed_msg)
		if parsed_msg[1]=="NAK" and parsed_msg[2]=="NAN" then
			print("Name ["..target.."] is not connected.")
		end
		socket.sleep(0.5)
		--connection:close()
	else
		connection=assert(socket.connect(connect_ip,51945),"Can't Connect. Check IP address.")
		connection:settimeout(0.5)
		connection:send("$REQ:"..name.."\n")
		unparsed_msg=connection:receive("*l")
		parsed_msg=ParseSocketMessage(unparsed_msg)
		if parsed_msg[1]=="ACK" then
			session_id=parsed_msg[2]
			print("Session ID:"..session_id..". Connected users:"..parsed_msg[3])
		elseif parsed_msg[1]=="NAK" and parsed_msg[2]=="UAV" then
			connection:close()
			io.write("Selected name not available. Enter Name:")
			name=io.read()
		else
			print(parsed_msg[2])
			connection:close()
		end
		--connection:close()
	end

end
connection:close()