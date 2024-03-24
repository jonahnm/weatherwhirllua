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
local obf_OR = obf_bitlib.bor;
local obf_AND = obf_bitlib.band;
obf_cached_str[168] = LUAOBFUSACTOR_DECRYPT_STR_0("\71\90\121\13\92\86\102\13\74\91\98\1\74\66\49\88", "\104\47\53\20");
obf_cached_str[166] = LUAOBFUSACTOR_DECRYPT_STR_0("\207\35\250\70\180\206\35\230\76\186\209\99\166", "\213\189\70\150\35");
obf_cached_str[161] = LUAOBFUSACTOR_DECRYPT_STR_0("\246\178\5\14\115\206\252\187\29", "\152\149\222\106\123\23");
obf_cached_str[156] = LUAOBFUSACTOR_DECRYPT_STR_0("\133\113\34\2\220\250\219\131\106", "\178\230\29\77\119\184\172");
obf_cached_str[151] = LUAOBFUSACTOR_DECRYPT_STR_0("\173\227\178\169\170\217\180\185\185", "\220\206\143\221");
obf_cached_str[146] = LUAOBFUSACTOR_DECRYPT_STR_0("\252\125\91\163\50\232\245\250\102", "\156\159\17\52\214\86\190");
obf_cached_str[141] = LUAOBFUSACTOR_DECRYPT_STR_0("\14\61\58\104\9\72\4\52\34", "\30\109\81\85\29\109");
obf_cached_str[136] = LUAOBFUSACTOR_DECRYPT_STR_0("\85\163\51\11\23\213\250\83\184", "\147\54\207\92\126\115\131");
obf_cached_str[131] = LUAOBFUSACTOR_DECRYPT_STR_0("\84\84\11\203\83\110\13\219\64", "\190\55\56\100");
obf_cached_str[128] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\234\201\212\64\236\198", "\33\139\163\128\185");
obf_cached_str[127] = LUAOBFUSACTOR_DECRYPT_STR_0("\1\175\122\231\78\210", "\226\110\205\16\132\107");
obf_cached_str[126] = LUAOBFUSACTOR_DECRYPT_STR_0("\55\19\188\233\56\226\216\48\30\233\177", "\183\68\118\204\129\81\144");
obf_cached_str[125] = LUAOBFUSACTOR_DECRYPT_STR_0("\88\12\130\30\33\57\24\174\76", "\203\59\96\237\107\69\111\113");
obf_cached_str[123] = LUAOBFUSACTOR_DECRYPT_STR_0("\24\122\210\5\103\193\36\76\255\21\114\221\51\121\252\31\127", "\174\86\41\147\112\19");
obf_cached_str[122] = LUAOBFUSACTOR_DECRYPT_STR_0("\139\42\172\194\157\3", "\210\228\72\198\161\184\51");
obf_cached_str[121] = LUAOBFUSACTOR_DECRYPT_STR_0("\205\226\162\221\242\204\226\190\215\252\211\162\254", "\147\191\135\206\184");
obf_cached_str[118] = LUAOBFUSACTOR_DECRYPT_STR_0("\20\104\121\9\246\91\38", "\67\65\33\48\100\151\60");
obf_cached_str[117] = LUAOBFUSACTOR_DECRYPT_STR_0("\221\135\214\32\194\249", "\52\178\229\188\67\231\201");
obf_cached_str[116] = LUAOBFUSACTOR_DECRYPT_STR_0("\168\207\68\83\71\15\107", "\45\203\163\43\38\35\42\91");
obf_cached_str[115] = LUAOBFUSACTOR_DECRYPT_STR_0("\41\164\77\27\197\193\2\54\189\72\11\128\245\7\45\160\12\49\228\184\78", "\110\89\200\44\120\160\130");
obf_cached_str[113] = LUAOBFUSACTOR_DECRYPT_STR_0("\56\27\63\240\229\173\176\21\17\60\195\223\171\181", "\194\112\116\82\149\182\206");
obf_cached_str[112] = LUAOBFUSACTOR_DECRYPT_STR_0("\234\27\95\128\90\93", "\62\133\121\53\227\127\109\79");
obf_cached_str[111] = LUAOBFUSACTOR_DECRYPT_STR_0("\131\64\86\82\177\221\91\134\103\82\94\183\204", "\62\226\46\63\63\208\169");
obf_cached_str[110] = LUAOBFUSACTOR_DECRYPT_STR_0("\177\120\227\242\136\142\124\231\226\200\232", "\237\216\21\130\149");
obf_cached_str[107] = LUAOBFUSACTOR_DECRYPT_STR_0("\213\47\8\30\139\85\25\98\246\7\0\29\131\95\29\64\250\6\62", "\22\147\99\73\112\226\56\120");
obf_cached_str[106] = LUAOBFUSACTOR_DECRYPT_STR_0("\115\245\35\53\118\244", "\196\28\151\73\86\83");
obf_cached_str[105] = LUAOBFUSACTOR_DECRYPT_STR_0("\10\203\118\75\6\240\126\73\20\131\39", "\44\99\166\23");
obf_cached_str[99] = LUAOBFUSACTOR_DECRYPT_STR_0("\198\248\175\53\221\244\176\53\235\249\148\57\235\224", "\80\142\151\194");
obf_cached_str[98] = LUAOBFUSACTOR_DECRYPT_STR_0("\21\183\130\14\95\229", "\109\122\213\232");
obf_cached_str[97] = LUAOBFUSACTOR_DECRYPT_STR_0("\217\231\120\253\143\241\211\238\96", "\167\186\139\23\136\235");
obf_cached_str[95] = LUAOBFUSACTOR_DECRYPT_STR_0("\205\174\223\216", "\110\190\199\165\189\19\145\61");
obf_cached_str[94] = LUAOBFUSACTOR_DECRYPT_STR_0("\64\225\76\142\70\253\28\208", "\224\34\142\57");
obf_cached_str[92] = LUAOBFUSACTOR_DECRYPT_STR_0("\147\245\152\115", "\118\224\156\226\22\80\136\214");
obf_cached_str[91] = LUAOBFUSACTOR_DECRYPT_STR_0("\68\67\212\173\242\219\3\28", "\168\38\44\161\195\150");
obf_cached_str[89] = LUAOBFUSACTOR_DECRYPT_STR_0("\143\251\9\35\177\132\230\1\35\172\145\253\1\49\231\215", "\194\231\148\100\70");
obf_cached_str[88] = LUAOBFUSACTOR_DECRYPT_STR_0("\234\186\2\201\89", "\60\140\200\99\164");
obf_cached_str[87] = LUAOBFUSACTOR_DECRYPT_STR_0("\50\17\149\22\69\35", "\33\80\126\224\120");
obf_cached_str[85] = LUAOBFUSACTOR_DECRYPT_STR_0("\101\136\198\32\86\43\85\175", "\78\48\193\149\67\36");
obf_cached_str[84] = LUAOBFUSACTOR_DECRYPT_STR_0("\9\29\88\196\233\34", "\235\102\127\50\167\204\18");
obf_cached_str[83] = LUAOBFUSACTOR_DECRYPT_STR_0("\2\124\23\113\79\29\207\80", "\234\96\19\98\31\43\110");
obf_cached_str[79] = LUAOBFUSACTOR_DECRYPT_STR_0("\140\22\1\191\118\171\167\53\161\23\58\179\64\191", "\80\196\121\108\218\37\200\213");
obf_cached_str[78] = LUAOBFUSACTOR_DECRYPT_STR_0("\131\62\78\225\22\82", "\98\236\92\36\130\51");
obf_cached_str[75] = LUAOBFUSACTOR_DECRYPT_STR_0("\30\59\1\88\138\128\199\29\27\45\66", "\162\75\114\72\53\235\231");
obf_cached_str[74] = LUAOBFUSACTOR_DECRYPT_STR_0("\217\131\245\74\154\134", "\191\182\225\159\41");
obf_cached_str[71] = LUAOBFUSACTOR_DECRYPT_STR_0("\198\198\113\219\36\81\246", "\54\147\143\56\182\69");
obf_cached_str[70] = LUAOBFUSACTOR_DECRYPT_STR_0("\87\21\45\69\29\71", "\38\56\119\71");
obf_cached_str[67] = LUAOBFUSACTOR_DECRYPT_STR_0("\110\117\89\11\0\69\104\81\11\61\112\115\81\25", "\83\38\26\52\110");
obf_cached_str[66] = LUAOBFUSACTOR_DECRYPT_STR_0("\244\172\184\43\190\254", "\72\155\206\210");
obf_cached_str[64] = LUAOBFUSACTOR_DECRYPT_STR_0("\134\122\233\127\22\50\71", "\161\211\51\170\16\122\93\53");
obf_cached_str[63] = LUAOBFUSACTOR_DECRYPT_STR_0("\55\4\7\238\125\86", "\141\88\102\109");
obf_cached_str[62] = LUAOBFUSACTOR_DECRYPT_STR_0("\54\39\3\203\242\38\41\21\206\241\23\41\12\207\231", "\149\84\70\96\160");
obf_cached_str[60] = LUAOBFUSACTOR_DECRYPT_STR_0("\223\173\10\25\202\211\183", "\163\182\192\109\79");
obf_cached_str[59] = LUAOBFUSACTOR_DECRYPT_STR_0("\87\206\242\211\37\197\73", "\160\62\163\149\133\76");
obf_cached_str[58] = LUAOBFUSACTOR_DECRYPT_STR_0("\176\1\132\23\11\48\187", "\204\217\108\227\65\98\85");
obf_cached_str[54] = LUAOBFUSACTOR_DECRYPT_STR_0("\17\0\189\83", "\201\98\105\199\54\221\132\119");
obf_cached_str[53] = LUAOBFUSACTOR_DECRYPT_STR_0("\13\169\56\113\227\251\74\246", "\136\111\198\77\31\135");
obf_cached_str[51] = LUAOBFUSACTOR_DECRYPT_STR_0("\224\120\236\9", "\42\147\17\150\108\112");
obf_cached_str[50] = LUAOBFUSACTOR_DECRYPT_STR_0("\25\226\147\95\233\46\124\75", "\89\123\141\230\49\141\93");
obf_cached_str[48] = LUAOBFUSACTOR_DECRYPT_STR_0("\198\113\191\6\150\205\108\183\6\139\216\119\183\20\192\158", "\229\174\30\210\99");
obf_cached_str[47] = LUAOBFUSACTOR_DECRYPT_STR_0("\130\83\89\35\129", "\78\228\33\56");
obf_cached_str[46] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\193\74\229\66\220", "\224\77\174\63\139\38\175");
obf_cached_str[44] = LUAOBFUSACTOR_DECRYPT_STR_0("\238\248\29\95\61\82\222\223", "\55\187\177\78\60\79");
obf_cached_str[43] = LUAOBFUSACTOR_DECRYPT_STR_0("\139\195\10\186\122\97", "\168\228\161\96\217\95\81");
obf_cached_str[42] = LUAOBFUSACTOR_DECRYPT_STR_0("\207\232\8\245\30\222\162\77", "\122\173\135\125\155");
obf_cached_str[40] = LUAOBFUSACTOR_DECRYPT_STR_0("\25\14\223\177\203\211\175\52\4\220\130\241\213\170", "\221\81\97\178\212\152\176");
obf_cached_str[39] = LUAOBFUSACTOR_DECRYPT_STR_0("\29\34\50\127\249\36", "\20\114\64\88\28\220");
obf_cached_str[37] = LUAOBFUSACTOR_DECRYPT_STR_0("\206\0\4\242\11\126", "\217\161\114\109\149\98\16");
obf_cached_str[36] = LUAOBFUSACTOR_DECRYPT_STR_0("\79\115\112\8\54\251", "\45\61\22\19\124\19\203");
obf_cached_str[35] = LUAOBFUSACTOR_DECRYPT_STR_0("\16\117\96\243\250\39", "\153\83\50\50\150");
obf_cached_str[33] = LUAOBFUSACTOR_DECRYPT_STR_0("\184\242\10\0\211", "\227\222\148\99\37");
obf_cached_str[32] = LUAOBFUSACTOR_DECRYPT_STR_0("\214\206\16\208\24\166", "\200\164\171\115\164\61\150");
obf_cached_str[31] = LUAOBFUSACTOR_DECRYPT_STR_0("\5\244\49\32\126", "\22\114\157\85\84");
obf_cached_str[30] = LUAOBFUSACTOR_DECRYPT_STR_0("\231\164\172\209", "\57\148\205\214\180\200\54");
obf_cached_str[29] = LUAOBFUSACTOR_DECRYPT_STR_0("\164\176\229\196\243\229", "\176\214\213\134");
obf_cached_str[27] = LUAOBFUSACTOR_DECRYPT_STR_0("\181\159\161\213\179\131", "\178\218\237\200");
obf_cached_str[26] = LUAOBFUSACTOR_DECRYPT_STR_0("\171\38\168\96\250\239", "\212\217\67\203\20\223\223\37");
obf_cached_str[25] = LUAOBFUSACTOR_DECRYPT_STR_0("\92\21\52\110\11\64", "\26\46\112\87");
obf_cached_str[24] = LUAOBFUSACTOR_DECRYPT_STR_0("\76\79\199\114\56\80", "\80\36\42\174\21");
obf_cached_str[23] = LUAOBFUSACTOR_DECRYPT_STR_0("\241\43\253\89", "\166\130\66\135\60\27\17");
obf_cached_str[22] = LUAOBFUSACTOR_DECRYPT_STR_0("\1\208\129\239\175\151", "\167\115\181\226\155\138");
obf_cached_str[20] = LUAOBFUSACTOR_DECRYPT_STR_0("\57\141\113\185\34\129\110\185\52\140\106\181\52\149\57\236", "\220\81\226\28");
obf_cached_str[19] = LUAOBFUSACTOR_DECRYPT_STR_0("\104\10\208\131\39\222\72\38\207\189\44\221\78", "\184\60\101\160\207\66");
obf_cached_str[18] = LUAOBFUSACTOR_DECRYPT_STR_0("\227\143\31\243\9\226\89\193\132", "\56\162\225\118\158\89\142");
obf_cached_str[17] = LUAOBFUSACTOR_DECRYPT_STR_0("\61\187\134\247\201\54\166\142\247\212\35\189\142\229\159\101", "\186\85\212\235\146");
obf_cached_str[16] = LUAOBFUSACTOR_DECRYPT_STR_0("\245\194\25\208\93\180\239\200\17\219\88\190\248\218\81\133", "\215\157\173\116\181\46");
obf_cached_str[15] = LUAOBFUSACTOR_DECRYPT_STR_0("\11\22\207\248\59\40", "\145\94\95\153");
obf_cached_str[14] = LUAOBFUSACTOR_DECRYPT_STR_0("\192\2\84\251\232\225\144\43\237\3\111\247\222\245", "\78\136\109\57\158\187\130\226");
obf_cached_str[12] = LUAOBFUSACTOR_DECRYPT_STR_0("\206\64\56\213\64\145", "\101\161\34\82\182");
obf_cached_str[11] = LUAOBFUSACTOR_DECRYPT_STR_0("\135\187\39", "\233\229\210\83\107\40\46");
obf_cached_str[10] = LUAOBFUSACTOR_DECRYPT_STR_0("\243\205\35\239\230\34\249", "\34\129\168\82\154\143\80\156");
obf_cached_str[9] = LUAOBFUSACTOR_DECRYPT_STR_0("\181\236\109\176\185", "\171\215\133\25\149\137");
obf_cached_str[8] = LUAOBFUSACTOR_DECRYPT_STR_0("\35\215\83", "\211\69\177\58\58");
obf_cached_str[7] = LUAOBFUSACTOR_DECRYPT_STR_0("\56\43\196\78\35\60\208", "\59\74\78\181");
obf_cached_str[6] = LUAOBFUSACTOR_DECRYPT_STR_0("\138\251\69\119\66", "\26\236\157\44\82\114\44");
obf_cached_str[5] = LUAOBFUSACTOR_DECRYPT_STR_0("\212\252\46\215\208\225\61\194\255\250\63\193", "\178\151\147\92");
obf_cached_str[3] = LUAOBFUSACTOR_DECRYPT_STR_0("\143\165\205\248\18\175", "\159\224\199\167\155\55");
obf_cached_str[2] = LUAOBFUSACTOR_DECRYPT_STR_0("\251\115\255\174\107\62\149\247", "\231\148\17\149\205\69\77");
obf_cached_str[1] = LUAOBFUSACTOR_DECRYPT_STR_0("\217\114\53\65\244\33\205", "\168\171\23\68\52\157\83");
obf_cached_str[0] = LUAOBFUSACTOR_DECRYPT_STR_0("\232\0\240\202\162\82", "\169\135\98\154");
TABLE_TableIndirection[obf_cached_str[0]] = _G[obf_cached_str[1]](obf_cached_str[2]);
TABLE_TableIndirection[obf_cached_str[3]].load(obf_cached_str[5]);
TABLE_TableIndirection[obf_cached_str[6]] = _G[obf_cached_str[7]](obf_cached_str[8]);
TABLE_TableIndirection[obf_cached_str[9]] = _G[obf_cached_str[10]](obf_cached_str[11]);
TABLE_TableIndirection[obf_cached_str[12]].class(obf_cached_str[14], obf_cached_str[15]);
TABLE_TableIndirection[obf_cached_str[16]] = {};
TABLE_TableIndirection[obf_cached_str[17]][obf_cached_str[18]] = {[obf_cached_str[19]]=(obf_AND(0, 0) + obf_OR(0, 0))};
TABLE_TableIndirection[obf_cached_str[20]].CGRectMake = function(x, y, width, height)
	local FlatIdent_77C29 = 0 - 0;
	while true do
		if ((FlatIdent_77C29 == (7 - 5)) or ((11705 - 8141) <= (4613 - 2526))) then
			TABLE_TableIndirection[obf_cached_str[22]][obf_cached_str[23]][obf_cached_str[24]] = height;
			return TABLE_TableIndirection[obf_cached_str[25]];
		end
		if (((4381 - 1423) < (obf_AND(4147, 356) + obf_OR(4147, 356))) and (FlatIdent_77C29 == (4 - 3))) then
			TABLE_TableIndirection[obf_cached_str[26]][obf_cached_str[27]]['y'] = y;
			TABLE_TableIndirection[obf_cached_str[29]][obf_cached_str[30]][obf_cached_str[31]] = width;
			FlatIdent_77C29 = obf_AND(2, 0) + obf_OR(2, 0);
		end
		if ((FlatIdent_77C29 == (0 - 0)) or ((4148 - (obf_AND(447, 966) + obf_OR(447, 966))) == (3583 - 2274))) then
			TABLE_TableIndirection[obf_cached_str[32]] = TABLE_TableIndirection[obf_cached_str[33]].new(obf_cached_str[35]);
			TABLE_TableIndirection[obf_cached_str[36]][obf_cached_str[37]]['x'] = x;
			FlatIdent_77C29 = 1818 - (obf_AND(1703, 114) + obf_OR(1703, 114));
		end
	end
end;
TABLE_TableIndirection[obf_cached_str[39]][obf_cached_str[40]].setImgView = function(self, imgView)
	local FlatIdent_8CEDF = 701 - (obf_AND(376, 325) + obf_OR(376, 325));
	while true do
		if ((FlatIdent_8CEDF == (1 - 0)) or ((12707 - 8577) <= (obf_AND(845, 2110) + obf_OR(845, 2110)))) then
			TABLE_TableIndirection[obf_cached_str[42]] = TABLE_TableIndirection[obf_cached_str[43]][obf_cached_str[44]]:mainScreen()[obf_cached_str[46]];
			imgView[obf_cached_str[47]] = TABLE_TableIndirection[obf_cached_str[48]].CGRectMake(0 - 0, 14 - (obf_AND(9, 5) + obf_OR(9, 5)), TABLE_TableIndirection[obf_cached_str[50]][obf_cached_str[51]].width, TABLE_TableIndirection[obf_cached_str[53]][obf_cached_str[54]].height);
			FlatIdent_8CEDF = 378 - (obf_AND(85, 291) + obf_OR(85, 291));
		end
		if ((FlatIdent_8CEDF == (1267 - (obf_AND(243, 1022) + obf_OR(243, 1022)))) or ((7473 - 5509) <= (obf_AND(1106, 234) + obf_OR(1106, 234)))) then
			self:addSubview(imgView);
			self:sendSubviewToBack(imgView);
			FlatIdent_8CEDF = 1183 - (obf_AND(1123, 57) + obf_OR(1123, 57));
		end
		if (((obf_AND(2034, 465) + obf_OR(2034, 465)) == (2753 - (obf_AND(163, 91) + obf_OR(163, 91)))) and (FlatIdent_8CEDF == (1933 - (obf_AND(1869, 61) + obf_OR(1869, 61))))) then
			self[obf_cached_str[58]] = imgView;
			break;
		end
		if ((FlatIdent_8CEDF == (obf_AND(0, 0) + obf_OR(0, 0))) or ((7941 - 5686) < (33 - 11))) then
			if (self[obf_cached_str[59]] or ((obf_AND(149, 937) + obf_OR(149, 937)) >= (1930 - 525))) then
				self[obf_cached_str[60]]:removeFromSuperview();
			end
			imgView[obf_cached_str[62]] = TABLE_TableIndirection[obf_cached_str[63]][obf_cached_str[64]]:clearColor();
			FlatIdent_8CEDF = obf_AND(1, 0) + obf_OR(1, 0);
		end
	end
end;
TABLE_TableIndirection[obf_cached_str[66]][obf_cached_str[67]].setBackgroundWithImage = function(self, img)
	if (img:isKindOfClass(TABLE_TableIndirection[obf_cached_str[70]][obf_cached_str[71]]:class()) or ((3843 - (obf_AND(1329, 145) + obf_OR(1329, 145))) == (1397 - (obf_AND(140, 831) + obf_OR(140, 831))))) then
		self:setImgView(TABLE_TableIndirection[obf_cached_str[74]][obf_cached_str[75]]:alloc():initWithImage(img));
	end
end;
TABLE_TableIndirection[obf_cached_str[78]][obf_cached_str[79]].setCloudView = function(self, cloudView)
	local FlatIdent_29B3D = 1850 - (obf_AND(1409, 441) + obf_OR(1409, 441));
	while true do
		if ((FlatIdent_29B3D == (719 - (obf_AND(15, 703) + obf_OR(15, 703)))) or ((obf_AND(1425, 1651) + obf_OR(1425, 1651)) > (3621 - (obf_AND(262, 176) + obf_OR(262, 176))))) then
			self:addSubview(cloudView);
			self:bringSubviewToFront(cloudView);
			FlatIdent_29B3D = 1723 - (obf_AND(345, 1376) + obf_OR(345, 1376));
		end
		if (((1890 - (obf_AND(198, 490) + obf_OR(198, 490))) > (4674 - 3616)) and (FlatIdent_29B3D == (0 - 0))) then
			TABLE_TableIndirection[obf_cached_str[83]] = TABLE_TableIndirection[obf_cached_str[84]][obf_cached_str[85]]:mainScreen()[obf_cached_str[87]];
			cloudView[obf_cached_str[88]] = TABLE_TableIndirection[obf_cached_str[89]].CGRectMake(1206 - (obf_AND(696, 510) + obf_OR(696, 510)), 0 - 0, TABLE_TableIndirection[obf_cached_str[91]][obf_cached_str[92]].width, TABLE_TableIndirection[obf_cached_str[94]][obf_cached_str[95]].height);
			FlatIdent_29B3D = 1263 - (obf_AND(1091, 171) + obf_OR(1091, 171));
		end
		if (((obf_AND(598, 3113) + obf_OR(598, 3113)) > (10562 - 7207)) and (FlatIdent_29B3D == (6 - 4))) then
			self[obf_cached_str[97]] = cloudView;
			break;
		end
	end
end;
TABLE_TableIndirection[obf_cached_str[98]][obf_cached_str[99]].setAnimationWithGif = function(self, animImg, whereto)
	local FlatIdent_981A3 = 374 - (obf_AND(123, 251) + obf_OR(123, 251));
	while true do
		if ((FlatIdent_981A3 == (4 - 3)) or ((1604 - (obf_AND(208, 490) + obf_OR(208, 490))) >= (obf_AND(189, 2040) + obf_OR(189, 2040)))) then
			self:addSubview(TABLE_TableIndirection["imageView%0"]);
			self:bringSubviewToFront(TABLE_TableIndirection["imageView%0"]);
			break;
		end
		if (((obf_AND(574, 714) + obf_OR(574, 714)) > (2087 - (obf_AND(660, 176) + obf_OR(660, 176)))) and (FlatIdent_981A3 == (obf_AND(0, 0) + obf_OR(0, 0)))) then
			TABLE_TableIndirection[obf_cached_str[105]] = TABLE_TableIndirection[obf_cached_str[106]][obf_cached_str[107]]:alloc():init();
			TABLE_TableIndirection[obf_cached_str[110]][obf_cached_str[111]] = animImg;
			FlatIdent_981A3 = 203 - (obf_AND(14, 188) + obf_OR(14, 188));
		end
	end
end;
TABLE_TableIndirection[obf_cached_str[112]][obf_cached_str[113]].placeClouds = function(self, weatherID)
	local FlatIdent_52551 = 675 - (obf_AND(534, 141) + obf_OR(534, 141));
	while true do
		if ((FlatIdent_52551 == (obf_AND(1, 0) + obf_OR(1, 0))) or ((obf_AND(3992, 521) + obf_OR(3992, 521)) < (obf_AND(3223, 129) + obf_OR(3223, 129)))) then
			print(obf_cached_str[115] .. tostring(weatherID));
			TABLE_TableIndirection[obf_cached_str[116]] = TABLE_TableIndirection[obf_cached_str[117]][obf_cached_str[118]]:imageWithContentsOfFile(root .. "/Library/Application Support/WeatherWhirl/cloud.png");
			FlatIdent_52551 = 3 - 1;
		end
		if ((FlatIdent_52551 == (0 - 0)) or ((5792 - 3727) >= (obf_AND(1717, 1479) + obf_OR(1717, 1479)))) then
			TABLE_TableIndirection[obf_cached_str[121]] = TABLE_TableIndirection[obf_cached_str[122]][obf_cached_str[123]]:new();
			if (not self[obf_cached_str[125]] or ((obf_AND(2787, 1589) + obf_OR(2787, 1589)) <= (1877 - (obf_AND(115, 281) + obf_OR(115, 281))))) then
				return;
			end
			FlatIdent_52551 = 2 - 1;
		end
		if ((FlatIdent_52551 == (obf_AND(2, 0) + obf_OR(2, 0))) or ((8197 - 4805) >= (17384 - 12643))) then
			TABLE_TableIndirection[obf_cached_str[126]] = TABLE_TableIndirection[obf_cached_str[127]][obf_cached_str[128]]:imageWithContentsOfFile(root .. "/Library/Application Support/WeatherWhirl/sephiroth.png");
			if (((4192 - (obf_AND(550, 317) + obf_OR(550, 317))) >= (3111 - 957)) and (weatherID == (1125 - 324))) then
				self[obf_cached_str[131]]:placeClouds(CloudTypes.FewClouds, TABLE_TableIndirection["cloud%0"], RainTypes.None);
			elseif ((weatherID == (2241 - 1439)) or ((1580 - (obf_AND(134, 151) + obf_OR(134, 151))) >= (4898 - (obf_AND(970, 695) + obf_OR(970, 695))))) then
				self[obf_cached_str[136]]:placeClouds(CloudTypes.ScatterClouds, TABLE_TableIndirection["cloud%0"], RainTypes.None);
			elseif (((8351 - 3974) > (3632 - (obf_AND(582, 1408) + obf_OR(582, 1408)))) and (weatherID == (2784 - 1981))) then
				self[obf_cached_str[141]]:placeClouds(CloudTypes.BrokeClouds, TABLE_TableIndirection["cloud%0"], RainTypes.None);
			elseif (((5942 - 1219) > (5109 - 3753)) and (weatherID == (2628 - (obf_AND(1195, 629) + obf_OR(1195, 629))))) then
				self[obf_cached_str[146]]:placeClouds(CloudTypes.OverClouds, TABLE_TableIndirection["cloud%0"], RainTypes.None);
			end
			FlatIdent_52551 = 3 - 0;
		end
		if ((FlatIdent_52551 == (244 - (obf_AND(187, 54) + obf_OR(187, 54)))) or ((4916 - (obf_AND(162, 618) + obf_OR(162, 618))) <= (obf_AND(2406, 1027) + obf_OR(2406, 1027)))) then
			if (((obf_AND(2828, 1417) + obf_OR(2828, 1417)) <= (9876 - 5245)) and (weatherID == (840 - 340))) then
				self[obf_cached_str[151]]:placeClouds(CloudTypes.FewClouds, TABLE_TableIndirection["sephiroth%0"], RainTypes.Light);
			elseif (((obf_AND(335, 3941) + obf_OR(335, 3941)) >= (5550 - (obf_AND(1373, 263) + obf_OR(1373, 263)))) and (weatherID == (1501 - (obf_AND(451, 549) + obf_OR(451, 549))))) then
				self[obf_cached_str[156]]:placeClouds(CloudTypes.ScatterClouds, TABLE_TableIndirection["sephiroth%0"], RainTypes.Moderate);
			elseif (((obf_AND(63, 135) + obf_OR(63, 135)) <= (6793 - 2428)) and (weatherID == (843 - 341))) then
				self[obf_cached_str[161]]:placeClouds(CloudTypes.BrokeClouds, TABLE_TableIndirection["sephiroth%0"], RainTypes.Heavy);
			end
			TABLE_TableIndirection[obf_cached_str[166]]:drain();
			break;
		end
	end
end;
return TABLE_TableIndirection[obf_cached_str[168]];

