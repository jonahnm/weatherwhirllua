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
obf_cached_str[224] = LUAOBFUSACTOR_DECRYPT_STR_0("\229\8\46\44\72\14\119\225\50\40\60\91\66\42", "\26\134\100\65\89\44\103");
obf_cached_str[223] = LUAOBFUSACTOR_DECRYPT_STR_0("\37\174\233\63", "\90\77\219\142");
obf_cached_str[222] = LUAOBFUSACTOR_DECRYPT_STR_0("\24\247\228\17", "\38\117\150\144\121\107");
obf_cached_str[221] = LUAOBFUSACTOR_DECRYPT_STR_0("\140\254\140\226\60\153\249\138\225\15\136\224\128\238\41\174\255\144\225\41", "\93\237\144\229\143");
obf_cached_str[220] = LUAOBFUSACTOR_DECRYPT_STR_0("\82\5\125\126\19\94\10\115\118\12\90\14\99\54\106", "\90\51\107\20\19");
obf_cached_str[219] = LUAOBFUSACTOR_DECRYPT_STR_0("\194\53\228\31\249\34\202\52\227\54\237\36\194\47\228\29\246", "\86\163\91\141\114\152");
obf_cached_str[218] = LUAOBFUSACTOR_DECRYPT_STR_0("\4\135\25\25\253\66\94\2\140\38\29\209\88\26\85", "\63\101\233\112\116\180\47");
obf_cached_str[217] = LUAOBFUSACTOR_DECRYPT_STR_0("\39\170\175\5\230", "\177\111\207\206\115\159\136\140");
obf_cached_str[216] = LUAOBFUSACTOR_DECRYPT_STR_0("\16\222\204\168\211\149\7\116\49", "\17\66\191\165\198\135\236\119");
obf_cached_str[215] = LUAOBFUSACTOR_DECRYPT_STR_0("\137\175\224\207\117\156\168\230\204\80\157\179\232\214\125\135\175", "\20\232\193\137\162");
obf_cached_str[214] = LUAOBFUSACTOR_DECRYPT_STR_0("\123\178\59\121\175\56\122\140\127\138\59\113\145\112\43", "\235\26\220\82\20\230\85\27");
obf_cached_str[213] = LUAOBFUSACTOR_DECRYPT_STR_0("\211\172\205\114\70\255\183\204", "\52\158\195\169\23");
obf_cached_str[212] = LUAOBFUSACTOR_DECRYPT_STR_0("\135\62\238\40\96\153\18\176\44", "\98\213\95\135\70\52\224");
obf_cached_str[211] = LUAOBFUSACTOR_DECRYPT_STR_0("\195\215\69\48\195\204\72\50\146\136", "\95\183\184\39");
obf_cached_str[209] = LUAOBFUSACTOR_DECRYPT_STR_0("\235\38\36\45", "\36\152\79\94\72\181\37\98");
obf_cached_str[208] = LUAOBFUSACTOR_DECRYPT_STR_0("\187\188\178\17\140\224", "\144\217\211\199\127\232\147");
obf_cached_str[207] = LUAOBFUSACTOR_DECRYPT_STR_0("\3\133\230\171\4\128\228\185\54\128\236\169\69\217", "\222\96\233\137");
obf_cached_str[205] = LUAOBFUSACTOR_DECRYPT_STR_0("\239\17\43\238\246\202", "\164\128\99\66\137\159");
obf_cached_str[204] = LUAOBFUSACTOR_DECRYPT_STR_0("\183\160\15\32\242", "\192\209\210\110\77\151\186");
obf_cached_str[203] = LUAOBFUSACTOR_DECRYPT_STR_0("\250\51\23\241\253\54\21\227\207\54\29\243\188\111", "\132\153\95\120");
obf_cached_str[201] = LUAOBFUSACTOR_DECRYPT_STR_0("\213\205\170\128\218\212", "\179\186\191\195\231");
obf_cached_str[200] = LUAOBFUSACTOR_DECRYPT_STR_0("\190\207\119\15\183", "\70\216\189\22\98\210\52\24");
obf_cached_str[199] = LUAOBFUSACTOR_DECRYPT_STR_0("\186\194\223\42\75\176\195\215\9\70\188\217\149\111", "\47\217\174\176\95");
obf_cached_str[198] = LUAOBFUSACTOR_DECRYPT_STR_0("\14\203\25\223\11\200\175\44\231\46\159\88", "\226\77\140\75\186\104\188");
obf_cached_str[195] = LUAOBFUSACTOR_DECRYPT_STR_0("\221\4\128\66\115\187\196\142\225\40\190", "\216\136\77\201\47\18\220\161");
obf_cached_str[194] = LUAOBFUSACTOR_DECRYPT_STR_0("\125\234\206\160\78\19", "\25\18\136\164\195\107\35");
obf_cached_str[193] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\69\55\216\120\28\253\41\78\8\220\84\6\185\126", "\156\78\43\94\181\49\113");
obf_cached_str[191] = LUAOBFUSACTOR_DECRYPT_STR_0("\172\180\198\205\52\41", "\203\195\198\175\170\93\71\237");
obf_cached_str[190] = LUAOBFUSACTOR_DECRYPT_STR_0("\14\46\27\77\1", "\157\104\92\122\32\100\109");
obf_cached_str[189] = LUAOBFUSACTOR_DECRYPT_STR_0("\213\121\38\182\227\133\161\17\224\124\44\180\162\220", "\118\182\21\73\195\135\236\204");
obf_cached_str[188] = LUAOBFUSACTOR_DECRYPT_STR_0("\168\70\12\233\168\87", "\142\192\35\101");
obf_cached_str[187] = LUAOBFUSACTOR_DECRYPT_STR_0("\75\204\77\255", "\151\56\165\55\154\35\83");
obf_cached_str[186] = LUAOBFUSACTOR_DECRYPT_STR_0("\230\184\241\132\74\205", "\185\142\221\152\227\34");
obf_cached_str[185] = LUAOBFUSACTOR_DECRYPT_STR_0("\174\238\62\163", "\60\221\135\68\198\167");
obf_cached_str[184] = LUAOBFUSACTOR_DECRYPT_STR_0("\208\148\100\51\221\49\224\179\117\63\218\58\225\174\18\96", "\84\133\221\55\80\175");
obf_cached_str[183] = LUAOBFUSACTOR_DECRYPT_STR_0("\152\215\20\214\172\68\131\213\83\137", "\48\236\184\118\185\216");
obf_cached_str[182] = LUAOBFUSACTOR_DECRYPT_STR_0("\253\89\244\88\82\110\245\88\243\113\70\104\253\67\244\90\93", "\26\156\55\157\53\51");
obf_cached_str[181] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\141\25\75\0\215\47\132\21\112\32\223\57\198\64", "\186\78\227\112\38\73");
obf_cached_str[180] = LUAOBFUSACTOR_DECRYPT_STR_0("\32\161\55\43\108\252", "\88\73\204\80");
obf_cached_str[178] = LUAOBFUSACTOR_DECRYPT_STR_0("\51\223\201\16\112\108", "\85\92\189\163\115");
obf_cached_str[177] = LUAOBFUSACTOR_DECRYPT_STR_0("\95\207\162\43\206\74\200\164\40\230\83\192\172\35\220", "\175\62\161\203\70");
obf_cached_str[176] = LUAOBFUSACTOR_DECRYPT_STR_0("\45\119\237\85\5\116\229\95\41\79\237\93\59\60\180", "\56\76\25\132");
obf_cached_str[173] = LUAOBFUSACTOR_DECRYPT_STR_0("\41\36\174\86\114\35\37\166\117\127\47\63\228\19", "\22\74\72\193\35");
obf_cached_str[171] = LUAOBFUSACTOR_DECRYPT_STR_0("\235\187\45\238\105\50\235\178\33\213\73\58\253\240\116", "\95\138\213\68\131\32");
obf_cached_str[170] = LUAOBFUSACTOR_DECRYPT_STR_0("\67\85\143\241\15\8", "\130\42\56\232");
obf_cached_str[167] = LUAOBFUSACTOR_DECRYPT_STR_0("\166\136\222\42\51\160\5\187\128\222\58\121\253", "\85\212\233\176\78\92\205");
obf_cached_str[164] = LUAOBFUSACTOR_DECRYPT_STR_0("\177\126\215\87\133\80\251\108\141\82\233", "\58\228\55\158");
obf_cached_str[163] = LUAOBFUSACTOR_DECRYPT_STR_0("\30\164\167\173\115\67", "\115\113\198\205\206\86");
obf_cached_str[162] = LUAOBFUSACTOR_DECRYPT_STR_0("\249\64\237\233\115\243\65\229\202\126\255\91\167\172", "\23\154\44\130\156");
obf_cached_str[158] = LUAOBFUSACTOR_DECRYPT_STR_0("\190\35\73\73", "\214\205\74\51\44");
obf_cached_str[156] = LUAOBFUSACTOR_DECRYPT_STR_0("\169\143\99\246", "\68\218\230\25\147\63\174");
obf_cached_str[154] = LUAOBFUSACTOR_DECRYPT_STR_0("\62\81\82\188\204\166\18\35\89\82\172\134\251", "\66\76\48\60\216\163\203");
obf_cached_str[152] = LUAOBFUSACTOR_DECRYPT_STR_0("\82\169\169\231\31\77\152\168\234\30\84\237\247", "\112\32\200\199\131");
obf_cached_str[151] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\1\55\23\10\52\208\39\14\23\76\112", "\64\157\70\101\114\105");
obf_cached_str[150] = LUAOBFUSACTOR_DECRYPT_STR_0("\64\17\232\33\86", "\118\38\99\137\76\51");
obf_cached_str[149] = LUAOBFUSACTOR_DECRYPT_STR_0("\160\191\237\212\194\10\125\127\149\186\231\214\131\83", "\24\195\211\130\161\166\99\16");
obf_cached_str[148] = LUAOBFUSACTOR_DECRYPT_STR_0("\249\192\160\244\199\249\192\181\194\194\228\208\181\242\139\187", "\174\139\165\209\129");
obf_cached_str[147] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\6\240\9\62\8\225\9\28\12\244\15\41\7\242\73\124", "\108\76\105\134");
obf_cached_str[146] = LUAOBFUSACTOR_DECRYPT_STR_0("\228\243\10\210\234\210\236\187\93", "\183\141\158\109\147\152");
obf_cached_str[145] = LUAOBFUSACTOR_DECRYPT_STR_0("\188\200\211\203\170\197\224\220\170\202\132\158", "\174\207\171\161");
obf_cached_str[143] = LUAOBFUSACTOR_DECRYPT_STR_0("\187\13\207\148\54\187\13\218\162\51\166\29\218\146\122\249", "\95\201\104\190\225");
obf_cached_str[142] = LUAOBFUSACTOR_DECRYPT_STR_0("\1\168\52\116\1\185", "\19\105\205\93");
obf_cached_str[141] = LUAOBFUSACTOR_DECRYPT_STR_0("\78\188\184\130", "\231\61\213\194");
obf_cached_str[140] = LUAOBFUSACTOR_DECRYPT_STR_0("\28\142\160\80\3", "\36\107\231\196");
obf_cached_str[139] = LUAOBFUSACTOR_DECRYPT_STR_0("\27\80\19\90", "\63\104\57\105");
obf_cached_str[138] = LUAOBFUSACTOR_DECRYPT_STR_0("\60\128\124\126\192\170\181\157\101", "\184\85\237\27\63\178\207\212");
obf_cached_str[137] = LUAOBFUSACTOR_DECRYPT_STR_0("\145\201\126\176\246\5\161\238\126\176\229\12\161\165\29", "\96\196\128\45\211\132");
obf_cached_str[136] = LUAOBFUSACTOR_DECRYPT_STR_0("\241\17\207\251\132\181", "\85\153\116\166\156\236\193\144");
obf_cached_str[135] = LUAOBFUSACTOR_DECRYPT_STR_0("\62\61\191\217", "\230\77\84\197\188\22\207\183");
obf_cached_str[134] = LUAOBFUSACTOR_DECRYPT_STR_0("\144\163\54\205\107\115\160\132\39\193\108\120\161\153\64\158", "\22\197\234\101\174\25");
obf_cached_str[133] = LUAOBFUSACTOR_DECRYPT_STR_0("\25\248\245\25\224\196\232\68\31\210\199\22\247\132\189", "\42\76\177\166\122\146\161\141");
obf_cached_str[132] = LUAOBFUSACTOR_DECRYPT_STR_0("\160\94\193\9\41", "\222\215\55\165\125\65");
obf_cached_str[131] = LUAOBFUSACTOR_DECRYPT_STR_0("\102\184\65\79", "\182\21\209\59\42");
obf_cached_str[130] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\107\16\160\45\76\224\0\56\77\54\173\59\90\160\94", "\110\122\34\67\195\95\41\133");
obf_cached_str[129] = LUAOBFUSACTOR_DECRYPT_STR_0("\23\236\182\198\52\84\37\253\161\194\116\10", "\58\100\143\196\163\81");
obf_cached_str[128] = LUAOBFUSACTOR_DECRYPT_STR_0("\47\70\221\184\255", "\109\92\37\188\212\154\29");
obf_cached_str[126] = LUAOBFUSACTOR_DECRYPT_STR_0("\235\141\104\79\86\217\77\208", "\40\190\196\59\44\36\188");
obf_cached_str[125] = LUAOBFUSACTOR_DECRYPT_STR_0("\50\214\176\222\50\30", "\50\93\180\218\189\23\46\71");
obf_cached_str[124] = LUAOBFUSACTOR_DECRYPT_STR_0("\190\173\6\184\252\142\120\133\183\54\186\226\142\56\219", "\29\235\228\85\219\142\235");
obf_cached_str[122] = LUAOBFUSACTOR_DECRYPT_STR_0("\115\192\159\140\173\23\119\202\185\140\173\21\117\193\157\204\239", "\118\16\175\233\233\223");
obf_cached_str[121] = LUAOBFUSACTOR_DECRYPT_STR_0("\222\252\41\164\6\253\229\57\178\54", "\69\145\138\76\214");
obf_cached_str[120] = LUAOBFUSACTOR_DECRYPT_STR_0("\249\133\80\23\8\217\195\153\90\17", "\141\186\233\63\98\108");
obf_cached_str[118] = LUAOBFUSACTOR_DECRYPT_STR_0("\245\249\111\4\148\221\241\243\73\4\148\223\243\248\109\68\214", "\188\150\150\25\97\230");
obf_cached_str[117] = LUAOBFUSACTOR_DECRYPT_STR_0("\228\42\182\61\188\33\202\55\172\50\170", "\98\166\88\217\86\217");
obf_cached_str[116] = LUAOBFUSACTOR_DECRYPT_STR_0("\232\120\202\34\86\23\0\219\113\214", "\121\171\20\165\87\50\67");
obf_cached_str[114] = LUAOBFUSACTOR_DECRYPT_STR_0("\197\214\149\219\60\235\193\220\179\219\60\233\195\215\151\155\126", "\138\166\185\227\190\78");
obf_cached_str[113] = LUAOBFUSACTOR_DECRYPT_STR_0("\247\44\32\48\27\193\61\2\40\0\209\43\50", "\111\164\79\65\68");
obf_cached_str[112] = LUAOBFUSACTOR_DECRYPT_STR_0("\119\120\9\38\74\96\97\68\113\21", "\24\52\20\102\83\46\52");
obf_cached_str[110] = LUAOBFUSACTOR_DECRYPT_STR_0("\228\53\253\117\245\59\236\117\215\63\249\115\226\52\255\53\183", "\16\135\90\139");
obf_cached_str[109] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\169\145\127\31\163\147\88\0", "\60\115\204\230");
obf_cached_str[108] = LUAOBFUSACTOR_DECRYPT_STR_0("\23\188\44\243\48\132\58\246\49\163", "\134\84\208\67");
obf_cached_str[107] = LUAOBFUSACTOR_DECRYPT_STR_0("\129\222\183\136\171\133\133\212\145\136\171\135\135\223\181\200\233", "\228\226\177\193\237\217");
obf_cached_str[106] = LUAOBFUSACTOR_DECRYPT_STR_0("\1\80\214\245\7\76", "\155\99\63\163");
obf_cached_str[104] = LUAOBFUSACTOR_DECRYPT_STR_0("\78\21\140\67\163\222\116\171", "\197\27\92\223\32\209\187\17");
obf_cached_str[103] = LUAOBFUSACTOR_DECRYPT_STR_0("\199\88\4\46\92\136", "\227\168\58\110\77\121\184\207");
obf_cached_str[102] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\174\145\83\18\130\167\94\34\136\183\94\4\148\231\0", "\48\96\231\194");
obf_cached_str[101] = LUAOBFUSACTOR_DECRYPT_STR_0("\13\72\67\111\153", "\169\100\37\36\74");
obf_cached_str[100] = LUAOBFUSACTOR_DECRYPT_STR_0("\236\212\15\32\99\181", "\70\133\185\104\83");
obf_cached_str[98] = LUAOBFUSACTOR_DECRYPT_STR_0("\65\124\179\187\149", "\165\40\17\212\158");
obf_cached_str[97] = LUAOBFUSACTOR_DECRYPT_STR_0("\63\179\185\37\154\56\163\200\124\246", "\160\89\198\213\73\234\89\215");
obf_cached_str[95] = LUAOBFUSACTOR_DECRYPT_STR_0("\32\16\88\77\178\215", "\107\79\114\50\46\151\231");
obf_cached_str[93] = LUAOBFUSACTOR_DECRYPT_STR_0("\12\90\80\76\207\62\118", "\174\89\19\25\33");
obf_cached_str[92] = LUAOBFUSACTOR_DECRYPT_STR_0("\215\68\10\112\238\251", "\203\184\38\96\19\203");
obf_cached_str[91] = LUAOBFUSACTOR_DECRYPT_STR_0("\170\65\134\89\236", "\111\195\44\225\124\220");
obf_cached_str[89] = LUAOBFUSACTOR_DECRYPT_STR_0("\93\90\123\28", "\104\47\53\20");
obf_cached_str[88] = LUAOBFUSACTOR_DECRYPT_STR_0("\219\51\250\79\165\220\50\254\6\229", "\213\189\70\150\35");
obf_cached_str[87] = LUAOBFUSACTOR_DECRYPT_STR_0("\187\240", "\152\149\222\106\123\23");
obf_cached_str[83] = LUAOBFUSACTOR_DECRYPT_STR_0("\163\69\25\37\253\225\247", "\178\230\29\77\119\184\172");
obf_cached_str[82] = LUAOBFUSACTOR_DECRYPT_STR_0("\156\238\180\178\154\246\173\185\189", "\220\206\143\221");
obf_cached_str[81] = LUAOBFUSACTOR_DECRYPT_STR_0("\209\126\90\179", "\156\159\17\52\214\86\190");
obf_cached_str[80] = LUAOBFUSACTOR_DECRYPT_STR_0("\63\48\60\115\57\103\29\52\38", "\30\109\81\85\29\109");
obf_cached_str[79] = LUAOBFUSACTOR_DECRYPT_STR_0("\95\162\59\13\86\179", "\147\54\207\92\126\115\131");
obf_cached_str[77] = LUAOBFUSACTOR_DECRYPT_STR_0("\116\84\11\203\83\110\13\219\64", "\190\55\56\100");
obf_cached_str[76] = LUAOBFUSACTOR_DECRYPT_STR_0("\228\193\234\218\4\187", "\33\139\163\128\185");
obf_cached_str[75] = LUAOBFUSACTOR_DECRYPT_STR_0("\26\162\98\225\31\199\94", "\226\110\205\16\132\107");
obf_cached_str[74] = LUAOBFUSACTOR_DECRYPT_STR_0("\48\25\190\228\37\181\135", "\183\68\118\204\129\81\144");
obf_cached_str[70] = LUAOBFUSACTOR_DECRYPT_STR_0("\93\6\132\78\117", "\203\59\96\237\107\69\111\113");
obf_cached_str[69] = LUAOBFUSACTOR_DECRYPT_STR_0("\34\70\250\4\118\220\115\25", "\174\86\41\147\112\19");
obf_cached_str[68] = LUAOBFUSACTOR_DECRYPT_STR_0("\144\39\175\213\221\65\247\212", "\210\228\72\198\161\184\51");
obf_cached_str[65] = LUAOBFUSACTOR_DECRYPT_STR_0("\208\229\164\219\182\143", "\147\191\135\206\184");
obf_cached_str[64] = LUAOBFUSACTOR_DECRYPT_STR_0("\53\78\89\16\242\78\102\113", "\67\65\33\48\100\151\60");
obf_cached_str[63] = LUAOBFUSACTOR_DECRYPT_STR_0("\198\138\206\38\147\236\4", "\52\178\229\188\67\231\201");
obf_cached_str[61] = LUAOBFUSACTOR_DECRYPT_STR_0("\184\202\81\67", "\45\203\163\43\38\35\42\91");
obf_cached_str[60] = LUAOBFUSACTOR_DECRYPT_STR_0("\12\129\127\27\210\231\11\55\138\67\13\206\230\29\124\248", "\110\89\200\44\120\160\130");
obf_cached_str[57] = LUAOBFUSACTOR_DECRYPT_STR_0("\3\29\40\240", "\194\112\116\82\149\182\206");
obf_cached_str[56] = LUAOBFUSACTOR_DECRYPT_STR_0("\208\48\102\128\13\8\42\80\199\22\64\141\27\30\106\14", "\62\133\121\53\227\127\109\79");
obf_cached_str[54] = LUAOBFUSACTOR_DECRYPT_STR_0("\150\65\77\90\164\140\14", "\62\226\46\63\63\208\169");
obf_cached_str[53] = LUAOBFUSACTOR_DECRYPT_STR_0("\186\122\247\251\137\171", "\237\216\21\130\149");
obf_cached_str[51] = LUAOBFUSACTOR_DECRYPT_STR_0("\198\42\26\19\144\93\29\120", "\22\147\99\73\112\226\56\120");
obf_cached_str[50] = LUAOBFUSACTOR_DECRYPT_STR_0("\115\245\35\53\118\244", "\196\28\151\73\86\83");
obf_cached_str[49] = LUAOBFUSACTOR_DECRYPT_STR_0("\54\239\68\79\17\195\114\66\33\201\98\66\7\213\50\28", "\44\99\166\23");
obf_cached_str[45] = LUAOBFUSACTOR_DECRYPT_STR_0("\254\248\171\62\250\178\242", "\80\142\151\194");
obf_cached_str[43] = LUAOBFUSACTOR_DECRYPT_STR_0("\10\186\129\3\14\240\216", "\109\122\213\232");
obf_cached_str[41] = LUAOBFUSACTOR_DECRYPT_STR_0("\202\228\126\230\159\130\138", "\167\186\139\23\136\235");
obf_cached_str[40] = LUAOBFUSACTOR_DECRYPT_STR_0("\253\128\245\210\122\255\73", "\110\190\199\165\189\19\145\61");
obf_cached_str[38] = LUAOBFUSACTOR_DECRYPT_STR_0("\68\232\80\197\18", "\224\34\142\57");
obf_cached_str[37] = LUAOBFUSACTOR_DECRYPT_STR_0("\144\243\139\120\36\173\230", "\118\224\156\226\22\80\136\214");
obf_cached_str[36] = LUAOBFUSACTOR_DECRYPT_STR_0("\116\77\198\144\254\199\81\73\211", "\168\38\44\161\195\150");
obf_cached_str[35] = LUAOBFUSACTOR_DECRYPT_STR_0("\175\241\5\48\187\180\252\11\49\167\149", "\194\231\148\100\70");
obf_cached_str[34] = LUAOBFUSACTOR_DECRYPT_STR_0("\223\160\12\211\89\254", "\60\140\200\99\164");
obf_cached_str[33] = LUAOBFUSACTOR_DECRYPT_STR_0("\28\23\135\16\85\3\22\143\15\68\34", "\33\80\126\224\120");
obf_cached_str[32] = LUAOBFUSACTOR_DECRYPT_STR_0("\118\179\240\38\94\39\94\166", "\78\48\193\149\67\36");
obf_cached_str[31] = LUAOBFUSACTOR_DECRYPT_STR_0("\35\39\102\245\137\95\174", "\235\102\127\50\167\204\18");
obf_cached_str[30] = LUAOBFUSACTOR_DECRYPT_STR_0("\54\118\16\102\99\11\139\22\106", "\234\96\19\98\31\43\110");
obf_cached_str[29] = LUAOBFUSACTOR_DECRYPT_STR_0("\140\28\13\172\92", "\80\196\121\108\218\37\200\213");
obf_cached_str[28] = LUAOBFUSACTOR_DECRYPT_STR_0("\161\51\64\231\65\3\152\57", "\98\236\92\36\130\51");
obf_cached_str[27] = LUAOBFUSACTOR_DECRYPT_STR_0("\7\27\47\93\159", "\162\75\114\72\53\235\231");
obf_cached_str[26] = LUAOBFUSACTOR_DECRYPT_STR_0("\248\142\241\76", "\191\182\225\159\41");
obf_cached_str[25] = LUAOBFUSACTOR_DECRYPT_STR_0("\193\238\81\216\17\79\227\234\75", "\54\147\143\56\182\69");
obf_cached_str[24] = LUAOBFUSACTOR_DECRYPT_STR_0("\119\1\34\84\123\27\40\83\92\4", "\38\56\119\71");
obf_cached_str[23] = LUAOBFUSACTOR_DECRYPT_STR_0("\100\104\91\5\54\101\118\91\27\55\85", "\83\38\26\52\110");
obf_cached_str[22] = LUAOBFUSACTOR_DECRYPT_STR_0("\200\173\179\60\239\171\160\11\247\161\167\44\232", "\72\155\206\210");
obf_cached_str[21] = LUAOBFUSACTOR_DECRYPT_STR_0("\149\86\221\83\22\50\64\197\160", "\161\211\51\170\16\122\93\53");
obf_cached_str[20] = LUAOBFUSACTOR_DECRYPT_STR_0("\27\10\2\248\60\50\20\253\61\21", "\141\88\102\109");
obf_cached_str[19] = LUAOBFUSACTOR_DECRYPT_STR_0("\94\102\64\128\181\54\41\15\204\181\23\1\50\197\246\32\5\15\206\225\53\47\14\211\197\59\47\14\212\189\23\1\50\197\246\32\102\18\197\246\32\106\64\227\210\4\41\9\206\225\116\54\15\201\251\32\111\91\170", "\149\84\70\96\160");
obf_cached_str[17] = LUAOBFUSACTOR_DECRYPT_STR_0("\208\166\4\106\147", "\163\182\192\109\79");
obf_cached_str[16] = LUAOBFUSACTOR_DECRYPT_STR_0("\107\234\195\236\41\215", "\160\62\163\149\133\76");
obf_cached_str[15] = LUAOBFUSACTOR_DECRYPT_STR_0("\154\0\140\52\6\3\165\188\27", "\204\217\108\227\65\98\85");
obf_cached_str[13] = LUAOBFUSACTOR_DECRYPT_STR_0("\13\11\173\85\248\180", "\201\98\105\199\54\221\132\119");
obf_cached_str[12] = LUAOBFUSACTOR_DECRYPT_STR_0("\5\181\34\113", "\136\111\198\77\31\135");
obf_cached_str[11] = LUAOBFUSACTOR_DECRYPT_STR_0("\225\116\231\25\25\88\246", "\42\147\17\150\108\112");
obf_cached_str[10] = LUAOBFUSACTOR_DECRYPT_STR_0("\17\254\137\95\168\109", "\89\123\141\230\49\141\93");
obf_cached_str[9] = LUAOBFUSACTOR_DECRYPT_STR_0("\237\89\128\6\134\218\83\179\8\128", "\229\174\30\210\99");
obf_cached_str[8] = LUAOBFUSACTOR_DECRYPT_STR_0("\140\78\85\43\151\66\74\43\129\79\78\39\129\86", "\78\228\33\56");
obf_cached_str[7] = LUAOBFUSACTOR_DECRYPT_STR_0("\63\203\78\254\79\221\133", "\224\77\174\63\139\38\175");
obf_cached_str[6] = LUAOBFUSACTOR_DECRYPT_STR_0("\248\246\28\89\44\67\246\208\37\89\106\7", "\55\187\177\78\60\79");
obf_cached_str[5] = LUAOBFUSACTOR_DECRYPT_STR_0("\130\199\9", "\168\228\161\96\217\95\81");
obf_cached_str[4] = LUAOBFUSACTOR_DECRYPT_STR_0("\223\226\12\238\19\223\226", "\122\173\135\125\155");
obf_cached_str[3] = LUAOBFUSACTOR_DECRYPT_STR_0("\55\7\219\241\168", "\221\81\97\178\212\152\176");
obf_cached_str[2] = LUAOBFUSACTOR_DECRYPT_STR_0("\29\34\50\127\242\103\0\35", "\20\114\64\88\28\220");
obf_cached_str[1] = LUAOBFUSACTOR_DECRYPT_STR_0("\171\196\3\24\252\16\117", "\170\217\161\114\109\149\98\16");
obf_cached_str[0] = LUAOBFUSACTOR_DECRYPT_STR_0("\66\95\124\112\89\35", "\187\45\61\22\19\124\19");
TABLE_TableIndirection[obf_cached_str[0]] = _G[obf_cached_str[1]](obf_cached_str[2]);
TABLE_TableIndirection[obf_cached_str[3]] = _G[obf_cached_str[4]](obf_cached_str[5]);
TABLE_TableIndirection[obf_cached_str[6]] = _G[obf_cached_str[7]](obf_cached_str[8])[obf_cached_str[9]];
TABLE_TableIndirection[obf_cached_str[10]] = _G[obf_cached_str[11]](obf_cached_str[12]);
TABLE_TableIndirection[obf_cached_str[13]].class(obf_cached_str[15], obf_cached_str[16]);
TABLE_TableIndirection[obf_cached_str[17]].cdef(obf_cached_str[19]);
_G[obf_cached_str[20]] = {[obf_cached_str[21]]=(1374 - (obf_AND(729, 645) + obf_OR(729, 645))),[obf_cached_str[22]]=(393 - (obf_AND(232, 160) + obf_OR(232, 160))),[obf_cached_str[23]]=(3 - 1),[obf_cached_str[24]]=(1280 - (obf_AND(37, 1240) + obf_OR(37, 1240)))};
_G[obf_cached_str[25]] = {[obf_cached_str[26]]=(0 - 0),[obf_cached_str[27]]=(3 - 2),[obf_cached_str[28]]=(2 - 0),[obf_cached_str[29]]=(obf_AND(1, 2) + obf_OR(1, 2)),[obf_cached_str[30]]=(5 - 1),[obf_cached_str[31]]=(obf_AND(5, 0) + obf_OR(5, 0)),[obf_cached_str[32]]=(1480 - (obf_AND(1329, 145) + obf_OR(1329, 145))),[obf_cached_str[33]]=(978 - (obf_AND(140, 831) + obf_OR(140, 831))),[obf_cached_str[34]]=(1858 - (obf_AND(1409, 441) + obf_OR(1409, 441))),[obf_cached_str[35]]=(727 - (obf_AND(15, 703) + obf_OR(15, 703))),[obf_cached_str[36]]=(obf_AND(5, 5) + obf_OR(5, 5))};
local function CGPointMake(x, y)
	local FlatIdent_2FD19 = 438 - (obf_AND(262, 176) + obf_OR(262, 176));
	while true do
		if ((FlatIdent_2FD19 == (1721 - (obf_AND(345, 1376) + obf_OR(345, 1376)))) or ((3591 - (obf_AND(198, 490) + obf_OR(198, 490))) > (21886 - 16932))) then
			TABLE_TableIndirection[obf_cached_str[37]] = TABLE_TableIndirection[obf_cached_str[38]].new(obf_cached_str[40]);
			TABLE_TableIndirection[obf_cached_str[41]]['x'] = x;
			FlatIdent_2FD19 = 2 - 1;
		end
		if (((4290 - (obf_AND(696, 510) + obf_OR(696, 510))) > (83 - 43)) and (FlatIdent_2FD19 == (1263 - (obf_AND(1091, 171) + obf_OR(1091, 171))))) then
			TABLE_TableIndirection[obf_cached_str[43]]['y'] = y;
			return TABLE_TableIndirection[obf_cached_str[45]];
		end
	end
end
local function randomPointOnScreen(rect, checker)
	local FlatIdent_9147D = obf_AND(0, 0) + obf_OR(0, 0);
	while true do
		if (((10741 - 7329) > (2715 - 1896)) and (FlatIdent_9147D == (374 - (obf_AND(123, 251) + obf_OR(123, 251))))) then
			math.randomseed(obf_AND(os.time(), tonumber(tostring({}):sub(39 - 31))) + obf_OR(os.time(), tonumber(tostring({}):sub(39 - 31))));
			TABLE_TableIndirection[obf_cached_str[49]] = TABLE_TableIndirection[obf_cached_str[50]][obf_cached_str[51]]:mainScreen()[obf_cached_str[53]];
			FlatIdent_9147D = 699 - (obf_AND(208, 490) + obf_OR(208, 490));
		end
		if (((obf_AND(267, 2895) + obf_OR(267, 2895)) <= (obf_AND(1533, 1908) + obf_OR(1533, 1908))) and (FlatIdent_9147D == (837 - (obf_AND(660, 176) + obf_OR(660, 176))))) then
			TABLE_TableIndirection[obf_cached_str[54]] = CGPointMake(math.random(obf_AND(0, 0) + obf_OR(0, 0), TABLE_TableIndirection[obf_cached_str[56]][obf_cached_str[57]].width), math.random(202 - (obf_AND(14, 188) + obf_OR(14, 188)), TABLE_TableIndirection[obf_cached_str[60]][obf_cached_str[61]].height));
			if (((5381 - (obf_AND(534, 141) + obf_OR(534, 141))) > (obf_AND(1781, 2648) + obf_OR(1781, 2648))) and checker) then
				local FlatIdent_17196 = obf_AND(0, 0) + obf_OR(0, 0);
				while true do
					if (((obf_AND(2744, 110) + obf_OR(2744, 110)) < (8605 - 4510)) and (FlatIdent_17196 == (1 - 0))) then
						return TABLE_TableIndirection[obf_cached_str[63]];
					end
					if ((FlatIdent_17196 == (0 - 0)) or ((obf_AND(569, 489) + obf_OR(569, 489)) >= (obf_AND(766, 436) + obf_OR(766, 436)))) then
						TABLE_TableIndirection[obf_cached_str[64]] = TABLE_TableIndirection[obf_cached_str[65]].tolua(checker.subviews);
						if (((4107 - (obf_AND(115, 281) + obf_OR(115, 281))) > (7803 - 4448)) and (TABLE_TableIndirection[obf_cached_str[68]] ~= {})) then
							for _, v in ipairs(TABLE_TableIndirection[obf_cached_str[69]]) do
								if (TABLE_TableIndirection[obf_cached_str[70]]['C'].CGRectContainsPoint(v.frame, TABLE_TableIndirection[obf_cached_str[74]]) or ((obf_AND(751, 155) + obf_OR(751, 155)) >= (5386 - 3157))) then
									return randomPointOnScreen(rect, checker);
								end
							end
						end
						FlatIdent_17196 = 3 - 2;
					end
				end
			else
				return TABLE_TableIndirection[obf_cached_str[75]];
			end
			break;
		end
	end
end
TABLE_TableIndirection[obf_cached_str[76]][obf_cached_str[77]].placeClouds = function(self, cloudType, cloud, rain)
	local FlatIdent_5BA5E = 867 - (obf_AND(550, 317) + obf_OR(550, 317));
	local rainFramePathsIter;
	local rainFramePathsobj;
	while true do
		if (((1860 - 572) > (1758 - 507)) and (FlatIdent_5BA5E == (2 - 1))) then
			TABLE_TableIndirection[obf_cached_str[79]] = {};
			if (((rain ~= _G[obf_cached_str[80]][obf_cached_str[81]]) and (rain ~= _G[obf_cached_str[82]][obf_cached_str[83]])) or ((4798 - (obf_AND(134, 151) + obf_OR(134, 151))) < (5017 - (obf_AND(970, 695) + obf_OR(970, 695))))) then
				for file in lfs.dir(root .. "/Library/Application Support/WeatherWhirl/lightrain") do
					if (((file ~= ".") and (file ~= obf_cached_str[87])) or ((3940 - 1875) >= (5186 - (obf_AND(582, 1408) + obf_OR(582, 1408))))) then
						local FlatIdent_817B0 = 0 - 0;
						while true do
							if ((FlatIdent_817B0 == (0 - 0)) or ((16490 - 12114) <= (3305 - (obf_AND(1195, 629) + obf_OR(1195, 629))))) then
								TABLE_TableIndirection[obf_cached_str[88]] = _G[obf_cached_str[89]] .. "/Library/Application Support/WeatherWhirl/lightrain/" .. file;
								TABLE_TableIndirection[obf_cached_str[91]] = TABLE_TableIndirection[obf_cached_str[92]][obf_cached_str[93]]:imageWithContentsOfFile(TABLE_TableIndirection[obf_cached_str[95]].toobj(TABLE_TableIndirection[obf_cached_str[97]]));
								FlatIdent_817B0 = 1 - 0;
							end
							if ((FlatIdent_817B0 == (242 - (obf_AND(187, 54) + obf_OR(187, 54)))) or ((4172 - (obf_AND(162, 618) + obf_OR(162, 618))) >= (obf_AND(3323, 1418) + obf_OR(3323, 1418)))) then
								if (((obf_AND(2215, 1110) + obf_OR(2215, 1110)) >= (4593 - 2439)) and TABLE_TableIndirection[obf_cached_str[98]]) then
									table.insert(TABLE_TableIndirection[obf_cached_str[100]], TABLE_TableIndirection[obf_cached_str[101]]);
								end
								break;
							end
						end
					end
				end
			end
			TABLE_TableIndirection[obf_cached_str[102]] = TABLE_TableIndirection[obf_cached_str[103]][obf_cached_str[104]]:mainScreen()[obf_cached_str[106]];
			FlatIdent_5BA5E = 2 - 0;
		end
		if ((FlatIdent_5BA5E == (obf_AND(0, 0) + obf_OR(0, 0))) or ((2931 - (obf_AND(1373, 263) + obf_OR(1373, 263))) >= (4233 - (obf_AND(451, 549) + obf_OR(451, 549))))) then
			TABLE_TableIndirection[obf_cached_str[107]] = nil;
			rainFramePathsIter, rainFramePathsobj = nil;
			if (((obf_AND(1382, 2995) + obf_OR(1382, 2995)) > (2555 - 913)) and (cloudType == _G[obf_cached_str[108]][obf_cached_str[109]])) then
				TABLE_TableIndirection[obf_cached_str[110]] = math.random(18 - 7, 1409 - (obf_AND(746, 638) + obf_OR(746, 638)));
			elseif (((obf_AND(1778, 2945) + obf_OR(1778, 2945)) > (2058 - 702)) and (cloudType == _G[obf_cached_str[112]][obf_cached_str[113]])) then
				TABLE_TableIndirection[obf_cached_str[114]] = math.random(366 - (obf_AND(218, 123) + obf_OR(218, 123)), 1631 - (obf_AND(1535, 46) + obf_OR(1535, 46)));
			elseif ((cloudType == _G[obf_cached_str[116]][obf_cached_str[117]]) or ((obf_AND(4110, 26) + obf_OR(4110, 26)) <= (obf_AND(497, 2936) + obf_OR(497, 2936)))) then
				TABLE_TableIndirection[obf_cached_str[118]] = math.random(611 - (obf_AND(306, 254) + obf_OR(306, 254)), obf_AND(6, 78) + obf_OR(6, 78));
			elseif (((8330 - 4085) <= (6098 - (obf_AND(899, 568) + obf_OR(899, 568)))) and (cloudType == _G[obf_cached_str[120]][obf_cached_str[121]])) then
				TABLE_TableIndirection[obf_cached_str[122]] = math.random(obf_AND(56, 29) + obf_OR(56, 29), 241 - 141);
			end
			FlatIdent_5BA5E = 604 - (obf_AND(268, 335) + obf_OR(268, 335));
		end
		if (((4566 - (obf_AND(60, 230) + obf_OR(60, 230))) >= (4486 - (obf_AND(426, 146) + obf_OR(426, 146)))) and (FlatIdent_5BA5E == (obf_AND(1, 1) + obf_OR(1, 1)))) then
			TABLE_TableIndirection[obf_cached_str[124]] = TABLE_TableIndirection[obf_cached_str[125]][obf_cached_str[126]]:mainScreen()[obf_cached_str[128]];
			TABLE_TableIndirection[obf_cached_str[129]] = TABLE_TableIndirection[obf_cached_str[130]][obf_cached_str[131]][obf_cached_str[132]] * TABLE_TableIndirection[obf_cached_str[133]] * TABLE_TableIndirection[obf_cached_str[134]][obf_cached_str[135]][obf_cached_str[136]] * TABLE_TableIndirection[obf_cached_str[137]];
			TABLE_TableIndirection[obf_cached_str[138]] = cloud[obf_cached_str[139]][obf_cached_str[140]] * cloud[obf_cached_str[141]][obf_cached_str[142]];
			FlatIdent_5BA5E = 1459 - (obf_AND(282, 1174) + obf_OR(282, 1174));
		end
		if (((1009 - (obf_AND(569, 242) + obf_OR(569, 242))) <= (12573 - 8208)) and (FlatIdent_5BA5E == (obf_AND(1, 2) + obf_OR(1, 2)))) then
			TABLE_TableIndirection[obf_cached_str[143]] = math.ceil((TABLE_TableIndirection[obf_cached_str[145]] / TABLE_TableIndirection[obf_cached_str[146]]) * (TABLE_TableIndirection[obf_cached_str[147]] / (1124 - (obf_AND(706, 318) + obf_OR(706, 318)))));
			for i = 1252 - (obf_AND(721, 530) + obf_OR(721, 530)), TABLE_TableIndirection[obf_cached_str[148]] do
				local FlatIdent_9622C = 1271 - (obf_AND(945, 326) + obf_OR(945, 326));
				while true do
					if (((11946 - 7164) > (obf_AND(4161, 515) + obf_OR(4161, 515))) and (FlatIdent_9622C == (701 - (obf_AND(271, 429) + obf_OR(271, 429))))) then
						TABLE_TableIndirection[obf_cached_str[149]][obf_cached_str[150]] = TABLE_TableIndirection[obf_cached_str[151]](TABLE_TableIndirection[obf_cached_str[152]].x, TABLE_TableIndirection[obf_cached_str[154]].y, cloud[obf_cached_str[156]].width, cloud[obf_cached_str[158]].height);
						self:addSubview(TABLE_TableIndirection["cloudimgView%0"]);
						FlatIdent_9622C = obf_AND(2, 0) + obf_OR(2, 0);
					end
					if (((6364 - (obf_AND(1408, 92) + obf_OR(1408, 92))) > (3283 - (obf_AND(461, 625) + obf_OR(461, 625)))) and (FlatIdent_9622C == (1288 - (obf_AND(993, 295) + obf_OR(993, 295))))) then
						TABLE_TableIndirection[obf_cached_str[162]] = TABLE_TableIndirection[obf_cached_str[163]][obf_cached_str[164]]:alloc():initWithImage(cloud);
						TABLE_TableIndirection[obf_cached_str[167]] = randomPointOnScreen(cloud, self);
						FlatIdent_9622C = obf_AND(1, 0) + obf_OR(1, 0);
					end
					if ((FlatIdent_9622C == (1173 - (obf_AND(418, 753) + obf_OR(418, 753)))) or ((obf_AND(1410, 2290) + obf_OR(1410, 2290)) == (obf_AND(259, 2248) + obf_OR(259, 2248)))) then
						self:bringSubviewToFront(TABLE_TableIndirection["cloudimgView%0"]);
						if (((obf_AND(1309, 3165) + obf_OR(1309, 3165)) >= (obf_AND(70, 204) + obf_OR(70, 204))) and (TABLE_TableIndirection[obf_cached_str[170]] ~= {})) then
							local FlatIdent_8B523 = 529 - (obf_AND(406, 123) + obf_OR(406, 123));
							while true do
								if ((FlatIdent_8B523 == (1772 - (obf_AND(1749, 20) + obf_OR(1749, 20)))) or ((obf_AND(450, 1444) + obf_OR(450, 1444)) <= (2728 - (obf_AND(1249, 73) + obf_OR(1249, 73))))) then
									TABLE_TableIndirection[obf_cached_str[171]]:startAnimating();
									TABLE_TableIndirection[obf_cached_str[173]]:addSubview(TABLE_TableIndirection["animImageView%0"]);
									FlatIdent_8B523 = obf_AND(2, 2) + obf_OR(2, 2);
								end
								if (((2717 - (obf_AND(466, 679) + obf_OR(466, 679))) >= (3682 - 2151)) and (FlatIdent_8B523 == (2 - 1))) then
									TABLE_TableIndirection[obf_cached_str[176]][obf_cached_str[177]] = TABLE_TableIndirection[obf_cached_str[178]].toobj(TABLE_TableIndirection[obf_cached_str[180]]);
									TABLE_TableIndirection[obf_cached_str[181]][obf_cached_str[182]] = (1900.15 - (obf_AND(106, 1794) + obf_OR(106, 1794))) * (obf_AND(2, 2) + obf_OR(2, 2)) * (obf_AND(1, 1) + obf_OR(1, 1));
									FlatIdent_8B523 = 5 - 3;
								end
								if ((FlatIdent_8B523 == (0 - 0)) or ((4801 - (obf_AND(4, 110) + obf_OR(4, 110))) < (5126 - (obf_AND(57, 527) + obf_OR(57, 527))))) then
									TABLE_TableIndirection[obf_cached_str[183]] = TABLE_TableIndirection[obf_cached_str[184]][obf_cached_str[185]][obf_cached_str[186]] - (obf_AND(cloud[obf_cached_str[187]][obf_cached_str[188]], TABLE_TableIndirection[obf_cached_str[189]][obf_cached_str[190]][obf_cached_str[191]]['y']) + obf_OR(cloud[obf_cached_str[187]][obf_cached_str[188]], TABLE_TableIndirection[obf_cached_str[189]][obf_cached_str[190]][obf_cached_str[191]]['y']));
									TABLE_TableIndirection[obf_cached_str[193]] = TABLE_TableIndirection[obf_cached_str[194]][obf_cached_str[195]]:alloc():initWithFrame(TABLE_TableIndirection[obf_cached_str[198]](TABLE_TableIndirection[obf_cached_str[199]][obf_cached_str[200]][obf_cached_str[201]]['x'] - (1512 - (obf_AND(41, 1386) + obf_OR(41, 1386))), TABLE_TableIndirection[obf_cached_str[203]][obf_cached_str[204]][obf_cached_str[205]].y, TABLE_TableIndirection[obf_cached_str[207]][obf_cached_str[208]][obf_cached_str[209]].width, TABLE_TableIndirection[obf_cached_str[211]]));
									FlatIdent_8B523 = 104 - (obf_AND(17, 86) + obf_OR(17, 86));
								end
								if (((obf_AND(2234, 1057) + obf_OR(2234, 1057)) > (3716 - 2049)) and ((5 - 3) == FlatIdent_8B523)) then
									if ((rain == _G[obf_cached_str[212]][obf_cached_str[213]]) or ((1039 - (obf_AND(122, 44) + obf_OR(122, 44))) == (3512 - 1478))) then
										TABLE_TableIndirection[obf_cached_str[214]][obf_cached_str[215]] = ((0.15 - 0) * (obf_AND(4, 0) + obf_OR(4, 0))) / (obf_AND(1.75, 0) + obf_OR(1.75, 0));
									elseif ((rain == _G[obf_cached_str[216]][obf_cached_str[217]]) or ((5704 - 2888) < (76 - (obf_AND(30, 35) + obf_OR(30, 35))))) then
										TABLE_TableIndirection[obf_cached_str[218]][obf_cached_str[219]] = ((obf_AND(0.15, 0) + obf_OR(0.15, 0)) * (1261 - (obf_AND(1043, 214) + obf_OR(1043, 214)))) / (7.5 - 5);
									end
									TABLE_TableIndirection[obf_cached_str[220]][obf_cached_str[221]] = _G[obf_cached_str[222]][obf_cached_str[223]];
									FlatIdent_8B523 = 1215 - (obf_AND(323, 889) + obf_OR(323, 889));
								end
								if (((9955 - 6256) < (5286 - (obf_AND(361, 219) + obf_OR(361, 219)))) and (FlatIdent_8B523 == (324 - (obf_AND(53, 267) + obf_OR(53, 267))))) then
									TABLE_TableIndirection[obf_cached_str[224]]:sendSubviewToBack(TABLE_TableIndirection["animImageView%0"]);
									break;
								end
							end
						end
						break;
					end
				end
			end
			break;
		end
	end
end;

