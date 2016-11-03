
--年每月日数表
local m_day={31,28,31,30,31,30,31,31,30,31,30,31}

--8月工作日表
local duty_day={
        1,1,1,1,1,0,0,
        1,1,1,1,1,0,0,
        1,1,1,1,1,0,0,
        1,1,1,1,1,0,0,
        1,1,1
        }

function  getworktime(name)
    local mintime = "09:10:00"
    local maxtime = "18:00:00"
    local off_duty_time  = "09:30:00"
    local jishubu_nine_half = {"吴汉卿","吴灵敏","林文贇","林仁霖","林茂祥","王纯斌","陈金开","陈秋峰","杜思源","林存锈","郭斌","唐君"}

    for _, v in ipairs(jishubu_nine_half) do 
        if v == name then
            off_duty_time  = "10:00:00"
            mintime = "09:40:00"
            maxtime = "18:30:00"
            break
        end
    end

    return mintime, maxtime,off_duty_time
end


function is_work_day(day)
    return duty_day[tonumber(day)] 
end

print "start ..."

-- 读取文件
---
--
--print (arg[0])
--print (arg[1])
--print (arg[2])


if arg[1] == nil then
    print ("命令格式错误");
    print ("请输入考勤原始数据文件");
    return
end



local timestamp={}
local file=io.open(arg[1], "r")


while true do 
    local data = file:read("*line")

    if not data then break end
--    print (data)

    local single_recode = {}
    for w in string.gmatch(data, "%S+") do 
        table.insert(single_recode, w)
    end

    --从记录中对比，同一个同一天是否有重复记录
    --增加记录
    timestamp[#timestamp + 1] = {
            index = single_recode[1],
            day = single_recode[2],
            time = single_recode[3],
            name = single_recode[6]
    }
        
end


file:close()

table.sort(timestamp, function(a,b) return a.index  < b.index end)

print ("统计结果")

local workman_timestap = {}
for i = 1, 100 do
    workman_timestap[i] = {}
end

local workman_name = {}

for _, vsp in ipairs(timestamp) do

   -- kaoqin[vsp.name] = vsp.day
--  print (kaoqin.vsp.name)
    -- 不同人先整理考勤时间


    --同一个人的考勤记录

   local index = tonumber(vsp.index)

   ---[[
    for k, manname in pairs(workman_name) do

          --  print ("test")
          --  print (vsp.name)
          --  print (manname)
            if vsp.name == manname then
                index = k

            --    print ("****************")
             --   print (index, vsp.name)
                
                break
            end
    end
    --]]

   workman_timestap[index][#(workman_timestap[index]) + 1] = {
         day = vsp.day,
        time = vsp.time
     }

    workman_name[index] = vsp.name

end


for i = 1, 100 do

    if #(workman_timestap[i]) > 0 then
        print ("-----------------------------------------------------------------")
        print (workman_name[i])

        table.sort(workman_timestap[i], function(a,b) 
            if a.day == b.day then
                return a.time < b.time 
            else
                return a.day < b.day
            end
        end)

        --当天内去重
        local day_record= { }       
        local maxtime, mintime

        for k, man in ipairs(workman_timestap[i]) do


            if #day_record == 0 or day_record[#day_record].day ~= man.day then
                day_record[#day_record + 1] = {
                    day = man.day,
                    mintime = man.time,
                    maxtime = man.time
                }
                    
            else

               if day_record[#day_record].maxtime < man.time then
                   day_record[#day_record].maxtime = man.time
               end

               if day_record[#day_record].mintime > man.time then
                   day_record[#day_record].mintime = man.time
               end
            end
        end


        local total_work_time = 0 --总计工作时间
       -- local total_work_day = 0 --总计出勤时间
        local count_day = 1
        local year,month,day
        
        --旷工天数
        local absent_day = 0  
        local later_count = 0  --迟到次数
        local early_count = 0   --早退次数
        for _, man in ipairs(day_record) do

            local patten="(%d+):(%d+):(%d+)"
            local patten_year = "(%d+)-(%d+)-(%d+)"
            local maxhour,maxminute,maxsecond = man.maxtime:match(patten)
            local minhour,minminute,minsecond = man.mintime:match(patten)
            year,month,day = man.day:match(patten_year)

            --判断是否工作日旷工
            while count_day < tonumber(day) do
                local count_day_int = os.date("%w",os.time({day=count_day,month=month,year=year}))
                
               -- if tonumber(count_day_int) < 6  and tonumber(count_day_int) > 0 then
               if is_work_day(count_day_int) == 1 then
                    print (os.date("%Y-%m-%d",os.time({day=count_day,month=month,year=year})).." 旷工")
                    absent_day = absent_day + 1
                end

                count_day = count_day + 1
            end

            count_day = count_day + 1
            
            local work_time=  os.difftime(os.time({day=day,month=month,year=year,hour=maxhour,min=maxminute,sec=maxsecond}),
                    os.time({day=day,month=month,year=year,hour=minhour,min=minminute,sec=minsecond}))
            local work_hour = math.floor(work_time/3600)
            local work_min = math.floor((work_time - work_hour * 3600) / 60)

            total_work_time = total_work_time + work_time

            local later_or_early = ""
            local on_duty_from,on_duty_to, off_duty_time = getworktime(workman_name[i])

            if man.mintime > off_duty_time  then
                later_or_early = " 早上旷工 "
                absent_day = absent_day + 0.5
            elseif man.mintime > on_duty_from then
                later_or_early = " 迟到 "
                later_count = later_count + 1
            end

            if man.maxtime < "13:30:00"  then
                later_or_early = later_or_early.." 下午旷工 "
                absent_day = absent_day + 0.5
            elseif man.maxtime < on_duty_to  then
                later_or_early = later_or_early.." 早退 "
                early_count = early_count + 1
            end

            if work_hour < 10 then
                work_hour = "0"..work_hour
            end

            if work_min  < 10 then
                work_min = "0"..work_min
            end


            print(man.day.." 签到 "..man.mintime.." 签退 "..man.maxtime.." 工作时长 "..work_hour.."小时"..work_min.."分钟"..later_or_early
                
            )

          --  total_work_day = total_work_day + 1
        end


         --判断是否工作日旷工,本月剩余
         while count_day <= m_day[tonumber(month)] do
                local count_day_int = os.date("%w",os.time({day=count_day,month=month,year=year}))
                
               if is_work_day(count_day_int) == 1 then
               -- if tonumber(count_day_int) < 6  and tonumber(count_day_int) > 0 then
                    print (os.date("%Y-%m-%d",os.time({day=count_day,month=month,year=year})).." 旷工")
                    absent_day = absent_day + 1
                end

              count_day = count_day + 1
         end

        local total_work_hour = math.floor(total_work_time/3600)
        local total_work_min = math.floor((total_work_time - total_work_hour * 3600) / 60)

        print("本月总签到时长 "..total_work_hour.."小时"..total_work_min.."分钟, ".. --出勤 "..total_work_day.." 天 "..
            "旷工 "..absent_day.."天".." 迟到 "..later_count.."次  早退 "..early_count.."次")

    end
end


--
