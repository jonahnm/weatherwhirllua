local TABLE_TableIndirection = {};
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
obf_cached_str[94] = LUAOBFUSACTOR_DECRYPT_STR_0("\196\191\179\210\173\68\92\250\174\179\199", "\57\148\205\214\180\200\54");
obf_cached_str[93] = LUAOBFUSACTOR_DECRYPT_STR_0("\144\185\231\196\159\177\227\222\162\138\180\131\148\144\190\149\230", "\176\214\213\134");
obf_cached_str[92] = LUAOBFUSACTOR_DECRYPT_STR_0("\185\152\187\198\181\128\138\211\185\134\175\192\181\152\166\214\169", "\178\218\237\200");
obf_cached_str[91] = LUAOBFUSACTOR_DECRYPT_STR_0("\169\49\174\114\172", "\212\217\67\203\20\223\223\37");
obf_cached_str[90] = LUAOBFUSACTOR_DECRYPT_STR_0("\126\2\50\124\75\2\50\116\77\21\36", "\26\46\112\87");
obf_cached_str[89] = LUAOBFUSACTOR_DECRYPT_STR_0("\84\88\203\115\35", "\80\36\42\174\21");
obf_cached_str[88] = LUAOBFUSACTOR_DECRYPT_STR_0("\210\48\226\90\126\99\195\236\33\226\79", "\166\130\66\135\60\27\17");
obf_cached_str[87] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\217\131\239\195\195\22\219\150\196\184\148\49\240\218\190\186", "\167\115\181\226\155\138");
obf_cached_str[86] = LUAOBFUSACTOR_DECRYPT_STR_0("\50\151\111\168\62\143\94\189\50\137\123\174\62\151\114\184\34", "\220\81\226\28");
obf_cached_str[85] = LUAOBFUSACTOR_DECRYPT_STR_0("\76\23\197\169\49", "\184\60\101\160\207\66");
obf_cached_str[84] = LUAOBFUSACTOR_DECRYPT_STR_0("\242\147\19\248\60\252\93\204\130\19\237", "\56\162\225\118\158\89\142");
obf_cached_str[82] = LUAOBFUSACTOR_DECRYPT_STR_0("\0\157\162\255\219\50\177", "\186\85\212\235\146");
obf_cached_str[81] = LUAOBFUSACTOR_DECRYPT_STR_0("\242\207\30\214\11\231", "\215\157\173\116\181\46");
obf_cached_str[80] = LUAOBFUSACTOR_DECRYPT_STR_0("\61\42\234\229\49\50\219\240\61\52\254\227\49\42\247\245\45", "\145\94\95\153");
obf_cached_str[79] = LUAOBFUSACTOR_DECRYPT_STR_0("\248\31\92\248\200", "\78\136\109\57\158\187\130\226");
obf_cached_str[78] = LUAOBFUSACTOR_DECRYPT_STR_0("\241\80\55\208\0\211\71\60\213\0\210", "\101\161\34\82\182");
obf_cached_str[77] = LUAOBFUSACTOR_DECRYPT_STR_0("\163\190\50\31\97\74\140\139\166\12\89\27\108\172\221\247\99", "\233\229\210\83\107\40\46");
obf_cached_str[76] = LUAOBFUSACTOR_DECRYPT_STR_0("\199\196\51\238\198\52\249\76\245\247\96\169\205\21\164\7\177", "\34\129\168\82\154\143\80\156");
obf_cached_str[74] = LUAOBFUSACTOR_DECRYPT_STR_0("\135\247\124\243\236\217\178\235\122\240\250", "\171\215\133\25\149\137");
obf_cached_str[73] = LUAOBFUSACTOR_DECRYPT_STR_0("\3\221\91\78\154\33\212\84\78\140\113\134\123\3\144\96\129", "\211\69\177\58\58");
obf_cached_str[71] = LUAOBFUSACTOR_DECRYPT_STR_0("\26\60\208\93\47\60\208\85\41\43\198", "\59\74\78\181");
obf_cached_str[69] = LUAOBFUSACTOR_DECRYPT_STR_0("\131\255\70\49\87\28", "\26\236\157\44\82\114\44");
obf_cached_str[68] = LUAOBFUSACTOR_DECRYPT_STR_0("\249\224\56\219\244\231\121\130", "\178\151\147\92");
obf_cached_str[66] = LUAOBFUSACTOR_DECRYPT_STR_0("\174\148\230\238\67\240\146\162\203\254\86\236\133\151\200\244\91", "\159\224\199\167\155\55");
obf_cached_str[65] = LUAOBFUSACTOR_DECRYPT_STR_0("\251\115\255\174\96\125", "\231\148\17\149\205\69\77");
obf_cached_str[64] = LUAOBFUSACTOR_DECRYPT_STR_0("\217\114\40\81\252\32\205\219\120\43\88\184\99", "\168\171\23\68\52\157\83");
obf_cached_str[63] = LUAOBFUSACTOR_DECRYPT_STR_0("\193\14\251\221\206\6\255\199\243\61\174\158\198\91\217\140\183", "\169\135\98\154");
obf_cached_str[61] = LUAOBFUSACTOR_DECRYPT_STR_0("\37\94\211\44\129\69\91\39\84\208\37\197\6", "\62\87\59\191\73\224\54");
obf_cached_str[59] = LUAOBFUSACTOR_DECRYPT_STR_0("\149\184\38\24\22\22\194\95\166\175\48", "\49\197\202\67\126\115\100\167");
obf_cached_str[57] = LUAOBFUSACTOR_DECRYPT_STR_0("\163\44\161\72\130\7", "\105\204\78\203\43\167\55\126");
obf_cached_str[55] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\1\51\8\113", "\61\97\82\102\90");
obf_cached_str[54] = LUAOBFUSACTOR_DECRYPT_STR_0("\235\115\118\74\158\31", "\128\132\17\28\41\187\47");
obf_cached_str[52] = LUAOBFUSACTOR_DECRYPT_STR_0("\94\169\197\178\83\174\132\235", "\219\48\218\161");
obf_cached_str[51] = LUAOBFUSACTOR_DECRYPT_STR_0("\84\77\118\145\215\143\119\79\99\186\170\220\83\24\84\192\174", "\235\18\33\23\229\158");
obf_cached_str[50] = LUAOBFUSACTOR_DECRYPT_STR_0("\37\159\52\165\170\169\115\123", "\86\75\236\80\204\201\221");
obf_cached_str[49] = LUAOBFUSACTOR_DECRYPT_STR_0("\92\18\61\173\240\163\64\74\65\24\61\237\161", "\58\46\119\81\200\145\208\37");
obf_cached_str[48] = LUAOBFUSACTOR_DECRYPT_STR_0("\156\88\183\84\147\80\179\78\174\107\226\23\155\13\149\5\234", "\32\218\52\214");
obf_cached_str[46] = LUAOBFUSACTOR_DECRYPT_STR_0("\126\149\230\43\75\149\230\35\77\130\240", "\77\46\231\131");
obf_cached_str[45] = LUAOBFUSACTOR_DECRYPT_STR_0("\149\36\14\232\249\95\182\38\27\195\134\10\230\123\87\185\128", "\59\211\72\111\156\176");
obf_cached_str[43] = LUAOBFUSACTOR_DECRYPT_STR_0("\2\89\140\159", "\144\112\54\227\235\230\78\205");
obf_cached_str[41] = LUAOBFUSACTOR_DECRYPT_STR_0("\84\44\190\85\8\11", "\45\59\78\212\54");
obf_cached_str[40] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\20\254\166\46\4\177\229", "\213\90\118\148");
obf_cached_str[38] = LUAOBFUSACTOR_DECRYPT_STR_0("\172\30\132\95\200\79\3\135\33\160\75\207\69\33\141\34\169", "\113\226\77\197\42\188\32");
obf_cached_str[37] = LUAOBFUSACTOR_DECRYPT_STR_0("\119\133\36\20\61\215", "\119\24\231\78");
obf_cached_str[36] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\10\224\19\40\218\19\241\29\41\218\90\164", "\90\191\127\148\124");
obf_cached_str[35] = LUAOBFUSACTOR_DECRYPT_STR_0("\219\191\81\81\85\219\248\189\68\122\42\142\168\224\8\0\44", "\191\157\211\48\37\28");
obf_cached_str[34] = LUAOBFUSACTOR_DECRYPT_STR_0("\26\61\8\175\48\239\36\59\40\14\95\234\76\184\121\112\108", "\85\92\81\105\219\121\139\65");
obf_cached_str[33] = LUAOBFUSACTOR_DECRYPT_STR_0("\38\81\52\204\155\68", "\134\66\56\87\184\190\116");
obf_cached_str[31] = LUAOBFUSACTOR_DECRYPT_STR_0("\165\202\7\200\128\243", "\129\202\168\109\171\165\195\183");
obf_cached_str[30] = LUAOBFUSACTOR_DECRYPT_STR_0("\168\48\123\24\55", "\143\216\66\30\126\68\155");
obf_cached_str[29] = LUAOBFUSACTOR_DECRYPT_STR_0("\126\185\213\116\42\209\72\170\77\174\195", "\196\46\203\176\18\79\163\45");
obf_cached_str[26] = LUAOBFUSACTOR_DECRYPT_STR_0("\128\111\6\9\3", "\81\206\60\83\91\79");
obf_cached_str[25] = LUAOBFUSACTOR_DECRYPT_STR_0("\14\229\66\92\54\81", "\19\97\135\40\63");
obf_cached_str[23] = LUAOBFUSACTOR_DECRYPT_STR_0("\147\234\4\69\190\205\41\67\179\216\50\85", "\44\221\185\64");
obf_cached_str[22] = LUAOBFUSACTOR_DECRYPT_STR_0("\68\209\178\79\94\45", "\29\43\179\216\44\123");
obf_cached_str[21] = LUAOBFUSACTOR_DECRYPT_STR_0("\56\166\130\88\166\41", "\24\92\207\225\44\131\25");
obf_cached_str[20] = LUAOBFUSACTOR_DECRYPT_STR_0("\253\135\16\225\144\216\202\213\159\46\163\232\137\156\131\206\65", "\175\187\235\113\149\217\188");
obf_cached_str[18] = LUAOBFUSACTOR_DECRYPT_STR_0("\88\67\95\242\103\131\139\14\88\69\78\184\37", "\107\57\54\43\157\21\230\231");
obf_cached_str[16] = LUAOBFUSACTOR_DECRYPT_STR_0("\72\199\234\66", "\224\58\168\133\54\58\146");
obf_cached_str[15] = LUAOBFUSACTOR_DECRYPT_STR_0("\94\44\102\239\82\116\87", "\32\56\64\19\156\58");
obf_cached_str[14] = LUAOBFUSACTOR_DECRYPT_STR_0("\213\92\117\12\224\92\117\4\230\75\99", "\106\133\46\16");
obf_cached_str[13] = LUAOBFUSACTOR_DECRYPT_STR_0("\152\254\192\214\19\202\183\112\170\205\151\147\111\157\234\59\238", "\30\222\146\161\162\90\174\210");
obf_cached_str[12] = LUAOBFUSACTOR_DECRYPT_STR_0("\226\204\206\41\163\149", "\93\134\165\173");
obf_cached_str[11] = LUAOBFUSACTOR_DECRYPT_STR_0("\162\122\179\147\39\191\61\233", "\83\205\24\217\224");
obf_cached_str[10] = LUAOBFUSACTOR_DECRYPT_STR_0("\70\217\33\211\22\66\192\48\221\23\66\137\101", "\100\39\172\85\188");
obf_cached_str[9] = LUAOBFUSACTOR_DECRYPT_STR_0("\138\165\16\80\159\239\202\162\189\46\18\231\190\156\244\236\65", "\175\204\201\113\36\214\139");
obf_cached_str[7] = LUAOBFUSACTOR_DECRYPT_STR_0("\188\23\90\64\225\83\229\130\6\90\85", "\128\236\101\63\38\132\33");
obf_cached_str[5] = LUAOBFUSACTOR_DECRYPT_STR_0("\210\19\18\192\190\72\137", "\230\180\127\103\179\214\28");
obf_cached_str[4] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\150\186\74\23", "\112\69\228\223\44\100\232\113");
obf_cached_str[3] = LUAOBFUSACTOR_DECRYPT_STR_0("\58\228\168\219\21\226\125\179\9\243\190", "\221\106\150\205\189\112\144\24");
obf_cached_str[2] = LUAOBFUSACTOR_DECRYPT_STR_0("\168\24\231\187\254\219\181\25", "\168\199\122\141\216\208");
obf_cached_str[1] = LUAOBFUSACTOR_DECRYPT_STR_0("\245\132\61\216\46\245\132", "\71\135\225\76\173");
obf_cached_str[0] = LUAOBFUSACTOR_DECRYPT_STR_0("\38\19\58\177\125\30", "\159\73\113\80\210\88\46");
TABLE_TableIndirection[obf_cached_str[0]] = _G[obf_cached_str[1]](obf_cached_str[2]);
_G[obf_cached_str[3]] = {[obf_cached_str[4]]=nil,[obf_cached_str[5]]=""};
_G[obf_cached_str[7]].loadPrefs = function()
	TABLE_TableIndirection[obf_cached_str[9]] = 0 - 0;
	TABLE_TableIndirection[obf_cached_str[10]] = nil;
	TABLE_TableIndirection[obf_cached_str[11]] = nil;
	TABLE_TableIndirection[obf_cached_str[12]] = nil;
	while true do
		if (((2978 + 1112) < (5650 - (915 + 82))) and (TABLE_TableIndirection[obf_cached_str[13]] == (5 - 3))) then
			_G[obf_cached_str[14]][obf_cached_str[15]] = _G[obf_cached_str[16]] .. "/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist";
			TABLE_TableIndirection[obf_cached_str[18]]:drain();
			break;
		end
		if ((TABLE_TableIndirection[obf_cached_str[20]] == (1 + 0)) or ((3487 - 835) < (1383 - (1069 + 118)))) then
			TABLE_TableIndirection[obf_cached_str[21]] = TABLE_TableIndirection[obf_cached_str[22]][obf_cached_str[23]]:dictionaryWithContentsOfURL(TABLE_TableIndirection[obf_cached_str[25]][obf_cached_str[26]]:fileURLWithPath(TABLE_TableIndirection["objstr%0"]), nil);
			_G[obf_cached_str[29]][obf_cached_str[30]] = TABLE_TableIndirection[obf_cached_str[31]].tolua(TABLE_TableIndirection[obf_cached_str[33]]);
			TABLE_TableIndirection[obf_cached_str[34]] = 4 - 2;
		end
		if (((9045 - 4910) < (838 + 3979)) and (TABLE_TableIndirection[obf_cached_str[35]] == (0 - 0))) then
			TABLE_TableIndirection[obf_cached_str[36]] = TABLE_TableIndirection[obf_cached_str[37]][obf_cached_str[38]]:new();
			TABLE_TableIndirection[obf_cached_str[40]] = TABLE_TableIndirection[obf_cached_str[41]].toobj(tostring(_G[obf_cached_str[43]] .. "/var/mobile/Library/Preferences/com.sora.weatherwhirl.plist"));
			TABLE_TableIndirection[obf_cached_str[45]] = 1 + 0;
		end
	end
end;
_G[obf_cached_str[46]].flush = function()
	TABLE_TableIndirection[obf_cached_str[48]] = 791 - (368 + 423);
	TABLE_TableIndirection[obf_cached_str[49]] = nil;
	TABLE_TableIndirection[obf_cached_str[50]] = nil;
	while true do
		if (((854 - 582) == (290 - (10 + 8))) and (TABLE_TableIndirection[obf_cached_str[51]] == (3 - 2))) then
			TABLE_TableIndirection[obf_cached_str[52]]:writeToURL_atomically(TABLE_TableIndirection[obf_cached_str[54]][obf_cached_str[55]]:fileURLWithPath(TABLE_TableIndirection[obf_cached_str[57]].toobj(_G[obf_cached_str[59]].flushTo)), true);
			TABLE_TableIndirection[obf_cached_str[61]]:drain();
			break;
		end
		if (((542 - (416 + 26)) <= (9971 - 6848)) and (TABLE_TableIndirection[obf_cached_str[63]] == (0 + 0))) then
			TABLE_TableIndirection[obf_cached_str[64]] = TABLE_TableIndirection[obf_cached_str[65]][obf_cached_str[66]]:new();
			TABLE_TableIndirection[obf_cached_str[68]] = TABLE_TableIndirection[obf_cached_str[69]].toobj(_G[obf_cached_str[71]].prefs);
			TABLE_TableIndirection[obf_cached_str[73]] = 1 - 0;
		end
	end
end;
_G[obf_cached_str[74]].customBackground = function(For)
	TABLE_TableIndirection[obf_cached_str[76]] = 438 - (145 + 293);
	while true do
		if (((431 - (44 + 386)) == TABLE_TableIndirection[obf_cached_str[77]]) or ((2855 - (998 + 488)) > (1585 + 3402))) then
			if (not _G[obf_cached_str[78]][obf_cached_str[79]][obf_cached_str[80]][For] or ((707 + 156) >= (5356 - (201 + 571)))) then
				return nil;
			end
			return TABLE_TableIndirection[obf_cached_str[81]][obf_cached_str[82]]:imageWithContentsOfFile(_G[obf_cached_str[84]][obf_cached_str[85]][obf_cached_str[86]][For]);
		end
		if ((TABLE_TableIndirection[obf_cached_str[87]] == (1138 - (116 + 1022))) or ((3014 - 2290) >= (980 + 688))) then
			if (((1562 - 1134) < (6406 - 4602)) and not _G[obf_cached_str[88]][obf_cached_str[89]]) then
				return nil;
			end
			if (not _G[obf_cached_str[90]][obf_cached_str[91]][obf_cached_str[92]] or ((4184 - (814 + 45)) > (11366 - 6753))) then
				return nil;
			end
			TABLE_TableIndirection[obf_cached_str[93]] = 1 + 0;
		end
	end
end;
return _G[obf_cached_str[94]];

