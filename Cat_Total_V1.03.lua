--V1.03版本修复，如果某条指令执行失败，在获取平均时间为nil的处理

portSendBackup = portSend
portRecvBackup = portRecv

--软件版本
version = "V1.03"

--测试板卡串口名称
client = {port="CLIENT"}
serve = {port="SERVICE"}

Ip_Addr = "\"124.70.78.1\""
Ip_Port = "37501"
Ip_Port_Udp = "37701"

--数据表转换定义
statistics = {}

idcnt = 1

--获取日期
date = getdate()

--日期格式分解
year, month, day, hour, min, sec = string.match(date,"(%d+)-(%d+)-(%d+) (%d+):(%d+):(%d+).%d+")

log_connt = "(1)"

--串口发送数据
portSend = function(port, data)
    local sbytes,err
	print("[" .. getdate() .."] ".. port..">send>: ".. data)
	start_time = gettime()
	if udp_test_flag ~= false and port ~= client.port then
		tonumber(string.match(port, '%d[%d.,]*'))
		for i=1,#UdpAddr,1 do
			if port == UdpAddr[UdpAddrIndex][1] then
				sbytes, err = portSendBackup(port, UdpAddr[UdpAddrIndex][2],data)
				--print("N1_ADDR "..UdpAddr[UdpAddrIndex][2].. " "..sbytes.." "..err)
				break
			end
		end
	else
		sbytes, err = portSendBackup(port, data)
	end
	if err ~= nil and err ~= 0 then
		sleep(0)
	end

	return sbytes, err
end

udp_test_flag = false
UdpAddrIndex = 0
UdpAddr = {
 {},
 {},
 {},
 {},
 {},
 {},
 {},
 {},
}
--串口接收数据
portRecv = function(port)
    local data,err
	 if udp_test_flag ~= false and port ~= client.port then
	     UdpAddrIndex = tonumber(string.match(port, '%d[%d.,]*')) + 1
		 data, err,ip= portRecvBackup(port)
		 UdpAddr[UdpAddrIndex][1] = port
		 UdpAddr[UdpAddrIndex][2] = ip
		 print(UdpAddr[UdpAddrIndex][1])
		 print( UdpAddr[UdpAddrIndex][2])
	 else
		data, err = portRecvBackup(port)
	 end
	if err == nil then
		return data, err
	elseif err ~= 0 then
	   print("[" .. getdate() .."] ".. port.."<recv<<err:"..err)
	else
		print("[" .. getdate() .."] ".. port.."<recv<: "..data)
	end

	return data, err
end

--数据表转换set函数操作
function table_set(t, k, v)
	t._data[k] = v
    --改变颜色
	if k == "color" then
		dataSheetSetStyle(t.index, "color:"..v)
		return
	end
	--更新数据
    dataSheetSet(t.index, 
				t._data.order_number,
				t._data.port,
				t._data.cmd_rpeat_times,
				t._data.cmd_rpeat_interval,
				t._data.repeat_exit,
				t._data.at_cmd,
				t._data.cmd_maxres_time,
				t._data.cmd_minres_time,
				t._data.cmd_averes_time,
				t._data.success_times,
				t._data.fail_times,
				t._data.total_times)
end

--数据表转换get函数操作
function table_get(t, k)
		return t._data[k]
end

--数据表转换注册
function add_table_row()
	 result_statistics = {
		order_number = "",
		port = "",
		cmd_rpeat_times = "",
		cmd_rpeat_interval = "",
		repeat_exit,
		at_cmd = "",
		cmd_maxres_time = 0,
		cmd_minres_time = 0,
		cmd_averes_time = 0,
		success_times,
		fail_times,
		total_times ,
	}

	 item = {
		index = "",
		_data = result_statistics
	}

	 item_class = {
		__index = table_get,
		__newindex = table_set
	}

	item.index = dataSheetAdd(item._data.order_number, item._data.port,item._data.cmd_rpeat_times,item._data.cmd_rpeat_interval,item._data.repeat_exit, item._data.at_cmd, item._data.cmd_maxres_time, item._data.cmd_minres_time, item._data.cmd_averes_time, item._data.success_times,item._data.fail_times,item._data.total_times)
	setmetatable(item, item_class)
	return item
end

--创建表格
function dataSheetDemo(start_row, end_row)
    --清空表格
    dataSheetClear()
    --添加标题栏
    local header = dataSheetAdd("序号","串口","重复次数","重复间隔","是否轮询", "AT命令", "最大响应时间(ms)","最小响应时间(ms)","平均响应时间(ms)", "成功次数", "失败次数", "总次数")

    --设置字体加粗
    dataSheetSetStyle(header, "font-weight:bold")

    --添加一条数据
	for j=start_row, end_row  do
		statistics[j] = add_table_row()
	end
end

function  logtast()
	sleep(3600000)
	setLogFileDemo(false)
	logtast()
end

--log文件创建
local logcnt = 1
function setLogFileDemo(state)
	local folder
	local log_name
	if state == true then
		clogcnt = 1
	else
		logcnt = logcnt + 1
	end
	folder ="cat1_test_logs" .. log_connt .. year .. month .. day
	log_name =folder .. "/" .. read_file_name ..  "_" .. version .. "_log " .. year .. "-" .. month .. "-" .. day .. "_" .. hour .. "-" .. min .. "-" .. sec .. "(" .. logcnt ..").txt"
	print(log_name )
    --调用命令行接口创建logs目录
    os.execute("mkdir " .. folder)

    --设置脚本日志路径为 logs/log.txt
    setLogFile(log_name)
end

--AT测试过程
record_repeat_times = 1
record_repeat_flag = false
record_data_count = 0
record_data_flag = false
record_data_time = {}
record_data_total_time = 0

function at_execute( at_id, repeat_times, repeat_interval, timeout, wait_time, lord_port,serve_port, at_command, lord_expect, serve_expect,repeat_exit,name)
	for record_repeat_times = record_repeat_times , repeat_times do
		statistics[at_id].color = "yellow"
		statistics[at_id].order_number = at_id
		statistics[at_id].port = lord_port
		statistics[at_id].at_cmd = at_command
		statistics[at_id].cmd_name = name
		statistics[at_id].cmd_rpeat_times =0
		statistics[at_id].repeat_exit = repeat_exit
		sleep(wait_time)
		local repeat_flag
		if record_repeat_times > 1 then
		else
			idcnt = idcnt + 1
		end
		if at_command ~= nil then
			if string.find(at_command, "\x1A", 1, true)  then
				record_data_count = record_data_count + 1
				statistics[at_id].cmd_rpeat_times = record_data_count
				record_data_flag = true
			else
				statistics[at_id].cmd_rpeat_times = repeat_times
			end

			statistics[at_id].cmd_rpeat_interval = repeat_interval
			sleep(statistics[at_id].cmd_rpeat_interval)
			portSend(lord_port,at_command)
			if lord_expect~= nil or serve_expect ~= nil then
				repeat_flag = recv_timeout(lord_port,serve_port,lord_expect,serve_expect,name,timeout,at_id,repeat_times,repeat_exit,at_command)
			end
			statistics[at_id].color = "lightgreen"
			if repeat_flag == true then
				if repeat_exit == true then
					return 0
				end
			end
		else
			return 0
		end
	end
end

--AT测试任务
function  at_task()
	--[[local test1 = require("Cat1_Udp_DataReported")
	sleep(500)
	test1.cat1_at_task()]]

	--[[local test2 = require("Cat1_DataReported")
	sleep(500)
	test2.cat1_at_task()]]

	local test3 = require("Cat1_Attcah_Success")
	sleep(500)
	test3.cat1_at_task()

	pause()
end

CycleCat1List = {id = 0,index = 0,data = 0,timeout = 0,next = nil}

function CycleCat1List:create()  
    local newNode = {}
    setmetatable(newNode, self)
    self.__index = self
    return newNode
end

function CycleCat1List:pushback(id,index,data,timeout)
	local newNode = {}
	setmetatable(newNode, CycleCat1List)
	newNode.id = id
	newNode.index = index
    newNode.data = data
	newNode.timeout = timeout
	newNode.next = nil
	local curNode = self
	while curNode.next do  -- 一直检测到最深处
        curNode = curNode.next
    end
	 curNode.next = newNode
	return self
end

function CycleCat1List:show()
    printnode = self.next
    while printnode do
	   print(printnode.id)
	   print(printnode.index)
       print(printnode.data)
       printnode = printnode.next
    end
    print("= = display OK = =")
end

record_network_time = 0
record_network_time_arr = {}
record_network_time_flag = false
record_network_success_times = 0

repeattiems = 0
repeattiem = 0
cycle_fail_times = 0
function recv_timeout(lord_port,serve_port,lord_expect_data,serve_expect_data,name,timeout,recv_id,repeat_times,repeat_exit,at_command)
	--数据初始化
	local load_flag, serve_flag
	datatime_max = 0
	datatime_min = 0
	datatime_average = 0
	if statistics[recv_id].total_times == nil then
		statistics[recv_id].success_times = 0
		statistics[recv_id].fail_times = 0
		statistics[recv_id].total_times = 0
	end
	statistics[recv_id].total_times = statistics[recv_id].total_times + 1
	local cleartime = startAlarm(timeout)
	if serve_expect_data ~= nil then
		if lord_expect_data ~= nil then
			load_flag = recv_data(lord_port, lord_expect_data, recv_id, name,repeat_times,repeat_exit)
			if load_flag == true then
				serve_flag = recv_data(serve_port, serve_expect_data, recv_id, name,repeat_times,repeat_exit)
				if  serve_flag == true then
					statistics[recv_id].success_times = statistics[recv_id].success_times + 1
					if repeat_exit == true then
						record_repeat_flag = true
					end
				else
					statistics[recv_id].fail_times = statistics[recv_id].fail_times + 1
					if repeat_exit == true then
						record_repeat_flag = false
					end
					error_flag = true
				end
			end
		else
			serve_flag = recv_data(serve_port, serve_expect_data, recv_id, name,repeat_times,repeat_exit)
			if  serve_flag == true then
				statistics[recv_id].success_times = statistics[recv_id].success_times + 1
				if repeat_exit == true then
					record_repeat_flag = true
				end
			else
				statistics[recv_id].fail_times = statistics[recv_id].fail_times + 1
				if repeat_exit == true then
					record_repeat_flag = false
				end
				error_flag = true
			end
		end
	else
		load_flag = recv_data(lord_port, lord_expect_data, recv_id, name,repeat_times,repeat_exit)
		if  load_flag == true then
			statistics[recv_id].success_times = statistics[recv_id].success_times + 1
			if repeat_exit == true then
				record_repeat_flag = true
			end
		else
			statistics[recv_id].fail_times = statistics[recv_id].fail_times + 1
			if repeat_exit == true then
				record_repeat_flag = false
			end
			error_flag = true
		end
	end
	if repeat_times > 1 and repeat_exit == false then
		end_time = gettime()
		difftime = end_time - start_time
		repeattiems = repeattiems + 1
		repeattiem = repeattiem + difftime
		if difftime > statistics[recv_id].cmd_maxres_time then
			statistics[recv_id].cmd_maxres_time = difftime
			if statistics[recv_id].cmd_minres_time >= difftime then
				statistics[recv_id].cmd_minres_time = difftime
			else
				if	statistics[recv_id].cmd_minres_time == 0 then
					statistics[recv_id].cmd_minres_time = difftime
				else	
					statistics[recv_id].cmd_minres_time = statistics[recv_id].cmd_minres_time
				end
			end	
		else
			statistics[recv_id].cmd_maxres_time = statistics[recv_id].cmd_maxres_time
			if statistics[recv_id].cmd_minres_time >= difftime then
				statistics[recv_id].cmd_minres_time = difftime
			else
				statistics[recv_id].cmd_minres_time = statistics[recv_id].cmd_minres_time
			end
		end

		if string.find(at_command, "\x1A", 1, true)  then
			if repeattiems == cmd_repeat_times then
				statistics[recv_id].cmd_averes_time = repeattiem / cmd_repeat_times
				repeattiems = 0
				repeattiem = 0
			end
		else
			if repeattiems == repeat_times then
				statistics[recv_id].cmd_averes_time = repeattiem / repeat_times
				repeattiems = 0
				repeattiem = 0
			end
		end
	else
		end_time = gettime()
		difftime = end_time - start_time
		statistics[recv_id].cmd_maxres_time = difftime
		statistics[recv_id].cmd_minres_time = difftime
		statistics[recv_id].cmd_averes_time = difftime
		if cat1_cycle_flag == true then
				cat1list:pushback(recv_id,cycle_index,difftime,timeout)
				--cat1list:show()  //调试信息
		end
		if record_data_flag == true  then
			record_data_flag = false
			record_data_time[record_data_count] = difftime
		end
		if record_data_count == cmd_repeat_times and repeat_exit == false then
			for i=1, cmd_repeat_times do
				for j=1, cmd_repeat_times-i do
					if record_data_time[j] > record_data_time[j+1] then
						temp = record_data_time[j];
						record_data_time[j] = record_data_time[j+1];
						record_data_time[j+1] = temp;
					end
				end
			end
			statistics[recv_id].cmd_maxres_time = record_data_time[cmd_repeat_times]
			statistics[recv_id].cmd_minres_time = record_data_time[1]
			for i=1, cmd_repeat_times do
				record_data_total_time = record_data_total_time + record_data_time[i]
			end
			statistics[recv_id].cmd_averes_time = record_data_total_time / cmd_repeat_times
			record_data_count = 0
			record_data_total_time = 0
		end

	end
	stopAlarm(cleartime)
	return record_repeat_flag
end

--AT接收回复命令操作
function recv_data(port, expect_data, recv_id, name,repeat_times,repeat_exit)
	local total = ""
	local resultlist = {}
	local temp = 1
	--find数据解包
	resultlist = subpackage(expect_data,"|")
	print("[" .. getdate() .."] ".. port .. ":" .. " 执行id[" .. recv_id .. "] 执行次数[" .. statistics[recv_id].total_times .. "] 命令[" .. name .. "]")
	while true do
		data, err = portRecv(port)
		--命令回复错误操作)
		if isInterrupt(data) then
			save_error("[" .. getdate() .."] "..port .. ":" .. "  错误id[" .. recv_id .. "]    执行次数[" .. statistics[recv_id].total_times .. "] 命令[" .. name .. "]")
			save_error("[" .. getdate() .."] ".. "find = " .. expect_data .. "  error\r\n".. "recv = " .. total)
			print("[" .. getdate() .."] ".. port .. ":find: " .. expect_data .. "  error11\r\n".. total)		    
			portFlush(port)
			return false
		elseif err ~= 0 then
			save_error("[" .. getdate() .."] "..port .. ":" .. "  错误id[" .. recv_id .. "]    执行次数[" .. statistics[recv_id].total_times .. "] 命令[" .. name .. "]")
			save_error("[" .. getdate() .."] ".. "find = " .. expect_data .. "  error\r\n".. "recv = " .. total)
			print("[" .. getdate() .."] ".. port .. ":find: " .. expect_data .. "  error\r\n".. total)
			portFlush(port)
			return false
		end
		total = total .. data
		--total = total .. " " .. data
		--命令回复正确操作
		temp = recv_find(port, total, resultlist, #resultlist, temp, recv_id,repeat_times,repeat_exit)
		if  temp == nil then
			portFlush(port)
			return true
		end
	end
end

--数据查找匹配判断
function recv_find(port, tdata, listdata, listlen, n, recv_id,repeat_times,repeat_exit)
	local i
	for i=n, listlen do
		if string.find(tdata, listdata[i], 1, true) then
			print("[" .. getdate() .."] ".. port .. ":find:" .. listdata[i] .. " success")
		else
			return i
		end
	end
	return nil
end

--find数据解包操作
function subpackage(data,reps)
	local resultStrList = {}
	--查找并返回以reps为分隔符的内容
	if data ~= nil then
		string.gsub(data,'[^'..reps..']+',function(w)
					table.insert(resultStrList,w)
					end)
	end
	return resultStrList
end

--错误信息统计
function save_error(errdata)
	local error_name
    local folder
 	folder ="cat1_test_error" .. log_connt .. year .. month .. day
	error_name = read_file_name .. "_" .. year .. month .. day .. "_" .. hour .. min .. sec ..".txt"
	

	local resultFile = io.open(	folder .. "/" .. error_name, "a+b")
	if resultFile == nil then
		os.execute("mkdir " .. folder)
		resultFile = io.open(folder .. "/" .. error_name, "a+b")
		return
	end
	local curResult = string.format("%s\r\n",errdata)
	resultFile:write(curResult)
	resultFile:flush()
end

function escape_csv_field(field)  
    -- 如果字段包含逗号则需要用双引号括起来  
    if string.find(field, "[,\"]") then  
        return '"' .. string.gsub(field, '"', '""') .. '"'  
    else  
        return field  
    end  
end 

--结果保存
function save_result(start_row, end_row)
	local result_name
    local folder
 	folder ="cat1_test_result" .. log_connt .. year .. month .. day
	result_name = read_file_name .. "_" .. year .. month .. day .. "_" .. hour .. min .. sec ..".csv"
	
	os.execute("mkdir " .. folder)
	local resultFile = io.open(	folder .. "/" .. result_name, "wb")
	end_row = end_row - 1
	resultFile:write("id,port,at_cmd,cmd_res_time,cmd_rpeat_times,max_response_time,min_response_time,average_response_time,success_times,fail_times,total_times,cmd_name\r\n")
	for k=start_row, end_row do
		local curResult = string.format("%d,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s,%s\r\n",
										k,
										statistics[k].port,
										escape_csv_field(string.sub(statistics[k].at_cmd, 1, (string.len(statistics[k].at_cmd)-2))),
										statistics[k].cmd_res_time,
										statistics[k].cmd_rpeat_times, 
										statistics[k].cmd_maxres_time,
										statistics[k].cmd_minres_time,
										statistics[k].cmd_averes_time,
										statistics[k].success_times, 
										statistics[k].fail_times,
										statistics[k].total_times,
										statistics[k].cmd_name)
		resultFile:write(curResult)
		resultFile:flush()
	end
	idcnt = 1
end

--服务器搭建
TcpRemote= ""
function creat_serve_task(port)
	--获取当前服务器的客户端列表
	sleep(300)
	local clients_list = tcpServerGetClientList(port)
	for _, client in ipairs(clients_list) do
		--创建回显任务
		TcpRemote = client
		serve.port = TcpRemote
		print("TcpRemote "..TcpRemote)
		sleep(50)
	end
end

starttimer = 0
stoptimer = 0
TotalSendLen = 0
recv_len = 0

function tcp_udp_server_recv_data()
	local recv_err,  tcp_recv_data 
	print("TCP Server Connect Success")
	if serve.port ~= nil then
		starttimer = gettime()
		while true do
			local cleartime = startAlarm(3000)
			tcp_recv_data, recv_err = portRecv(serve.port)
			if isInterrupt(tcp_recv_data) then
				local stoptimerend = gettime()
				local rate = (TotalSendLen * 1.0)/(stoptimerend - starttimer - 3000)
				printf("RX              %dms                       %f KBps              Total %d Byte\r\n",(stoptimerend - starttimer-3000),rate,TotalSendLen)
				pause()
			end
			stopAlarm(cleartime)
			stoptimer = gettime()
			recv_len = recv_len + #tcp_recv_data
			TotalSendLen = TotalSendLen + #tcp_recv_data
		end
	else 
		print("RX Mode TCP Server Connect Fail")
		return 0
	end
end

function tcp_udp_client_recv_data()
	local recv_err,  tcp_recv_data 
	local charToFind1 = ","
	print("TCP Server Connect Success")
	if client.port ~= nil then
		starttimer = gettime()
		while true do
			local cleartime = startAlarm(3000)
			tcp_recv_data, recv_err = portRecv(client.port)
			if isInterrupt(tcp_recv_data) then
			    local stoptimerend = gettime()
				local rate = (TotalSendLen * 1.0)/(stoptimerend - starttimer - 3000)
				printf("RX              %dms                       %f KBps              Total %d Byte\r\n",(stoptimerend - starttimer-3000),rate,TotalSendLen)
				pause()
			end
			stopAlarm(cleartime)
			stoptimer = gettime()
			recv_len = recv_len + (#tcp_recv_data)
			TotalSendLen = TotalSendLen + (#tcp_recv_data)
		end
	else 
		print("RX Mode TCP Server Connect Fail")
		return 0
	end
end

function strfind(str,charToFind,index)
	local foundIndex, endIndex = string.find(str, charToFind, index)
	if foundIndex then
		return foundIndex,endIndex
	else
		return 0,0
	end
end

function StringToHex(str)
    Strlen = string.len(str)
    Hex = ""
    for i = 1, Strlen do
        temp = string.byte(str,i)
		Hex = Hex .. string.format("%X",temp)
    end
    return (Hex)
end

function Getpkdata(packtype,len)
	local j,i
	local pkdata = ""
	local str = ""
	if packtype == "char" then
		HexData = "123456789ABCDEF"
		tmp1,tmp2 = math.modf(len/15)
		tmp3= math.floor(len%15)
		for i=1, tmp1 do
			str = str .. HexData
		end 
		data = string.sub(HexData, 0, tmp3)
		str = str .. data
		pkdata  = str
	elseif packtype == "hex" then
		HexData = "123456789ABCDEF"
		tmp1,tmp2 = math.modf(len/15)
		tmp3= math.floor(len%15)
		for i=1, tmp1 do
			str = str .. HexData
		end 
		data = string.sub(HexData, 0, tmp3)
		str = str .. data
		pkdata = StringToHex(str)
	else
		return 0
	end
	return pkdata
end

function Subpkdata(packtype,len)
	local j
	local pkdata = ""
    local str = ""
	if packtype == "char" then
		HexData = "123456789ABCDEF"
		tmp1,tmp2 = math.modf(len/15)
		tmp3= math.floor(len%15)
		for i=1, tmp1 do
			str = str .. HexData
		end 
		data = string.sub(HexData, 0, tmp3)
		str = str .. data
		pkdata  = str
	elseif packtype == "hex" then
		HexData = "123456789ABCDEF"
		tmp1,tmp2 = math.modf(len/15)
		tmp3= math.floor(len%15)
		for i=1, tmp1 do
			str = str .. HexData
		end 
		data = string.sub(HexData, 0, tmp3)
		str = str .. data
		pkdata  = str
	else
		return 0
	end
	return pkdata
end

function subblesort(sbuuble_sort_arr,id,timeout)
	for i=1,#sbuuble_sort_arr, 1 do
		if sbuuble_sort_arr[i] == nil then
			sbuuble_sort_arr[i] = timeout + 10
		end
	end
	for i=1, #sbuuble_sort_arr,1 do
		for j=1, #sbuuble_sort_arr-i,1 do
			if sbuuble_sort_arr[j] > sbuuble_sort_arr[j+1] then
			temp = sbuuble_sort_arr[j]
			sbuuble_sort_arr[j] = sbuuble_sort_arr[j+1]
			sbuuble_sort_arr[j+1] = temp
			end
		end
	end
	local failtimes = 0
	for i=1, #sbuuble_sort_arr - 1 do
		if sbuuble_sort_arr[i] >= timeout then
			failtimes = failtimes + 1
		else
			record_data_total_time = record_data_total_time + sbuuble_sort_arr[i]
		end	
	end
	statistics[id].cmd_maxres_time = sbuuble_sort_arr[#sbuuble_sort_arr - failtimes -1]
	statistics[id].cmd_minres_time = sbuuble_sort_arr[1]

	--print(record_data_total_time / #sbuuble_sort_arr)
	statistics[id].cmd_averes_time = string.format("%.2f", record_data_total_time / (#sbuuble_sort_arr - failtimes - 1))
	record_data_total_time = 0
	failtimes = 0
end

record_cycle_time_arr = {
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},
	{},

}
cyclenum = 0
cycletotaltime = 0
timeoutval = 0
function CycleCat1List:calc_average_time()
	printnode = self.next
	while printnode do
		for i = cycle_start_index,cycle_end_index do
			if  printnode.id == i then
				if string.find(statistics[printnode.id].at_cmd, "AT+CGATT?", 1, true)  then
					cycletotaltime =  cycletotaltime + printnode.data
					record_cycle_time_arr[i - cycle_start_index + 1][printnode.index] = cycletotaltime
					record_cycle_time_arr[i - cycle_start_index + 1][printnode.index + 1] = 500000
					timeoutval = printnode.index + 1
				else
					cycletotaltime = 0
					record_cycle_time_arr[i - cycle_start_index + 1][printnode.index] = printnode.data
					record_cycle_time_arr[i - cycle_start_index + 1][printnode.index + 1] = printnode.timeout
					timeoutval = printnode.index + 1
				end
			end
		end
       printnode = printnode.next
    end
	for i = cycle_start_index,cycle_end_index do
		subblesort(record_cycle_time_arr[i - cycle_start_index + 1],i,record_cycle_time_arr[i - cycle_start_index + 1][timeoutval])
	end
end

cat1list = CycleCat1List:create()
taskStart(at_task)
taskStart(logtast)