socket=require "socket"
sqlite3=require "luasql.sqlite3"
--PARSE SOCKET MESSSAGES--
--## 1.create a regular expression parser (?!\$)[\w' ]+
--## 	multiple messages will be separated by a $ symbol which shall not be read
--## 	message components will be separated by a : sumbol which shall not be read
--## 2. if message is empty or nil then
--##		return array{NEG,No Messages}
--## 3.	end
--## 2. separate messages components via regualr expression and put into an array
--## 3. return array


--main loop--
--##BEGIN LOOP
--## 1. Accept the client socket connection
--## 3. Parse request message
--## 4. IF REQ received THEN
--## 5		Search session list for 'nickname'
--## 6		If nickname not in list THEN
--##			Create Session_ID
--##			add nickname and session_ID to list
--##			Send message string ACK:SESSION_ID(6)
--##		ELSE
--##			SEND messag string NAK:UAV
--##		END
--##	END
--##	FOR Every Active session in list DO
--##		IF GET Received THEN
--##			FOR EACH message in nickames backlog
--##				Conncatenate to message string
--##				remove message from backlog
--##				Send message string to client
--##			END FOR
--##		ELSE IF PUT Received
--##			Log the message to database
--##			IF target is ALL clients
--##				FOR every active session add message to that session
--##			ELSE IF target is server
--##				Server add response to current session
--##			ELSE
--##				Find Target in Session List
--##				Add message only to target
--##			END
--##		ELSE IF END Received
--##			Log Disconnection
--##			Remove session from list
--##			For each remaining session Log a disconnect message
--##		ELSE
--##			Send Message 'NAK:INV'
--##	 5.	ENDIF
--##	END FOR
--## END LOOP

--TABLE STRUCTURE--
--[[
{
 {destnikname, connection_object, {{src,message},...}, connection_ID},
 {destnikname, connection_object, {{src,message},...}, connection_ID},
 ...
 ...
}
]]

function _assert(val,cmp,fail_msg)
	if val~=cmp then
		error(fail_msg)
		exit()
	end
end
--Database access function

--function to log messages in SQL data base
function Log_Message(db, con_ID,nickname,message,msgtype)
	msgDate=os.date("%x")
	msgTime=os.date("%X")
	sql=[[INSERT INTO messages (con_id, nickname, message, date, time) VALUES (]]..con_ID..[[, ']]..nickname..[[', ']]..message..[[', ']]..msgDate..[[', ']]..msgTime..[[')]]
	status, errorstring=db:execute(sql)
	_assert(status,1,errorstring)
	print(">>(ID:"..con_ID..")("..msgtype..") "..nickname..":  "..message.." at "..msgDate.." "..msgTime)
end

--Function to Record connections in Database
function Log_Connection(db,nickname, ipaddress)
	conDate=os.date("%x")
	conTime=os.date("%X")
	message=" connected to server from "..ipaddress
--add chat session to DATABASE
	sql=[[INSERT INTO connections (nickname, ipaddress, con_date, con_time) VALUES (']]..nickname..[[',']]..ipaddress..[[',']]..conDate..[[',']]..conTime..[[')]]
	status, errorstring=db:execute(sql)
	_assert(status,1,errorstring)
--retrieve the chat session ID
	sql=[[SELECT rowid FROM connections ORDER BY rowid DESC LIMIT 1;]]
	cursor, errorstring=db:execute(sql)
	
--Provided there is data to retrieve get the session ID for that client
	if cursor~=nil then
		row=cursor:fetch({},"a")
		conID=0
		if row==nil then
			print("Status: "..tostring(cursor).." | Error: "..tostring(errorstring))
		else
--Log a connection message for that session
			conID=tonumber(row.rowid)
			Log_Message(db,conID,nickname,message,"Broadcast")
		end
	else
		print("SQL Select Error: "..errorstring)
		conID=nil
	end
	return conID
end

--Functin to record Disconnects in database
function Log_Disconnect(db,con_ID, nickname)
	dconDate=os.date("%x")
	dconTime=os.date("%X")
	message=" disconnected"
	sql=[[UPDATE connections SET dcon_date=']]..dconDate..[[', dcon_time=']]..dconTime..[[' WHERE rowid=]]..con_ID
	status, errorstring=db:execute(sql)
	_assert(status,1,errorstring)
	Log_Message(db,con_ID,nickname,message,"Broadcast")
end



--Function to Create Tables
--First Check whether table exists in database if not create it.
function Create_Table(db,table_name,str_list_cols)
	sql=[[SELECT rowid,name FROM sqlite_master WHERE type='table' AND name=']]..table_name..[[']]
	cursor, errorstring=db:execute(sql)
	row=cursor:fetch({},"a")
	if row==nil then
		sql=[[CREATE TABLE ]]..table_name..[[ (]]..str_list_cols..[[);]]
		status, errorstring=db:execute(sql)
		print("Status: "..tostring(cursor)," | Error: "..tostring(errorstring))
		print(table_name.." Table Created")
	else
		print("ID: "..tostring(row.rowid)," | Error: "..row.name.." table exists")
	end
	cursor:close()
end


---------------------------------------
--Function to parse socket message--
function ParseSocketMessage(str)
	regex="[%w ',%-%.]+"
	array={}
	if str==nil or str=="" then
		return {"NEG","No Message"," "," "}
	end
	for i in string.gmatch(str,regex) do
		table.insert(array,i)
	end
--message format sent over socket expects 4 valid parameters. Regex iterator may return less. must be topped up.
	n=table.maxn(array)
	if n<4 then
		for i=n,4,1 do
			table.insert(array," ")
		end
	end
	return array
end

--Function to search session list to check if requested name already actively connected
function IsNicknameCurrentlyActiveSession(ActiveSessionList,ActiveSessionCount,nickname)
	i=1
	exist=false
	while i<=ActiveSessionCount do
		if ActiveSessionList[i][1]==nickname then --the nickname of client
			exist=true
			break
		end
		i=i+1
	end
	return exist,i
end
-----------------------------------------
------------MAIN PROGRAM BEGIN-----------
-----------------------------------------

--Create the sqlite database
local env=sqlite3.sqlite3('chatter.sqlite3')
local chatter=env:connect('chatterbox.sqlite3','root','123456')
print(env, chatter)

--Create tables
Create_Table(chatter,[[connections]],[[nickname VARCHAR(255), ipaddress VARCHAR(15), con_date DATE, con_time TIME, dcon_date DATE, dcon_time TIME]])
Create_Table(chatter,[[messages]],[[con_id INTEGER, nickname VARCHAR(255), message VARCHAR(255), date DATE, time TIME]])


--Commence Listening on Primary socket
print("Socket: "..tostring(socket))
 serv, errorstring=socket.bind("*",51945)
print("Serv: "..tostring(serv).." | Error: "..tostring(errorstring))
serv:settimeout(0.1)
ip,port=serv:getsockname()
print("\n\nSocket Listening at",ip,port,"\nWaiting client connection...")

--table to store the active sessions
session_list={}
session_count=0

--main server loop - every time through loop check if client waiting to connect
while true do
	connection=serv:accept()
	if connection~=nil then
		unparsed_msg=connection:receive("*l")
		parsed_msg=ParseSocketMessage(unparsed_msg)
--check whether the name requested by the client is already in use.
		if parsed_msg[1]=="REQ" then
			nickname_exist=IsNicknameCurrentlyActiveSession(session_list,session_count,parsed_msg[2])
			if nickname_exist==false then
--if the requested name is available create a new session
				ip,port=connection:getsockname()
				session_id=Log_Connection(chatter,parsed_msg[2],tostring(ip..":"..port))
				session_count=session_count+1
				session_list[session_count]={parsed_msg[2],connection,{},session_id}
				connection:send("$ACK:"..tostring(session_id..":"..session_count).."\n")
--Notify all active sesions that a new session has been created
				for row = 1 , table.maxn(session_list), 1 do
					table.insert(session_list[row][3],{"Server",parsed_msg[2].." Connected"})
				end
			else
				connection:send("$NAK:UAV\n")
			end
		end
	end
	c=1
	--loop throuh all connected sessions to get updated messages from clients
	while c<=session_count do
		session_list[c][2]:settimeout(.1)
		unparsed_msg=session_list[c][2]:receive("*l")
		parsed_msg=ParseSocketMessage(unparsed_msg)
--Client sends GET, PUT, or END to send a message, get message backlog, or end session
		
		if parsed_msg[1]=="PUT" then
			if parsed_msg[2]=="ALL" then
--if target is all clients add message to every session			
				Log_Message(chatter,session_list[c][4],session_list[c][1],parsed_msg[4],"Broadcast")
				for row = 1 , table.maxn(session_list), 1 do
					table.insert(session_list[row][3],{parsed_msg[3],parsed_msg[4]})
				end
			else
				Log_Message(chatter,session_list[c][4],session_list[c][1],parsed_msg[4],"Private->"..parsed_msg[2])
				if parsed_msg[2]=="server" then
					table.insert(session_list[c][3],{"Server","Only admin is allowed to do that."})
				else
--Search for target name in session list add only to that sessoin
					nickname_exist, row=IsNicknameCurrentlyActiveSession(session_list,session_count,parsed_msg[2])
					if nickname_exist==false then
						Log_Message(chatter,session_list[c][4],session_list[c][1]," DELIVERYFAIL-NOTCONNECTED","Server")
						session_list[c][2]:send("$NAK:NAN\n")
					else
						table.insert(session_list[row][3],{parsed_msg[3],parsed_msg[4]})
					end
				end
			end
		elseif parsed_msg[1]=="GET" then
--for every message for a single session concat them all together and send as ones string. then clear messages
			concat=""
			for m=1, table.maxn(session_list[c][3]), 1 do
				concat=concat.."$PUT:"..session_list[c][3][m][1]..":"..session_list[c][3][m][2]
			end
			session_list[c][2]:send(concat.."\n")
			session_list[c][3]={}
		elseif parsed_msg[1]=="END" then
--log the disconnection. notify remaining sessions
			Log_Disconnect(chatter,session_list[c][4],session_list[c][1])
			table.remove(session_list,c)
			for row = 1 , table.maxn(session_list), 1 do
				table.insert(session_list[row][3],{"Server",parsed_msg[2].." Disconnected"})
			end
			session_count=session_count-1
		end
		c=c+1
	end
end