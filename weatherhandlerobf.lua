local obf_cached_str = {};
local obf_stringchar = string.char;
local obf_stringbyte = string.byte;
local obf_stringsub = string.sub;
local obf_bitlib = bit32 or bit;
local obf_XOR = obf_bitlib.bxor;
local obf_tableconcat = table.concat;
local obf_tableinsert = table.insert;
local function LUAOBFUSACTOR_DECRYPT_STR_0(LUAOBFUSACTOR_STR, LUAOBFUSACTOR_KEY)
	local result = {};
	for i = 1, #LUAOBFUSACTOR_STR do
		obf_tableinsert(result, obf_stringchar(obf_XOR(obf_stringbyte(obf_stringsub(LUAOBFUSACTOR_STR, i, i + 1)), obf_stringbyte(obf_stringsub(LUAOBFUSACTOR_KEY, 1 + (i % #LUAOBFUSACTOR_KEY), 1 + (i % #LUAOBFUSACTOR_KEY) + 1))) % 256));
	end
	return obf_tableconcat(result);
end
obf_cached_str[97] = LUAOBFUSACTOR_DECRYPT_STR_0("\42\146\186\94\7\137\2\4\101\135\179\67\17\140\2", "\112\69\228\223\44\100\232\113");
obf_cached_str[96] = LUAOBFUSACTOR_DECRYPT_STR_0("\175\207\31\251\125\248\237\222\28\255\109\242\190", "\150\205\189\112\144\24");
obf_cached_str[95] = LUAOBFUSACTOR_DECRYPT_STR_0("\9\238\185\164\184\184\181\31\233\248\179\160\178\178\30\254", "\199\122\141\216\208\204\221");
obf_cached_str[94] = LUAOBFUSACTOR_DECRYPT_STR_0("\135\41\218\82\228\141\35\216\22\244", "\135\225\76\173\114");
obf_cached_str[93] = LUAOBFUSACTOR_DECRYPT_STR_0("\18\60\183\57\92\119\58\26\41", "\73\113\80\210\88\46\87");
obf_cached_str[92] = LUAOBFUSACTOR_DECRYPT_STR_0("\203\10\131\225\211\131\6\140\227\207\205\28\139\227\211\131\29\131\254\196", "\170\163\111\226\151");
obf_cached_str[91] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\1\134\195\184\57\26\135\134\184\57\7\140", "\202\88\110\226\166");
obf_cached_str[90] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\239\54\186\178\190\25\211\239\63", "\107\178\134\81\210\198\158");
obf_cached_str[75] = LUAOBFUSACTOR_DECRYPT_STR_0("\242\253", "\164\216\137\187");
obf_cached_str[72] = LUAOBFUSACTOR_DECRYPT_STR_0("\18\74", "\114\56\62\101\73\71\141");
obf_cached_str[63] = LUAOBFUSACTOR_DECRYPT_STR_0("\158\197", "\60\180\164\142");
obf_cached_str[61] = LUAOBFUSACTOR_DECRYPT_STR_0("\112\41\86\52\32\90\184\66\39\31\55\53\91\246\22\46\80\42\32\93\249\69\60\31\62\44\82\253\24\102\17", "\152\54\72\63\88\69\62");
obf_cached_str[59] = LUAOBFUSACTOR_DECRYPT_STR_0("\77\250", "\174\103\142\197");
obf_cached_str[51] = LUAOBFUSACTOR_DECRYPT_STR_0("\236\60\33\137\186\16\242\207\111", "\156\168\78\64\224\212\121");
obf_cached_str[48] = LUAOBFUSACTOR_DECRYPT_STR_0("\225\85\121\24\188\26\135\64\127\84\174\12\206\64\117\84\191\17\213\81\115\21\170\10\137", "\126\167\52\16\116\217");
obf_cached_str[45] = LUAOBFUSACTOR_DECRYPT_STR_0("\19\25\188\37\4\25\189\46\93\86", "\75\103\118\217");
obf_cached_str[44] = LUAOBFUSACTOR_DECRYPT_STR_0("\190\248\61\85\182", "\199\235\144\82\61\152");
obf_cached_str[42] = LUAOBFUSACTOR_DECRYPT_STR_0("\151\235\37\222\12\238\39\200\246\249\41\202\20\162\115\205\165\230\36\138", "\167\214\137\74\171\120\206\83");
obf_cached_str[40] = LUAOBFUSACTOR_DECRYPT_STR_0("\4\193\75\96\114\110", "\135\108\174\62\18\30\23\147");
obf_cached_str[38] = LUAOBFUSACTOR_DECRYPT_STR_0("\189\214\80\89\31\162", "\126\219\185\34\61");
obf_cached_str[35] = LUAOBFUSACTOR_DECRYPT_STR_0("\15\206\62\133\40\213\56\141\45\129\63\156\59\200\34\143\104", "\232\73\161\76");
obf_cached_str[28] = LUAOBFUSACTOR_DECRYPT_STR_0("\159\63\33\226\136\254\205\100\117\181\137\252\152\63\117\181\220\175\155\57\37\180\139\169\156\100\34\228\139\251\147\111", "\202\171\92\71\134\190");
obf_cached_str[23] = LUAOBFUSACTOR_DECRYPT_STR_0("\14\181\136\54\205\11\181\133\26\216\12\187\140\50\203\66\185\132\56\203\6\179\138\57\205\7\224\203", "\185\98\218\235\87");
obf_cached_str[22] = LUAOBFUSACTOR_DECRYPT_STR_0("\149\196\217\5\16\46\252\215\223\3\17\103\252\212\210\74\8\62\175\215\151\4\7\46\184\131\195\5\66\60\189\202\195\74\4\36\174\131\199\15\16\38\181\208\196\3\13\37\242", "\75\220\163\183\106\98");
obf_cached_str[19] = LUAOBFUSACTOR_DECRYPT_STR_0("\69\77\3\36\93\75\15\43\100\67\14\36\78\71\18\101\69\77\3\36\93\75\15\43\19\2", "\69\41\34\96");
obf_cached_str[18] = LUAOBFUSACTOR_DECRYPT_STR_0("\142\70\205\161\46\89\62\198\251\90\198\163\59\68\57\206\181\23", "\161\219\54\169\192\90\48\80");
obf_cached_str[16] = LUAOBFUSACTOR_DECRYPT_STR_0("\48\177\216\203\136\40\117", "\84\121\223\177\191\237\76");
obf_cached_str[12] = LUAOBFUSACTOR_DECRYPT_STR_0("\137\104\104\32\22\112\180", "\35\200\29\28\72\115\20\154");
obf_cached_str[9] = LUAOBFUSACTOR_DECRYPT_STR_0("\250\82\179\69\244\94\169\65\188\81\168\84\249\84\166\85\232\22", "\38\156\55\199");
obf_cached_str[8] = LUAOBFUSACTOR_DECRYPT_STR_0("\64\219\63", "\152\38\189\86\156\32\24\133");
obf_cached_str[7] = LUAOBFUSACTOR_DECRYPT_STR_0("\161\55\31\56", "\155\203\68\112\86\19\197");
obf_cached_str[6] = LUAOBFUSACTOR_DECRYPT_STR_0("\118\58\3\28\247\93\23\54\23\250\121\27\35\21\251", "\158\48\118\66\114");
obf_cached_str[4] = LUAOBFUSACTOR_DECRYPT_STR_0("\1\158\98\31\168", "\38\84\215\41\118\220\70");
obf_cached_str[2] = LUAOBFUSACTOR_DECRYPT_STR_0("\0\194\56\192\208\44\206\43\209\245\44\195", "\156\67\173\74\165");
obf_cached_str[0] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\193\209\38\168\168\213\29", "\126\177\163\187\69\134\219\167");
local objc = require(obf_cached_str[0]);
objc.load(obf_cached_str[2]);
objc.load(obf_cached_str[4]);
objc.load(obf_cached_str[6]);
local json = require(obf_cached_str[7]);
local ffi = require(obf_cached_str[8]);
weatherhandler = {};
local function fetchForecast(gmcurtime, path)
	print(obf_cached_str[9]);
	local releasepool = objc.NSAutoreleasePool:new();
	print(obf_cached_str[12]);
	local locationManager = objc.CLLocationManager:alloc():init();
	print(obf_cached_str[16]);
	locationManager:startUpdatingLocation();
	print(obf_cached_str[18]);
	print(obf_cached_str[19] .. tostring(locationManager.location));
	if not locationManager.location then
		error(obf_cached_str[22]);
	end
	print(obf_cached_str[23] .. tostring(locationManager.location.coordinate));
	local str = string.format("http://api.openweathermap.org/data/3.0/onecall?lat=%f&lon=%f&appid=" .. obf_cached_str[28], locationManager.location.coordinate.latitude, locationManager.location.coordinate.longitude);
	print(obf_cached_str[35]);
	locationManager:stopUpdatingLocation();
	local response = dohttp(str);
	print(response);
	local obj = json.decode(response);
	local toencode = {[obf_cached_str[38]]=gmcurtime.yday,[obf_cached_str[40]]=obj.hourly};
	local towrite;
	print(obf_cached_str[42]);
	local thepcall, err = pcall(function()
		towrite = json.encode(toencode);
	end);
	if (not thepcall and err) then
		print(obf_cached_str[44] .. tostring(err));
		return {};
	end
	print(obf_cached_str[45] .. towrite);
	local fd, err = io.open(path, "w");
	if not fd then
		print(obf_cached_str[48]);
		print(err);
		return {};
	end
	fd:write(towrite);
	fd:close();
	print(obf_cached_str[51]);
	releasepool:drain();
	return toencode.hourly;
end
local function file_exists(name)
	local f = io.open(name, "r");
	return (f ~= nil) and f:close();
end
local function getForecast()
	local path = rootpath("/Library/Application Support/WeatherWhirl/Forecast.json");
	local time = os.date(obf_cached_str[59]);
	if not file_exists(path) then
		return fetchForecast(time, path);
	else
		local fd = io.open(path);
		if not fd then
			print(obf_cached_str[61]);
			return {};
		end
		local jsonstr = fd:read(obf_cached_str[63]);
		local obj = json.decode(jsonstr);
		local wasForDay = obj.forday;
		print(wasForDay);
		if (wasForDay ~= time.yday) then
			fd:close();
			os.remove(path);
			return fetchForecast(time, path);
		end
		fd:close();
		return obj.hourly;
	end
end
local function getIDOfCurrentWeather()
	local forecast = getForecast();
	local curTime = os.date(obf_cached_str[72]);
	local name, id;
	for i, v in ipairs(forecast) do
		local dt = v.dt;
		local forecastTime = os.date(obf_cached_str[75], dt);
		if ((forecastTime.hour ~= curTime.hour) or (forecastTime.wday ~= curTime.wday)) then
		else
			name = v.weather[1].description;
			id = v.weather[1].id;
			break;
		end
	end
	return name, id;
end
weatherhandler.UIImageForCurrentWeather = function()
	local name, id;
	if Preferences.prefs then
		if not Preferences.prefs.overrideNext then
			name, id = getIDOfCurrentWeather();
		else
			name = Preferences.prefs.override;
			if (name == obf_cached_str[90]) then
				id = 500;
			elseif (name == obf_cached_str[91]) then
				id = 501;
			elseif (name == obf_cached_str[92]) then
				id = 502;
			elseif (name == obf_cached_str[93]) then
				id = 800;
			elseif (name == obf_cached_str[94]) then
				id = 801;
			elseif (name == obf_cached_str[95]) then
				id = 802;
			elseif (name == obf_cached_str[96]) then
				id = 803;
			elseif (name == obf_cached_str[97]) then
				id = 804;
			end
			Preferences.prefs.overrideNext = false;
			Preferences.flush();
		end
	else
		name, id = getIDOfCurrentWeather();
	end
	local animpath;
	local filepath;
	local animImg;
	if (id == 800) then
		animpath = rootpath("/Library/Application Support/WeatherWhirl/sunAnim.gif");
		filepath = rootpath("/Library/Application Support/WeatherWhirl/clearskies.jpg");
	elseif ((id <= 804) and (id >= 801)) then
		filepath = rootpath("/Library/Application Support/WeatherWhirl/clearskies.jpg");
	end
	if ((id >= 500) and (id <= 531)) then
		filepath = rootpath("/Library/Application Support/WeatherWhirl/grey.jpg");
	end
	print(filepath);
	local image;
	print(name);
	image = Preferences.customBackground(name);
	if not image then
		image = objc.UIImage:imageWithContentsOfFile(objc.toobj(filepath));
	end
	if animpath then
		local gifData = objc.NSData:dataWithContentsOfFile(objc.toobj(animpath));
		animImg = objc.FLAnimatedImage:animatedImageWithGIFData(gifData);
	end
	return id, image, animImg;
end;
return weatherhandler;

