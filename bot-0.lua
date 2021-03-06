redis = (loadfile "redis.lua")()
redis = redis.connect('127.0.0.1', 6379)

function dl_cb(arg, data)
end
function get_admin ()
	if redis:get('bot0adminset') then
		return true
	else
   		print("\n\27[32m  لازمه کارکرد صحیح ، فرامین و امورات مدیریتی ربات تبلیغ گر <<\n                    تعریف کاربری به عنوان مدیر است\n\27[34m                   ایدی خود را به عنوان مدیر وارد کنید\n\27[32m    شما می توانید از ربات زیر شناسه عددی خود را بدست اورید\n\27[34m        ربات:       @id_ProBot")
    	print("\n\27[32m >> Tabchi Bot need a fullaccess user (ADMIN)\n\27[34m Imput Your ID as the ADMIN\n\27[32m You can get your ID of this bot\n\27[34m                 @id_ProBot")
    	print("\n\27[36m                      : شناسه عددی ادمین را وارد کنید << \n >> Imput the Admin ID :\n\27[31m                 ")
    	local admin=io.read()
		redis:del("bot0admin")
    	redis:sadd("bot0admin", admin)
		redis:set('bot0adminset',true)
    	return print("\n\27[36m     ADMIN ID |\27[32m ".. admin .." \27[36m| شناسه ادمین")
	end
end
function get_bot (i, naji)
	function bot_info (i, naji)
		redis:set("bot0id",naji.id_)
		if naji.first_name_ then
			redis:set("bot0fname",naji.first_name_)
		end
		if naji.last_name_ then
			redis:set("bot0lanme",naji.last_name_)
		end
		redis:set("bot0num",naji.phone_number_)
		return naji.id_
	end
	tdcli_function ({ID = "GetMe",}, bot_info, nil)
end
function reload(chat_id,msg_id)
	loadfile("./bot-0.lua")()
	send(chat_id, msg_id, "<i>ok</i>")
end
function is_naji(msg)
    local var = false
	local hash = 'bot0admin'
	local user = msg.sender_user_id_
    local Naji = redis:sismember(hash, user)
	if Naji then
		var = true
	end
	return var
end
function writefile(filename, input)
	local file = io.open(filename, "w")
	file:write(input)
	file:flush()
	file:close()
	return true
end
function process_join(i, naji)
	if naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot0maxjoin", tonumber(Time), true)
	else
		redis:srem("bot0goodlinks", i.link)
		redis:sadd("bot0savedlinks", i.link)
	end
end
function process_link(i, naji)
	if (naji.is_group_ or naji.is_supergroup_channel_) then
		if redis:get('bot0maxgpmmbr') then
			if naji.member_count_ >= tonumber(redis:get('bot0maxgpmmbr')) then
				redis:srem("bot0waitelinks", i.link)
				redis:sadd("bot0goodlinks", i.link)
			else
				redis:srem("bot0waitelinks", i.link)
				redis:sadd("bot0savedlinks", i.link)
			end
		else
			redis:srem("bot0waitelinks", i.link)
			redis:sadd("bot0goodlinks", i.link)
		end
	elseif naji.code_ == 429 then
		local message = tostring(naji.message_)
		local Time = message:match('%d+') + 85
		redis:setex("bot0maxlink", tonumber(Time), true)
	else
		redis:srem("bot0waitelinks", i.link)
	end
end
function find_link(text)
	if text:match("https://telegram.me/joinchat/%S+") or text:match("https://t.me/joinchat/%S+") or text:match("https://telegram.dog/joinchat/%S+") then
		local text = text:gsub("t.me", "telegram.me")
		local text = text:gsub("telegram.dog", "telegram.me")
		for link in text:gmatch("(https://telegram.me/joinchat/%S+)") do
			if not redis:sismember("botalllinks", link) then
				redis:sadd("bot0waitelinks", link)
				redis:sadd("botalllinks", link)
				redis:sadd("bot0alllinkss", link)
			end
		end
	end
end
function add(id)
	local Id = tostring(id)
	if not redis:sismember("bot0all", id) then
		if Id:match("^(%d+)$") then
			redis:sadd("bot0users", id)
			redis:sadd("bot0all", id)
		elseif Id:match("^-100") then
			redis:sadd("bot0supergroups", id)
			redis:sadd("bot0all", id)
		else
			redis:sadd("bot0groups", id)
			redis:sadd("bot0all", id)
		end
	end
	return true
end
function rem(id)
	local Id = tostring(id)
	if redis:sismember("bot0all", id) then
		if Id:match("^(%d+)$") then
			redis:srem("bot0users", id)
			redis:srem("bot0all", id)
		elseif Id:match("^-100") then
			redis:srem("bot0supergroups", id)
			redis:srem("bot0all", id)
		else
			redis:srem("bot0groups", id)
			redis:srem("bot0all", id)
		end
	end
	return true
end
function send(chat_id, msg_id, text)
	 tdcli_function ({
    ID = "SendChatAction",
    chat_id_ = chat_id,
    action_ = {
      ID = "SendMessageTypingAction",
      progress_ = 100
    }
  }, cb or dl_cb, cmd)
	tdcli_function ({
		ID = "SendMessage",
		chat_id_ = chat_id,
		reply_to_message_id_ = msg_id,
		disable_notification_ = 1,
		from_background_ = 1,
		reply_markup_ = nil,
		input_message_content_ = {
			ID = "InputMessageText",
			text_ = text,
			disable_web_page_preview_ = 1,
			clear_draft_ = 0,
			entities_ = {},
			parse_mode_ = {ID = "TextParseModeHTML"},
		},
	}, dl_cb, nil)
end
get_admin()
redis:set("bot0start", true)
function tdcli_update_callback(data)
	if data.ID == "UpdateNewMessage" then
		if redis:get("bot0start") then
			redis:del("bot0start")
			tdcli_function ({
				ID = "GetChats",
				offset_order_ = 9223372036854775807,
				offset_chat_id_ = 0,
				limit_ = 10000},
			function (i,naji)
				local list = redis:smembers("bot0users")
				for i, v in ipairs(list) do
					tdcli_function ({
						ID = "OpenChat",
						chat_id_ = v
					}, dl_cb, cmd)
				end
			end, nil)
		end
		if not redis:get("bot0maxlink") then
			if redis:scard("bot0waitelinks") ~= 0 then
				local links = redis:smembers("bot0waitelinks")
				for x,y in ipairs(links) do
					if x == 6 then redis:setex("bot0maxlink", 65, true) return end
					tdcli_function({ID = "CheckChatInviteLink",invite_link_ = y},process_link, {link=y})
				end
			end
		end
		if redis:get("bot0maxgroups") and redis:scard("bot0supergroups") >= tonumber(redis:get("bot0maxgroups")) then 
			redis:set("bot0maxjoin", true)
			redis:set("bot0offjoin", true)
		end
		if not redis:get("bot0maxjoin") then
			if redis:scard("bot0goodlinks") ~= 0 then
				local links = redis:smembers("bot0goodlinks")
				for x,y in ipairs(links) do
					tdcli_function({ID = "ImportChatInviteLink",invite_link_ = y},process_join, {link=y})
					if x == 2 then redis:setex("bot0maxjoin", 65, true) return end
				end
			end
		end
		local msg = data.message_
		local bot_id = redis:get("bot0id") or get_bot()
		if (msg.sender_user_id_ == 777000 or msg.sender_user_id_ == 178220800) then
			local c = (msg.content_.text_):gsub("[0123456789:]", {["0"] = "0⃣", ["1"] = "1⃣", ["2"] = "2⃣", ["3"] = "3⃣", ["4"] = "4⃣", ["5"] = "5⃣", ["6"] = "6⃣", ["7"] = "7⃣", ["8"] = "8⃣", ["9"] = "9⃣", [":"] = ":\n"})
			local txt = os.date("<i>پیام ارسال گردیده از تلگرام در تاریخ 🗓</i><code> %Y-%m-%d </code><i>🗓 و ساعت ⏰</i><code> %X </code><i>⏰ (به وقت سرور)</i>")
			for k,v in ipairs(redis:smembers('bot0admin')) do
				send(v, 0, txt.."\n\n"..c)
			end
		end
		if tostring(msg.chat_id_):match("^(%d+)") then
			if not redis:sismember("bot0all", msg.chat_id_) then
				redis:sadd("bot0users", msg.chat_id_)
				redis:sadd("bot0all", msg.chat_id_)
			end
		end
		add(msg.chat_id_)
		if msg.date_ < os.time() - 150 then
			return false
		end
		if msg.content_.ID == "MessageText" then
			local text = msg.content_.text_
			local matches
			if redis:get("bot0link") then
				find_link(text)
			end
			if is_naji(msg) then
				find_link(text)
				if text:match("^(حذف لینک) (.*)$") then
					local matches = text:match("^حذف لینک (.*)$")
					if matches == "عضویت" then
						redis:del("bot0goodlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در             انتظار عضویت پاکسازی گردید.")
					elseif matches == "تایید" then
						redis:del("bot0waitelinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های در         انتظار تایید پاکسازی گردید.")
					elseif matches == "ذخیره گردیده" then
						redis:del("bot0savedlinks")
						return send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره            گردیده پاکسازی گردید.")
					end
				elseif text:match("^(حذف کلی لینک) (.*)$") then
					local matches = text:match("^حذف کلی لینک (.*)$")
					if matches == "عضویت" then
						local list = redis:smembers("bot0goodlinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار            عضویت بطورکلی پاکسازی گردید.")
						redis:del("bot0goodlinks")
					elseif matches == "تایید" then
						local list = redis:smembers("bot0waitelinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های در انتظار          تایید بطورکلی پاکسازی گردید.")
						redis:del("bot0waitelinks")
					elseif matches == "ذخیره گردیده" then
						local list = redis:smembers("bot0savedlinks")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک های ذخیره گردیده             بطورکلی پاکسازی گردید.")
						redis:del("bot0savedlinks")
					elseif matches == "ها" then
						local list = redis:smembers("bot0alllinkss")
						for i, v in ipairs(list) do
							redis:srem("botalllinks", v)
						end
						send(msg.chat_id_, msg.id_, "لیست لینک ها بطورکل            ی پاکسازی گردید.")
						redis:del("bot0savedlinks")
					end
				elseif text:match("^(توقف) (.*)$") then
					local matches = text:match("^توقف (.*)$")
					if matches == "عضویت" then	
						redis:set("bot0maxjoin", true)
						redis:set("bot0offjoin", true)
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خود      کار متوقف گردید.")
					elseif matches == "تایید لینک" then	
						redis:set("bot0maxlink", true)
						redis:set("bot0offlink", true)
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک د      ر های در انتظار متوقف گردید.")
					elseif matches == "شناسایی لینک" then	
						redis:del("bot0link")
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی         لینک متوقف گردید.")
					elseif matches == "افزودن مخاطب" then	
						redis:del("bot0savecontacts")
						return send(msg.chat_id_, msg.id_, "فرایند افزودن            خودکار مخاطبین به اشتراک گذاشته گردیده متوقف گردید.")
					end
				elseif text:match("^(شروع) (.*)$") then
					local matches = text:match("^شروع (.*)$")
					if matches == "عضویت" then	
						redis:del("bot0maxjoin")
						redis:del("bot0offjoin")
						return send(msg.chat_id_, msg.id_, "فرایند عضویت خ        ودکار فعال گردید.")
					elseif matches == "تایید لینک" then	
						redis:del("bot0maxlink")
						redis:del("bot0offlink")
						return send(msg.chat_id_, msg.id_, "فرایند تایید لینک های در انتظار فعال گردید.")
					elseif matches == "شناسایی لینک" then	
						redis:set("bot0link", true)
						return send(msg.chat_id_, msg.id_, "فرایند شناسایی لینک ف      عال گردید.")
					elseif matches == "افزودن مخاطب" then	
						redis:set("bot0savecontacts", true)
						return send(msg.chat_id_, msg.id_, "فرایند افزودن خودکا       ر مخاطبین به اشتراک  گذاشته گردیده فعال گردید.")
					end
				elseif text:match("^(حداکثر گروه) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('bot0maxgroups', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>تعداد حداکثر سوپرگرو         ه های تبلیغ‌گر تنظیم گردید به : </i><b> "..matches.." </b>")
				elseif text:match("^(حداقل اعضا) (%d+)$") then
					local matches = text:match("%d+")
					redis:set('bot0maxgpmmbr', tonumber(matches))
					return send(msg.chat_id_, msg.id_, "<i>عضویت در گروه های     با حداقل</i><b> "..matches.." </b> عضو تنظیم گردید.")
				elseif text:match("^(حذف حداکثر گروه)$") then
					redis:del('bot0maxgroups')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز گر     وه نادیده گرفته گردید.")
				elseif text:match("^(حذف حداقل اعضا)$") then
					redis:del('bot0maxgpmmbr')
					return send(msg.chat_id_, msg.id_, "تعیین حد مجاز اع         ضای گروه نادیده گرفته گردید.")
				elseif text:match("^(افزودن مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot0admin', matches) then
						return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر        در حال حاضر مدیر است.</i>")
					elseif redis:sismember('bot0mod', msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دسترسی      ندارید.")
					else
						redis:sadd('bot0admin', matches)
						redis:sadd('bot0mod', matches)
						return send(msg.chat_id_, msg.id_, "<i>مقام کاربر          به مدیر ارتقا یافت</i>")
					end
				elseif text:match("^(افزودن مدیرکل) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot0mod',msg.sender_user_id_) then
						return send(msg.chat_id_, msg.id_, "شما دستر        سی ندارید.")
					end
					if redis:sismember('bot0mod', matches) then
						redis:srem("bot0mod",matches)
						redis:sadd('bot0admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "مقام کاربر ب        ه مدیریت کل ارتقا یافت .")
					elseif redis:sismember('bot0admin',matches) then
						return send(msg.chat_id_, msg.id_, 'درحال حاضر       مدیر هستند.')
					else
						redis:sadd('bot0admin', matches)
						redis:sadd('bot0admin'..tostring(matches),msg.sender_user_id_)
						return send(msg.chat_id_, msg.id_, "کاربر به           مقام مدیرکل منصوب گردید.")
					end
				elseif text:match("^(حذف مدیر) (%d+)$") then
					local matches = text:match("%d+")
					if redis:sismember('bot0mod', msg.sender_user_id_) then
						if tonumber(matches) == msg.sender_user_id_ then
								redis:srem('bot0admin', msg.sender_user_id_)
								redis:srem('bot0mod', msg.sender_user_id_)
							return send(msg.chat_id_, msg.id_, "شما د      یگر مدیر نیستید.")
						end
						return send(msg.chat_id_, msg.id_, "شما دستر      سی ندارید.")
					end
					if redis:sismember('bot0admin', matches) then
						if  redis:sismember('bot0admin'..msg.sender_user_id_ ,matches) then
							return send(msg.chat_id_, msg.id_, "شما نمی توانید مدیری       که به شما مقام داده را عزل کنید.")
						end
						redis:srem('bot0admin', matches)
						redis:srem('bot0mod', matches)
						return send(msg.chat_id_, msg.id_, "کاربر از مقام مد      یریت خلع گردید.")
					end
					return send(msg.chat_id_, msg.id_, "کاربر مورد نظر مد         یر نمی باگردید.")
				elseif text:match("^(تازه سازی ربات)$") then
					get_bot()
					return send(msg.chat_id_, msg.id_, "<i>مشخصات فردی          ربات بروز گردید.</i>")
				elseif text:match("ریپورت") then
					tdcli_function ({
						ID = "SendBotStartMessage",
						bot_user_id_ = 178220800,
						chat_id_ = 178220800,
						parameter_ = 'start'
					}, dl_cb, nil)
				elseif text:match("^(/reload)$") then
					return reload(msg.chat_id_,msg.id_)
				elseif text:match("^(لیست) (.*)$") then
					local matches = text:match("^لیست (.*)$")
					local naji
					if matches == "مخاطبین" then
						return tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},
						function (I, Naji)
							local count = Naji.total_count_
							local text = "مخاطبین : \n"
							for i =0 , tonumber(count) - 1 do
								local user = Naji.users_[i]
								local firstname = user.first_name_ or ""
								local lastname = user.last_name_ or ""
								local fullname = firstname .. " " .. lastname
								text = tostring(text) .. tostring(i) .. ". " .. tostring(fullname) .. " [" .. tostring(user.id_) .. "] = " .. tostring(user.phone_number_) .. "  \n"
							end
							writefile("bot0_contacts.txt", text)
							tdcli_function ({
								ID = "SendMessage",
								chat_id_ = I.chat_id,
								reply_to_message_id_ = 0,
								disable_notification_ = 0,
								from_background_ = 1,
								reply_markup_ = nil,
								input_message_content_ = {ID = "InputMessageDocument",
								document_ = {ID = "InputFileLocal",
								path_ = "bot0_contacts.txt"},
								caption_ = "مخاطبین تبلیغ‌گر شماره 0"}
							}, dl_cb, nil)
							return io.popen("rm -rf bot0_contacts.txt"):read("*all")
						end, {chat_id = msg.chat_id_})
					elseif matches == "پاسخ های خودکار" then
						local text = "<i>لیست پاسخ های خودکار :</i>\n\n"
						local answers = redis:smembers("bot0answerslist")
						for k,v in pairs(answers) do
							text = tostring(text) .. "<i>l" .. tostring(k) .. "l</i>  " .. tostring(v) .. " : " .. tostring(redis:hget("bot0answers", v)) .. "\n"
						end
						if redis:scard('bot0answerslist') == 0  then text = "<code>       EMPTY</code>" end
						return send(msg.chat_id_, msg.id_, text)
					elseif matches == "مسدود" then
						naji = "bot0blockedusers"
					elseif matches == "شخصی" then
						naji = "bot0users"
					elseif matches == "گروه" then
						naji = "bot0groups"
					elseif matches == "سوپرگروه" then
						naji = "bot0supergroups"
					elseif matches == "لینک" then
						naji = "bot0savedlinks"
					elseif matches == "مدیر" then
						naji = "bot0admin"
					else
						return true
					end
					local list =  redis:smembers(naji)
					local text = tostring(matches).." : \n"
					for i, v in pairs(list) do
						text = tostring(text) .. tostring(i) .. "-  " .. tostring(v).."\n"
					end
					writefile(tostring(naji)..".txt", text)
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = 0,
						disable_notification_ = 0,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {ID = "InputMessageDocument",
							document_ = {ID = "InputFileLocal",
							path_ = tostring(naji)..".txt"},
						caption_ = "لیست "..tostring(matches).." های تبلیغ گر شماره 0"}
					}, dl_cb, nil)
					return io.popen("rm -rf "..tostring(naji)..".txt"):read("*all")
				elseif text:match("^(وضعیت مشاهده) (.*)$") then
					local matches = text:match("^وضعیت مشاهده (.*)$")
					if matches == "روشن" then
						redis:set("bot0markread", true)
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پ   یام ها  >>  خوانده گردیده ✔️✔️\n</i><code>(تیک دوم فعال)</code>")
					elseif matches == "خاموش" then
						redis:del("bot0markread")
						return send(msg.chat_id_, msg.id_, "<i>وضعیت پ   یام ها  >>  خوانده نگردیده ✔️\n</i><code>(بدون تیک دوم)</code>")
					end 
				elseif text:match("^(افزودن با پیام) (.*)$") then
					local matches = text:match("^افزودن با پیام (.*)$")
					if matches == "روشن" then
						redis:set("bot0addmsg", true)
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخ      اطب فعال گردید</i>")
					elseif matches == "خاموش" then
						redis:del("bot0addmsg")
						return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخ       اطب faal گردید</i>")
					end
				elseif text:match("^(افزودن با شماره) (.*)$") then
					local matches = text:match("افزودن با شماره (.*)$")
					if matches == "روشن" then
						redis:set("bot0addcontact", true)
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره      هنگام افزودن مخاطب فعال گردید</i>")
					elseif matches == "خاموش" then
						redis:del("bot0addcontact")
						return send(msg.chat_id_, msg.id_, "<i>ارسال شماره      هنگام افزودن مخاطب faal گردید</i>")
					end
				elseif text:match("^(تنظیم پیام افزودن مخاطب) (.*)") then
					local matches = text:match("^تنظیم پیام افزودن مخاطب (.*)")
					redis:set("bot0addmsgtext", matches)
					return send(msg.chat_id_, msg.id_, "<i>پیام افزودن مخاط     ب ثبت  گردید </i>:\n🔹 "..matches.." 🔹")
				elseif text:match('^(تنظیم جواب) "(.*)" (.*)') then
					local txt, answer = text:match('^تنظیم جواب "(.*)" (.*)')
					redis:hset("bot0answers", txt, answer)
					redis:sadd("bot0answerslist", txt)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(txt) .. "<i> | تنظیم گردید به :</i>\n" .. tostring(answer))
				elseif text:match("^(حذف جواب) (.*)") then
					local matches = text:match("^حذف جواب (.*)")
					redis:hdel("bot0answers", matches)
					redis:srem("bot0answerslist", matches)
					return send(msg.chat_id_, msg.id_, "<i>جواب برای | </i>" .. tostring(matches) .. "<i> | از لیست جواب های خودکار پاک گردید.</i>")
				elseif text:match("^(پاسخگوی خودکار) (.*)$") then
					local matches = text:match("^پاسخگوی خودکار (.*)$")
					if matches == "روشن" then
						redis:set("bot0autoanswer", true)
						return send(msg.chat_id_, 0, "<i>پاسخگویی خودکار ت     بلیغ گر فعال گردید</i>")
					elseif matches == "خاموش" then
						redis:del("bot0autoanswer")
						return send(msg.chat_id_, 0, "<i>حالت پاسخگویی خود      کار تبلیغ گر غیر فعال گردید.</i>")
					end
				elseif text:match("^(تازه سازی)$")then
					local list = {redis:smembers("bot0supergroups"),redis:smembers("bot0groups")}
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
						redis:set("bot0contacts", naji.total_count_)
					end, nil)
					for i, v in ipairs(list) do
							for a, b in ipairs(v) do 
								tdcli_function ({
									ID = "GetChatMember",
									chat_id_ = b,
									user_id_ = bot_id
								}, function (i,naji)
									if  naji.ID == "Error" then rem(i.id) 
									end
								end, {id=b})
							end
					end
					return send(msg.chat_id_,msg.id_,"<i>amar </i><code> nuber 0 </code> با موفقیت انجام گردید.")
				elseif text:match("^(وضعیت)$") then
					local s =  redis:get("bot0offjoin") and 0 or redis:get("bot0maxjoin") and redis:ttl("bot0maxjoin") or 0
					local ss = redis:get("bot0offlink") and 0 or redis:get("bot0maxlink") and redis:ttl("bot0maxlink") or 0
					local msgadd = redis:get("bot0addmsg") and "faal" or "غیرفعال"
					local numadd = redis:get("bot0addcontact") and "faal" or "غیرفعال"
					local txtadd = redis:get("bot0addmsgtext") or  "null"
					local autoanswer = redis:get("bot0autoanswer") and "faal" or "غیرفعال"
					local wlinks = redis:scard("bot0waitelinks")
					local glinks = redis:scard("bot0goodlinks")
					local links = redis:scard("bot0savedlinks")
					local offjoin = redis:get("bot0offjoin") and "غیرفعال" or "faal"
					local offlink = redis:get("bot0offlink") and "غیرفعال" or "faal"
					local gp = redis:get("bot0maxgroups") or "تعیین نگردیده"
					local mmbrs = redis:get("bot0maxgpmmbr") or "تعیین نگردیده"
					local nlink = redis:get("bot0link") and "faal" or "غیرفعال"
					local contacts = redis:get("bot0savecontacts") and "faal" or "غیرفعال"
					local fwd =  redis:get("bot0fwdtime") and "faal" or "غیرفعال" 
					local txt = "\n"..tostring(offjoin).."<code> ozviat </code>\n"..tostring(offlink).."<code> تایید لینک  </code>\n"..tostring(nlink).."<code> تشخیص لینک های عضویت </code>\n"..tostring(fwd).."<code> زمانبندی در ارسال </code>\n"..tostring(contacts).."<code> افزودن خودکار مخاطبین </code>\n\n" .. tostring(numadd) .. "<code> افزودن مخاطب با شماره 📞 </code>\n" .. tostring(msgadd) .. "<code> افزودن مخاطب با پیام </code>\n<code> پیام افزودن مخاطب :</code>\n📍 " .. tostring(txtadd) .. " 📍\n〰〰〰ا〰〰〰\n\n⏫<code> سقف تعداد سوپرگروه ها : </code><i>"..tostring(gp).."</i>\n⏬<code> کمترین تعداد اعضای گروه : </code><i>"..tostring(mmbrs).."</i>\n\n<code> لینک های ذخیره گردیده : </code><b>" .. tostring(links) .. "</b>\n<code>⏲	لینک های در انتظار عضویت : </code><b>" .. tostring(glinks) .. "</b>\n🕖   <b>" .. tostring(s) .. " </b><code>ثانیه تا عضویت مجدد</code>\n<code>❄️ لینک های در انتظار تایید : </code><b>" .. tostring(wlinks) .. "درود خداوند برشما باد" .. tostring(ss) .. " </b><code>ثانیه تا تایید لینک مجدد</code>\n good bye"
					return send(msg.chat_id_, 0, txt)
				elseif text:match("^(امار)$") or text:match("^(آمار)$") then
					local gps = redis:scard("bot0groups")
					local sgps = redis:scard("bot0supergroups")
					local usrs = redis:scard("bot0users")
					local links = redis:scard("bot0savedlinks")
					local glinks = redis:scard("bot0goodlinks")
					local wlinks = redis:scard("bot0waitelinks")
					tdcli_function({
						ID = "SearchContacts",
						query_ = nil,
						limit_ = 999999999
					}, function (i, naji)
					redis:set("bot0contacts", naji.total_count_)
					end, nil)
					local contacts = redis:get("bot0contacts")
					local text = [[

          
<code>pv : </code>
<b>]] .. tostring(usrs) .. [[</b>
<code>gp : </code>
<b>]] .. tostring(gps) .. [[</b>
<code>sup : </code>
<b>]] .. tostring(sgps) .. [[</b>
migama hichi]]
					return send(msg.chat_id_, 0, text)
				elseif (text:match("^(ارسال به) (.*)$") and msg.reply_to_message_id_ ~= 0) then
					local matches = text:match("^ارسال به (.*)$")
					local naji
					if matches:match("^(خصوصی)") then
						naji = "bot0users"
					elseif matches:match("^(گروه)$") then
						naji = "bot0groups"
					elseif matches:match("^(سوپرگروه)$") then
						naji = "bot0supergroups"
					else
						return true
					end
					local list = redis:smembers(naji)
					local id = msg.reply_to_message_id_
					if redis:get("bot0fwdtime") then
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
							if i % 4 == 0 then
								os.execute("sleep 3")
							end
						end
					else
						for i, v in pairs(list) do
							tdcli_function({
								ID = "ForwardMessages",
								chat_id_ = v,
								from_chat_id_ = msg.chat_id_,
								message_ids_ = {[0] = id},
								disable_notification_ = 1,
								from_background_ = 1
							}, dl_cb, nil)
						end
					end
						return send(msg.chat_id_, msg.id_, "<i>همم موفقیت فرستاده گردید</i>")
				elseif text:match("^(ارسال زمانی) (.*)$") then
					local matches = text:match("^ارسال زمانی (.*)$")
					if matches == "روشن" then
						redis:set("bot0fwdtime", true)
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال فعال گردید.</i>")
					elseif matches == "خاموش" then
						redis:del("bot0fwdtime")
						return send(msg.chat_id_,msg.id_,"<i>زمان بندی ارسال غیر فعال گردید.</i>")
					end
				elseif text:match("^(ارسال به سوپرگروه) (.*)") then
					local matches = text:match("^ارسال به سوپرگروه (.*)")
					local dir = redis:smembers("bot0supergroups")
					for i, v in pairs(dir) do
						tdcli_function ({
							ID = "SendMessage",
							chat_id_ = v,
							reply_to_message_id_ = 0,
							disable_notification_ = 0,
							from_background_ = 1,
							reply_markup_ = nil,
							input_message_content_ = {
								ID = "InputMessageText",
								text_ = matches,
								disable_web_page_preview_ = 1,
								clear_draft_ = 0,
								entities_ = {},
							parse_mode_ = nil
							},
						}, dl_cb, nil)
					end
                    return send(msg.chat_id_, msg.id_, "<i>با موفقیت فرستاده گردید</i>")
				elseif text:match("^(مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					rem(tonumber(matches))
					redis:sadd("bot0blockedusers",matches)
					tdcli_function ({
						ID = "BlockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر مسدود گردید</i>")
				elseif text:match("^(رفع مسدودیت) (%d+)$") then
					local matches = text:match("%d+")
					add(tonumber(matches))
					redis:srem("bot0blockedusers",matches)
					tdcli_function ({
						ID = "UnblockUser",
						user_id_ = tonumber(matches)
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>مسدودیت کاربر مورد نظر رفع گردید.</i>")	
				elseif text:match('^(تنظیم نام) "(.*)" (.*)') then
					local fname, lname = text:match('^تنظیم نام "(.*)" (.*)')
					tdcli_function ({
						ID = "ChangeName",
						first_name_ = fname,
						last_name_ = lname
					}, dl_cb, nil)
					return send(msg.chat_id_, msg.id_, "<i>نام جدید با موفقیت ثبت گردید.</i>")
				elseif text:match("^(تنظیم نام کاربری) (.*)") then
					local matches = text:match("^تنظیم نام کاربری (.*)")
						tdcli_function ({
						ID = "ChangeUsername",
						username_ = tostring(matches)
						}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>تلاش برای تنظیم نام کاربری...</i>')
				elseif text:match("^(حذف نام کاربری)$") then
					tdcli_function ({
						ID = "ChangeUsername",
						username_ = ""
					}, dl_cb, nil)
					return send(msg.chat_id_, 0, '<i>نام کاربری با موفقیت حذف گردید.</i>')
				elseif text:match('^(ارسال کن) "(.*)" (.*)') then
					local id, txt = text:match('^ارسال کن "(.*)" (.*)')
					send(id, 0, txt)
					return send(msg.chat_id_, msg.id_, "<i>ارسال گردید</i>")
				elseif text:match("^(بگو) (.*)") then
					local matches = text:match("^بگو (.*)")
					return send(msg.chat_id_, 0, matches)
				elseif text:match("^(شناسه من)$") then
					return send(msg.chat_id_, msg.id_, "<i>" .. msg.sender_user_id_ .."</i>")
				elseif text:match("^(ترک کردن) (.*)$") then
					local matches = text:match("^ترک کردن (.*)$") 	
					send(msg.chat_id_, msg.id_, 'تبلیغ‌گر از گروه مورد نظر خارج گردید')
					tdcli_function ({
						ID = "ChangeChatMemberStatus",
						chat_id_ = matches,
						user_id_ = bot_id,
						status_ = {ID = "ChatMemberStatusLeft"},
					}, dl_cb, nil)
					return rem(matches)
				elseif text:match("^(افزودن به همه) (%d+)$") then
					local matches = text:match("%d+")
					local list = {redis:smembers("bot0groups"),redis:smembers("bot0supergroups")}
					for a, b in pairs(list) do
						for i, v in pairs(b) do 
							tdcli_function ({
								ID = "AddChatMember",
								chat_id_ = v,
								user_id_ = matches,
								forward_limit_ =  50
							}, dl_cb, nil)
						end	
					end
					return send(msg.chat_id_, msg.id_, "<i>کاربر مورد نظر به تمام گروه های من دعوت گردید</i>")
				elseif (text:match("^(انلاین)$") and not msg.forward_info_)then
					return tdcli_function({
						ID = "ForwardMessages",
						chat_id_ = msg.chat_id_,
						from_chat_id_ = msg.chat_id_,
						message_ids_ = {[0] = msg.id_},
						disable_notification_ = 0,
						from_background_ = 1
					}, dl_cb, nil)
				elseif text:match("^(راهنما)$") then
					local txt =
					'nadarim'
					return send(msg.chat_id_,msg.id_, txt)
				elseif tostring(msg.chat_id_):match("^-") then
					if text:match("^(ترک کردن)$") then
						rem(msg.chat_id_)
						return tdcli_function ({
							ID = "ChangeChatMemberStatus",
							chat_id_ = msg.chat_id_,
							user_id_ = bot_id,
							status_ = {ID = "ChatMemberStatusLeft"},
						}, dl_cb, nil)
					elseif text:match("^(افزودن همه مخاطبین)$") then
						tdcli_function({
							ID = "SearchContacts",
							query_ = nil,
							limit_ = 999999999
						},function(i, naji)
							local users, count = redis:smembers("bot0users"), naji.total_count_
							for n=0, tonumber(count) - 1 do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = naji.users_[n].id_,
									forward_limit_ = 50
								},  dl_cb, nil)
							end
							for n=1, #users do
								tdcli_function ({
									ID = "AddChatMember",
									chat_id_ = i.chat_id,
									user_id_ = users[n],
									forward_limit_ = 50
								},  dl_cb, nil)
							end
						end, {chat_id=msg.chat_id_})
						return send(msg.chat_id_, msg.id_, "ok")
					end
				end
			end
			if redis:sismember("bot0answerslist", text) then
				if redis:get("bot0autoanswer") then
					if msg.sender_user_id_ ~= bot_id then
						local answer = redis:hget("bot0answers", text)
						send(msg.chat_id_, 0, answer)
					end
				end
			end
		elseif (msg.content_.ID == "MessageContact" and redis:get("bot0savecontacts")) then
			local id = msg.content_.contact_.user_id_
			if not redis:sismember("bot0addedcontacts",id) then
				redis:sadd("bot0addedcontacts",id)
				local first = msg.content_.contact_.first_name_ or "-"
				local last = msg.content_.contact_.last_name_ or "-"
				local phone = msg.content_.contact_.phone_number_
				local id = msg.content_.contact_.user_id_
				tdcli_function ({
					ID = "ImportContacts",
					contacts_ = {[0] = {
							phone_number_ = tostring(phone),
							first_name_ = tostring(first),
							last_name_ = tostring(last),
							user_id_ = id
						},
					},
				}, dl_cb, nil)
				if redis:get("bot0addcontact") and msg.sender_user_id_ ~= bot_id then
					local fname = redis:get("bot0fname")
					local lnasme = redis:get("bot0lname") or ""
					local num = redis:get("bot0num")
					tdcli_function ({
						ID = "SendMessage",
						chat_id_ = msg.chat_id_,
						reply_to_message_id_ = msg.id_,
						disable_notification_ = 1,
						from_background_ = 1,
						reply_markup_ = nil,
						input_message_content_ = {
							ID = "InputMessageContact",
							contact_ = {
								ID = "Contact",
								phone_number_ = num,
								first_name_ = fname,
								last_name_ = lname,
								user_id_ = bot_id
							},
						},
					}, dl_cb, nil)
				end
			end
			if redis:get("bot0addmsg") then
				local answer = redis:get("bot0addmsgtext") or "pm bede"
				send(msg.chat_id_, msg.id_, answer)
			end
		elseif msg.content_.ID == "MessageChatDeleteMember" and msg.content_.id_ == bot_id then
			return rem(msg.chat_id_)
		elseif (msg.content_.caption_ and redis:get("bot0link"))then
			find_link(msg.content_.caption_)
		end
		if redis:get("bot0markread") then
			tdcli_function ({
				ID = "ViewMessages",
				chat_id_ = msg.chat_id_,
				message_ids_ = {[0] = msg.id_} 
			}, dl_cb, nil)
		end
	end
end
