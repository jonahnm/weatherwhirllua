local StrToNumber = tonumber;
local Byte = string.byte;
local Char = string.char;
local Sub = string.sub;
local Subg = string.gsub;
local Rep = string.rep;
local Concat = table.concat;
local Insert = table.insert;
local LDExp = math.ldexp;
local GetFEnv = getfenv or function()
	return _ENV;
end;
local Setmetatable = setmetatable;
local PCall = pcall;
local Select = select;
local Unpack = unpack or table.unpack;
local ToNumber = tonumber;
local function VMCall(ByteString, vmenv, ...)
	local DIP = 1;
	local repeatNext;
	ByteString = Subg(Sub(ByteString, 5), "..", function(byte)
		if (Byte(byte, 2) == 79) then
			repeatNext = StrToNumber(Sub(byte, 1, 1));
			return "";
		else
			local a = Char(StrToNumber(byte, 16));
			if repeatNext then
				local b = Rep(a, repeatNext);
				repeatNext = nil;
				return b;
			else
				return a;
			end
		end
	end);
	local function gBit(Bit, Start, End)
		if End then
			local Res = (Bit / (2 ^ (Start - 1))) % (2 ^ (((End - 1) - (Start - 1)) + 1));
			return Res - (Res % 1);
		else
			local Plc = 2 ^ (Start - 1);
			return (((Bit % (Plc + Plc)) >= Plc) and 1) or 0;
		end
	end
	local function gBits8()
		local a = Byte(ByteString, DIP, DIP);
		DIP = DIP + 1;
		return a;
	end
	local function gBits16()
		local a, b = Byte(ByteString, DIP, DIP + 2);
		DIP = DIP + 2;
		return (b * 256) + a;
	end
	local function gBits32()
		local a, b, c, d = Byte(ByteString, DIP, DIP + 3);
		DIP = DIP + 4;
		return (d * 16777216) + (c * 65536) + (b * 256) + a;
	end
	local function gFloat()
		local Left = gBits32();
		local Right = gBits32();
		local IsNormal = 1;
		local Mantissa = (gBit(Right, 1, 20) * (2 ^ 32)) + Left;
		local Exponent = gBit(Right, 21, 31);
		local Sign = ((gBit(Right, 32) == 1) and -1) or 1;
		if (Exponent == 0) then
			if (Mantissa == 0) then
				return Sign * 0;
			else
				Exponent = 1;
				IsNormal = 0;
			end
		elseif (Exponent == 2047) then
			return ((Mantissa == 0) and (Sign * (1 / 0))) or (Sign * NaN);
		end
		return LDExp(Sign, Exponent - 1023) * (IsNormal + (Mantissa / (2 ^ 52)));
	end
	local function gString(Len)
		local Str;
		if not Len then
			Len = gBits32();
			if (Len == 0) then
				return "";
			end
		end
		Str = Sub(ByteString, DIP, (DIP + Len) - 1);
		DIP = DIP + Len;
		local FStr = {};
		for Idx = 1, #Str do
			FStr[Idx] = Char(Byte(Sub(Str, Idx, Idx)));
		end
		return Concat(FStr);
	end
	local gInt = gBits32;
	local function _R(...)
		return {...}, Select("#", ...);
	end
	local function Deserialize()
		local Instrs = {};
		local Functions = {};
		local Lines = {};
		local Chunk = {Instrs,Functions,nil,Lines};
		local ConstCount = gBits32();
		local Consts = {};
		for Idx = 1, ConstCount do
			local Type = gBits8();
			local Cons;
			if (Type == 1) then
				Cons = gBits8() ~= 0;
			elseif (Type == 2) then
				Cons = gFloat();
			elseif (Type == 3) then
				Cons = gString();
			end
			Consts[Idx] = Cons;
		end
		Chunk[3] = gBits8();
		for Idx = 1, gBits32() do
			local Descriptor = gBits8();
			if (gBit(Descriptor, 1, 1) == 0) then
				local Type = gBit(Descriptor, 2, 3);
				local Mask = gBit(Descriptor, 4, 6);
				local Inst = {gBits16(),gBits16(),nil,nil};
				if (Type == 0) then
					Inst[3] = gBits16();
					Inst[4] = gBits16();
				elseif (Type == 1) then
					Inst[3] = gBits32();
				elseif (Type == 2) then
					Inst[3] = gBits32() - (2 ^ 16);
				elseif (Type == 3) then
					Inst[3] = gBits32() - (2 ^ 16);
					Inst[4] = gBits16();
				end
				if (gBit(Mask, 1, 1) == 1) then
					Inst[2] = Consts[Inst[2]];
				end
				if (gBit(Mask, 2, 2) == 1) then
					Inst[3] = Consts[Inst[3]];
				end
				if (gBit(Mask, 3, 3) == 1) then
					Inst[4] = Consts[Inst[4]];
				end
				Instrs[Idx] = Inst;
			end
		end
		for Idx = 1, gBits32() do
			Functions[Idx - 1] = Deserialize();
		end
		return Chunk;
	end
	local function Wrap(Chunk, Upvalues, Env)
		local Instr = Chunk[1];
		local Proto = Chunk[2];
		local Params = Chunk[3];
		return function(...)
			local Instr = Instr;
			local Proto = Proto;
			local Params = Params;
			local _R = _R;
			local VIP = 1;
			local Top = -1;
			local Vararg = {};
			local Args = {...};
			local PCount = Select("#", ...) - 1;
			local Lupvals = {};
			local Stk = {};
			for Idx = 0, PCount do
				if (Idx >= Params) then
					Vararg[Idx - Params] = Args[Idx + 1];
				else
					Stk[Idx] = Args[Idx + 1];
				end
			end
			local Varargsz = (PCount - Params) + 1;
			local Inst;
			local Enum;
			while true do
				Inst = Instr[VIP];
				Enum = Inst[1];
				if (Enum <= 212) then
					if (Enum <= 105) then
						if (Enum <= 52) then
							if (Enum <= 25) then
								if (Enum <= 12) then
									if (Enum <= 5) then
										if (Enum <= 2) then
											if (Enum <= 0) then
												local A;
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
											elseif (Enum == 1) then
												local A;
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = {};
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Stk[Inst[3]];
											else
												local A;
												Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Upvalues[Inst[3]] = Stk[Inst[2]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Upvalues[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Upvalues[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Inst[3];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												Stk[Inst[2]] = Upvalues[Inst[3]];
												VIP = VIP + 1;
												Inst = Instr[VIP];
												A = Inst[2];
												Stk[A](Unpack(Stk, A + 1, Inst[3]));
											end
										elseif (Enum <= 3) then
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if Stk[Inst[2]] then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										elseif (Enum > 4) then
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										else
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										end
									elseif (Enum <= 8) then
										if (Enum <= 6) then
											local A;
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Stk[A](Unpack(Stk, A + 1, Inst[3]));
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Unpack(Stk, A, Top);
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										elseif (Enum > 7) then
											local A;
											Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = {};
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
										else
											local A;
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										end
									elseif (Enum <= 10) then
										if (Enum > 9) then
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										else
											local A;
											Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3] ~= 0;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Env[Inst[3]] = Stk[Inst[2]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3] ~= 0;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Env[Inst[3]] = Stk[Inst[2]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = {};
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
									elseif (Enum == 11) then
										do
											return Stk[Inst[2]];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 18) then
									if (Enum <= 15) then
										if (Enum <= 13) then
											local A;
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											for Idx = Inst[2], Inst[3] do
												Stk[Idx] = nil;
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3] ~= 0;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
										elseif (Enum > 14) then
											local A;
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3] ~= 0;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return Stk[Inst[2]];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										else
											local A;
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if (Stk[Inst[2]] ~= Inst[4]) then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										end
									elseif (Enum <= 16) then
										local Edx;
										local Results;
										local B;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results = {Stk[A](Stk[A + 1])};
										Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									elseif (Enum == 17) then
										do
											return;
										end
									else
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									end
								elseif (Enum <= 21) then
									if (Enum <= 19) then
										local Edx;
										local Results;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
										Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if not Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									elseif (Enum == 20) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 23) then
									if (Enum > 22) then
										local A = Inst[2];
										local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										local Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
									else
										local K;
										local B;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										B = Inst[3];
										K = Stk[B];
										for Idx = B + 1, Inst[4] do
											K = K .. Stk[Idx];
										end
										Stk[Inst[2]] = K;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return Stk[Inst[2]];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum > 24) then
									local A;
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 38) then
								if (Enum <= 31) then
									if (Enum <= 28) then
										if (Enum <= 26) then
											local A;
											Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										elseif (Enum == 27) then
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Stk[Inst[3]] % Inst[4];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]] / Inst[4];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Stk[A + 1]));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
										else
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
									elseif (Enum <= 29) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									elseif (Enum > 30) then
										Stk[Inst[2]] = Env[Inst[3]];
									else
										local A;
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
								elseif (Enum <= 34) then
									if (Enum <= 32) then
										Stk[Inst[2]] = -Stk[Inst[3]];
									elseif (Enum > 33) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local A;
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 36) then
									if (Enum > 35) then
										local B;
										local A;
										Upvalues[Inst[3]] = Stk[Inst[2]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									else
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum > 37) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								end
							elseif (Enum <= 45) then
								if (Enum <= 41) then
									if (Enum <= 39) then
										local A;
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									elseif (Enum == 40) then
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									else
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum <= 43) then
									if (Enum > 42) then
										if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum == 44) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 48) then
								if (Enum <= 46) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								elseif (Enum == 47) then
									local Edx;
									local Results, Limit;
									local VA;
									local B;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 50) then
								if (Enum == 49) then
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum == 51) then
								local Step;
								local Index;
								local A;
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = #Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Index = Stk[A];
								Step = Stk[A + 2];
								if (Step > 0) then
									if (Index > Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Index < Stk[A + 1]) then
									VIP = Inst[3];
								else
									Stk[A + 3] = Index;
								end
							else
								local K;
								local B;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Inst[3];
								K = Stk[B];
								for Idx = B + 1, Inst[4] do
									K = K .. Stk[Idx];
								end
								Stk[Inst[2]] = K;
							end
						elseif (Enum <= 78) then
							if (Enum <= 65) then
								if (Enum <= 58) then
									if (Enum <= 55) then
										if (Enum <= 53) then
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
										elseif (Enum > 54) then
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Env[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
										else
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A]());
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Stk[A](Unpack(Stk, A + 1, Top));
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Unpack(Stk, A, Top);
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
										end
									elseif (Enum <= 56) then
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									elseif (Enum == 57) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
									else
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
									end
								elseif (Enum <= 61) then
									if (Enum <= 59) then
										local A = Inst[2];
										local Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										local Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
									elseif (Enum > 60) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									else
										Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									end
								elseif (Enum <= 63) then
									if (Enum > 62) then
										local A = Inst[2];
										local B = Inst[3];
										for Idx = A, B do
											Stk[Idx] = Vararg[Idx - A];
										end
									else
										local Edx;
										local Results, Limit;
										local B;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum == 64) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 71) then
								if (Enum <= 68) then
									if (Enum <= 66) then
										local Step;
										local Index;
										local VA;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Top = (A + Varargsz) - 1;
										for Idx = A, Top do
											VA = Vararg[Idx - A];
											Stk[Idx] = VA;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Index = Stk[A];
										Step = Stk[A + 2];
										if (Step > 0) then
											if (Index > Stk[A + 1]) then
												VIP = Inst[3];
											else
												Stk[A + 3] = Index;
											end
										elseif (Index < Stk[A + 1]) then
											VIP = Inst[3];
										else
											Stk[A + 3] = Index;
										end
									elseif (Enum > 67) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3] ~= 0;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Env[Inst[3]] = Stk[Inst[2]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 69) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum == 70) then
									local VA;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 74) then
								if (Enum <= 72) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								elseif (Enum > 73) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
								end
							elseif (Enum <= 76) then
								if (Enum == 75) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								end
							elseif (Enum > 77) then
								local A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 91) then
							if (Enum <= 84) then
								if (Enum <= 81) then
									if (Enum <= 79) then
										Stk[Inst[2]]();
									elseif (Enum > 80) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
									end
								elseif (Enum <= 82) then
									Stk[Inst[2]] = Stk[Inst[3]];
								elseif (Enum > 83) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = not Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								else
									local Results;
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 87) then
								if (Enum <= 85) then
									local VA;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								elseif (Enum == 86) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = #Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]] % Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] + Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = #Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]] % Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] + Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								else
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								end
							elseif (Enum <= 89) then
								if (Enum == 88) then
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local B;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									B = Stk[Inst[4]];
									if not B then
										VIP = VIP + 1;
									else
										Stk[Inst[2]] = B;
										VIP = Inst[3];
									end
								end
							elseif (Enum > 90) then
								local K;
								local B;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Inst[3];
								K = Stk[B];
								for Idx = B + 1, Inst[4] do
									K = K .. Stk[Idx];
								end
								Stk[Inst[2]] = K;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									local VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
							end
						elseif (Enum <= 98) then
							if (Enum <= 94) then
								if (Enum <= 92) then
									Stk[Inst[2]] = Wrap(Proto[Inst[3]], nil, Env);
								elseif (Enum == 93) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum <= 96) then
								if (Enum == 95) then
									Stk[Inst[2]] = #Stk[Inst[3]];
								else
									Stk[Inst[2]] = Stk[Inst[3]] / Inst[4];
								end
							elseif (Enum > 97) then
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = #Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = -Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] - Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 101) then
							if (Enum <= 99) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum > 100) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 103) then
							if (Enum > 102) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum > 104) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						else
							local A = Inst[2];
							local Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							local Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
						end
					elseif (Enum <= 158) then
						if (Enum <= 131) then
							if (Enum <= 118) then
								if (Enum <= 111) then
									if (Enum <= 108) then
										if (Enum <= 106) then
											local Edx;
											local Results, Limit;
											local K;
											local B;
											local A;
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											B = Inst[3];
											K = Stk[B];
											for Idx = B + 1, Inst[4] do
												K = K .. Stk[Idx];
											end
											Stk[Inst[2]] = K;
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											if (Stk[Inst[2]] == Stk[Inst[4]]) then
												VIP = VIP + 1;
											else
												VIP = Inst[3];
											end
										elseif (Enum == 107) then
											local Results;
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results = {Stk[A](Unpack(Stk, A + 1, Top))};
											Edx = 0;
											for Idx = A, Inst[4] do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										else
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Stk[A] = Stk[A](Stk[A + 1]);
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Inst[3];
										end
									elseif (Enum <= 109) then
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									elseif (Enum == 110) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 114) then
									if (Enum <= 112) then
										Stk[Inst[2]] = not Stk[Inst[3]];
									elseif (Enum > 113) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3] ~= 0;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									else
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum <= 116) then
									if (Enum == 115) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local Results;
										local Edx;
										local Results, Limit;
										local A;
										local K;
										local B;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										B = Inst[3];
										K = Stk[B];
										for Idx = B + 1, Inst[4] do
											K = K .. Stk[Idx];
										end
										Stk[Inst[2]] = K;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results = {Stk[A](Unpack(Stk, A + 1, Top))};
										Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum == 117) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local B;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
								end
							elseif (Enum <= 124) then
								if (Enum <= 121) then
									if (Enum <= 119) then
										Stk[Inst[2]] = {};
									elseif (Enum > 120) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 122) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum > 123) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								else
									local VA;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 127) then
								if (Enum <= 125) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = not Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum == 126) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 129) then
								if (Enum == 128) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum == 130) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 144) then
							if (Enum <= 137) then
								if (Enum <= 134) then
									if (Enum <= 132) then
										local K;
										local B;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										B = Inst[3];
										K = Stk[B];
										for Idx = B + 1, Inst[4] do
											K = K .. Stk[Idx];
										end
										Stk[Inst[2]] = K;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return Stk[Inst[2]];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									elseif (Enum > 133) then
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									else
										local A;
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if (Stk[Inst[2]] == Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									end
								elseif (Enum <= 135) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum == 136) then
									local A = Inst[2];
									local Index = Stk[A];
									local Step = Stk[A + 2];
									if (Step > 0) then
										if (Index > Stk[A + 1]) then
											VIP = Inst[3];
										else
											Stk[A + 3] = Index;
										end
									elseif (Index < Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								else
									local Edx;
									local Results;
									local B;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Stk[A + 1])};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 140) then
								if (Enum <= 138) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								elseif (Enum == 139) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								else
									local A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
							elseif (Enum <= 142) then
								if (Enum == 141) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum == 143) then
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							else
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 151) then
							if (Enum <= 147) then
								if (Enum <= 145) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum > 146) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								end
							elseif (Enum <= 149) then
								if (Enum > 148) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								elseif (Inst[2] > Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 150) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = not Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							else
								local Edx;
								local Results, Limit;
								local VA;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 154) then
							if (Enum <= 152) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							elseif (Enum == 153) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							else
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return Stk[Inst[2]];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 156) then
							if (Enum == 155) then
								local A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
							else
								local Edx;
								local Results;
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum > 157) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							for Idx = Inst[2], Inst[3] do
								Stk[Idx] = nil;
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						else
							Stk[Inst[2]] = Upvalues[Inst[3]];
						end
					elseif (Enum <= 185) then
						if (Enum <= 171) then
							if (Enum <= 164) then
								if (Enum <= 161) then
									if (Enum <= 159) then
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									elseif (Enum == 160) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if (Stk[Inst[2]] ~= Inst[4]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									end
								elseif (Enum <= 162) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								elseif (Enum == 163) then
									local Edx;
									local Results, Limit;
									local VA;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 167) then
								if (Enum <= 165) then
									local K;
									local VA;
									local B;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									B = Inst[3];
									K = Stk[B];
									for Idx = B + 1, Inst[4] do
										K = K .. Stk[Idx];
									end
									Stk[Inst[2]] = K;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								elseif (Enum > 166) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Upvalues[Inst[3]] = Stk[Inst[2]];
								end
							elseif (Enum <= 169) then
								if (Enum == 168) then
									local NewProto = Proto[Inst[3]];
									local NewUvals;
									local Indexes = {};
									NewUvals = Setmetatable({}, {__index=function(_, Key)
										local Val = Indexes[Key];
										return Val[1][Val[2]];
									end,__newindex=function(_, Key, Value)
										local Val = Indexes[Key];
										Val[1][Val[2]] = Value;
									end});
									for Idx = 1, Inst[4] do
										VIP = VIP + 1;
										local Mvm = Instr[VIP];
										if (Mvm[1] == 82) then
											Indexes[Idx - 1] = {Stk,Mvm[3]};
										else
											Indexes[Idx - 1] = {Upvalues,Mvm[3]};
										end
										Lupvals[#Lupvals + 1] = Indexes;
									end
									Stk[Inst[2]] = Wrap(NewProto, NewUvals, Env);
								else
									local Results;
									local Edx;
									local Results, Limit;
									local A;
									local K;
									local B;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									B = Inst[3];
									K = Stk[B];
									for Idx = B + 1, Inst[4] do
										K = K .. Stk[Idx];
									end
									Stk[Inst[2]] = K;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									B = Stk[Inst[3]];
									Stk[A + 1] = B;
									Stk[A] = B[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum > 170) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A]();
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							else
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 178) then
							if (Enum <= 174) then
								if (Enum <= 172) then
									local A;
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum == 173) then
									local Results;
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] == Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum <= 176) then
								if (Enum == 175) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum > 177) then
								local A = Inst[2];
								local Cls = {};
								for Idx = 1, #Lupvals do
									local List = Lupvals[Idx];
									for Idz = 0, #List do
										local Upv = List[Idz];
										local NStk = Upv[1];
										local DIP = Upv[2];
										if ((NStk == Stk) and (DIP >= A)) then
											Cls[DIP] = NStk[DIP];
											Upv[1] = Cls;
										end
									end
								end
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 181) then
							if (Enum <= 179) then
								Env[Inst[3]] = Stk[Inst[2]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Env[Inst[3]] = Stk[Inst[2]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Env[Inst[3]] = Stk[Inst[2]];
							elseif (Enum == 180) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum <= 183) then
							if (Enum > 182) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							else
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum == 184) then
							local A;
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						else
							for Idx = Inst[2], Inst[3] do
								Stk[Idx] = nil;
							end
						end
					elseif (Enum <= 198) then
						if (Enum <= 191) then
							if (Enum <= 188) then
								if (Enum <= 186) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
								elseif (Enum > 187) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local Edx;
									local Results;
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								end
							elseif (Enum <= 189) then
								Stk[Inst[2]] = Stk[Inst[3]] % Stk[Inst[4]];
							elseif (Enum > 190) then
								if (Inst[2] < Stk[Inst[4]]) then
									VIP = Inst[3];
								else
									VIP = VIP + 1;
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 194) then
							if (Enum <= 192) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							elseif (Enum > 193) then
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							end
						elseif (Enum <= 196) then
							if (Enum == 195) then
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							else
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum > 197) then
							if (Stk[Inst[2]] == Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						end
					elseif (Enum <= 205) then
						if (Enum <= 201) then
							if (Enum <= 199) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								for Idx = Inst[2], Inst[3] do
									Stk[Idx] = nil;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
							elseif (Enum == 200) then
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum <= 203) then
							if (Enum > 202) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							end
						elseif (Enum > 204) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						else
							Env[Inst[3]] = Stk[Inst[2]];
						end
					elseif (Enum <= 208) then
						if (Enum <= 206) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Enum == 207) then
							if (Inst[2] == Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
						end
					elseif (Enum <= 210) then
						if (Enum == 209) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							for Idx = Inst[2], Inst[3] do
								Stk[Idx] = nil;
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						else
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						end
					elseif (Enum == 211) then
						local A = Inst[2];
						Stk[A] = Stk[A]();
					else
						local Edx;
						local Results, Limit;
						local A;
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results, Limit = _R(Stk[A](Stk[A + 1]));
						Top = (Limit + A) - 1;
						Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
					end
				elseif (Enum <= 319) then
					if (Enum <= 265) then
						if (Enum <= 238) then
							if (Enum <= 225) then
								if (Enum <= 218) then
									if (Enum <= 215) then
										if (Enum <= 213) then
											local A = Inst[2];
											local C = Inst[4];
											local CB = A + 2;
											local Result = {Stk[A](Stk[A + 1], Stk[CB])};
											for Idx = 1, C do
												Stk[CB + Idx] = Result[Idx];
											end
											local R = Result[1];
											if R then
												Stk[CB] = R;
												VIP = Inst[3];
											else
												VIP = VIP + 1;
											end
										elseif (Enum > 214) then
											local Edx;
											local Results, Limit;
											local A;
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Upvalues[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											Results, Limit = _R(Stk[A](Stk[A + 1]));
											Top = (Limit + A) - 1;
											Edx = 0;
											for Idx = A, Top do
												Edx = Edx + 1;
												Stk[Idx] = Results[Edx];
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Stk[A](Unpack(Stk, A + 1, Top));
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Unpack(Stk, A, Top);
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											do
												return;
											end
										else
											local B;
											local A;
											Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											B = Stk[Inst[3]];
											Stk[A + 1] = B;
											Stk[A] = B[Inst[4]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											Stk[Inst[2]] = Stk[Inst[3]];
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Stk[A](Unpack(Stk, A + 1, Inst[3]));
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											A = Inst[2];
											do
												return Unpack(Stk, A, Top);
											end
											VIP = VIP + 1;
											Inst = Instr[VIP];
											VIP = Inst[3];
										end
									elseif (Enum <= 216) then
										local VA;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Top = (A + Varargsz) - 1;
										for Idx = A, Top do
											VA = Vararg[Idx - A];
											Stk[Idx] = VA;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									elseif (Enum == 217) then
										if (Stk[Inst[2]] == Stk[Inst[4]]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local B;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										B = Stk[Inst[3]];
										Stk[A + 1] = B;
										Stk[A] = B[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Inst[3]));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
									end
								elseif (Enum <= 221) then
									if (Enum <= 219) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
									elseif (Enum == 220) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if (Stk[Inst[2]] ~= Inst[4]) then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum <= 223) then
									if (Enum > 222) then
										local Edx;
										local Results;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = not Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results = {Stk[A](Stk[A + 1])};
										Edx = 0;
										for Idx = A, Inst[4] do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									else
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3] ~= 0;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return Stk[Inst[2]];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										VIP = Inst[3];
									end
								elseif (Enum == 224) then
									local A = Inst[2];
									do
										return Stk[A], Stk[A + 1];
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum <= 231) then
								if (Enum <= 228) then
									if (Enum <= 226) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									elseif (Enum == 227) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Stk[A + 1]));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
									else
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
									end
								elseif (Enum <= 229) then
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum > 230) then
									local Edx;
									local Results;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Stk[Inst[2]][Stk[Inst[3]]] = Inst[4];
								end
							elseif (Enum <= 234) then
								if (Enum <= 232) then
									local K;
									local B;
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									B = Inst[3];
									K = Stk[B];
									for Idx = B + 1, Inst[4] do
										K = K .. Stk[Idx];
									end
									Stk[Inst[2]] = K;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
								elseif (Enum > 233) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 236) then
								if (Enum > 235) then
									local Results;
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Inst[2] > Stk[Inst[4]]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum == 237) then
								local B = Inst[3];
								local K = Stk[B];
								for Idx = B + 1, Inst[4] do
									K = K .. Stk[Idx];
								end
								Stk[Inst[2]] = K;
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 251) then
							if (Enum <= 244) then
								if (Enum <= 241) then
									if (Enum <= 239) then
										local A;
										Stk[Inst[2]] = Env[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Env[Inst[3]] = Stk[Inst[2]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									elseif (Enum > 240) then
										local Edx;
										local Results, Limit;
										local VA;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Top = (A + Varargsz) - 1;
										for Idx = A, Top do
											VA = Vararg[Idx - A];
											Stk[Idx] = VA;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local B;
										local T;
										local A;
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = {};
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										T = Stk[A];
										B = Inst[3];
										for Idx = 1, B do
											T[Idx] = Stk[A + Idx];
										end
									end
								elseif (Enum <= 242) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								elseif (Enum == 243) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 247) then
								if (Enum <= 245) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
								elseif (Enum > 246) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Top));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 249) then
								if (Enum == 248) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A = Inst[2];
									local T = Stk[A];
									local B = Inst[3];
									for Idx = 1, B do
										T[Idx] = Stk[A + Idx];
									end
								end
							elseif (Enum > 250) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 258) then
							if (Enum <= 254) then
								if (Enum <= 252) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								elseif (Enum > 253) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
								else
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								end
							elseif (Enum <= 256) then
								if (Enum > 255) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum == 257) then
								local Edx;
								local Results, Limit;
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum <= 261) then
							if (Enum <= 259) then
								local A;
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							elseif (Enum > 260) then
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
						elseif (Enum <= 263) then
							if (Enum == 262) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] ~= Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum == 264) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] ~= Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A;
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						end
					elseif (Enum <= 292) then
						if (Enum <= 278) then
							if (Enum <= 271) then
								if (Enum <= 268) then
									if (Enum <= 266) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										for Idx = Inst[2], Inst[3] do
											Stk[Idx] = nil;
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									elseif (Enum == 267) then
										local Edx;
										local Results, Limit;
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
										Top = (Limit + A) - 1;
										Edx = 0;
										for Idx = A, Top do
											Edx = Edx + 1;
											Stk[Idx] = Results[Edx];
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Stk[A](Unpack(Stk, A + 1, Top));
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										do
											return Unpack(Stk, A, Top);
										end
										VIP = VIP + 1;
										Inst = Instr[VIP];
										do
											return;
										end
									else
										local A;
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3];
									end
								elseif (Enum <= 269) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
								elseif (Enum == 270) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum <= 274) then
								if (Enum <= 272) then
									local Step;
									local Index;
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]] - Inst[4];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Index = Stk[A];
									Step = Stk[A + 2];
									if (Step > 0) then
										if (Index > Stk[A + 1]) then
											VIP = Inst[3];
										else
											Stk[A + 3] = Index;
										end
									elseif (Index < Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Enum == 273) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								else
									Stk[Inst[2]] = Stk[Inst[3]] % Inst[4];
								end
							elseif (Enum <= 276) then
								if (Enum > 275) then
									local Edx;
									local Results, Limit;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results, Limit = _R(Stk[A](Stk[A + 1]));
									Top = (Limit + A) - 1;
									Edx = 0;
									for Idx = A, Top do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Top));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
								end
							elseif (Enum == 277) then
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
							else
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							end
						elseif (Enum <= 285) then
							if (Enum <= 281) then
								if (Enum <= 279) then
									local A;
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								elseif (Enum == 280) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if (Stk[Inst[2]] == Inst[4]) then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								end
							elseif (Enum <= 283) then
								if (Enum == 282) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Env[Inst[3]] = Stk[Inst[2]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Env[Inst[3]] = Stk[Inst[2]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
								end
							elseif (Enum > 284) then
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Env[Inst[3]] = Stk[Inst[2]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Env[Inst[3]] = Stk[Inst[2]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Env[Inst[3]] = Stk[Inst[2]];
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 288) then
							if (Enum <= 286) then
								local A = Inst[2];
								local B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
							elseif (Enum == 287) then
								local A = Inst[2];
								local Step = Stk[A + 2];
								local Index = Stk[A] + Step;
								Stk[A] = Index;
								if (Step > 0) then
									if (Index <= Stk[A + 1]) then
										VIP = Inst[3];
										Stk[A + 3] = Index;
									end
								elseif (Index >= Stk[A + 1]) then
									VIP = Inst[3];
									Stk[A + 3] = Index;
								end
							else
								Stk[Inst[2]][Inst[3]] = Inst[4];
							end
						elseif (Enum <= 290) then
							if (Enum == 289) then
								local Step;
								local Index;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] - Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Index = Stk[A];
								Step = Stk[A + 2];
								if (Step > 0) then
									if (Index > Stk[A + 1]) then
										VIP = Inst[3];
									else
										Stk[A + 3] = Index;
									end
								elseif (Index < Stk[A + 1]) then
									VIP = Inst[3];
								else
									Stk[A + 3] = Index;
								end
							else
								local VA;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum > 291) then
							Stk[Inst[2]] = Inst[3] + Stk[Inst[4]];
						else
							Stk[Inst[2]] = Inst[3] ~= 0;
						end
					elseif (Enum <= 305) then
						if (Enum <= 298) then
							if (Enum <= 295) then
								if (Enum <= 293) then
									local Edx;
									local Results;
									local VA;
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Top = (A + Varargsz) - 1;
									for Idx = A, Top do
										VA = Vararg[Idx - A];
										Stk[Idx] = VA;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Results = {Stk[A](Unpack(Stk, A + 1, Top))};
									Edx = 0;
									for Idx = A, Inst[4] do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if not Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								elseif (Enum == 294) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return Stk[Inst[2]];
									end
								else
									local A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
								end
							elseif (Enum <= 296) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							elseif (Enum == 297) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
							else
								local B;
								local A;
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 301) then
							if (Enum <= 299) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] ~= Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 300) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							end
						elseif (Enum <= 303) then
							if (Enum > 302) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A]());
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							else
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							end
						elseif (Enum > 304) then
							local Edx;
							local Results;
							local A;
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] == Inst[4]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local B;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
						end
					elseif (Enum <= 312) then
						if (Enum <= 308) then
							if (Enum <= 306) then
								local A = Inst[2];
								local Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								local Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							elseif (Enum > 307) then
								local B;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Stk[Inst[4]];
								if B then
									VIP = VIP + 1;
								else
									Stk[Inst[2]] = B;
									VIP = Inst[3];
								end
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							end
						elseif (Enum <= 310) then
							if (Enum == 309) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local B;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Stk[Inst[4]];
								if not B then
									VIP = VIP + 1;
								else
									Stk[Inst[2]] = B;
									VIP = Inst[3];
								end
							end
						elseif (Enum > 311) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						end
					elseif (Enum <= 315) then
						if (Enum <= 313) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Enum == 314) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
						end
					elseif (Enum <= 317) then
						if (Enum == 316) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						end
					elseif (Enum == 318) then
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						if Stk[Inst[2]] then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					else
						local A;
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return Stk[Inst[2]];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						do
							return;
						end
					end
				elseif (Enum <= 372) then
					if (Enum <= 345) then
						if (Enum <= 332) then
							if (Enum <= 325) then
								if (Enum <= 322) then
									if (Enum <= 320) then
										local A;
										Stk[Inst[2]] = Upvalues[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Stk[A + 1]);
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if not Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									elseif (Enum > 321) then
										local B = Stk[Inst[4]];
										if not B then
											VIP = VIP + 1;
										else
											Stk[Inst[2]] = B;
											VIP = Inst[3];
										end
									else
										local A;
										Stk[Inst[2]] = Inst[3];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = #Stk[Inst[3]];
										VIP = VIP + 1;
										Inst = Instr[VIP];
										Stk[Inst[2]] = Inst[3] ~= 0;
										VIP = VIP + 1;
										Inst = Instr[VIP];
										A = Inst[2];
										Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
										VIP = VIP + 1;
										Inst = Instr[VIP];
										if not Stk[Inst[2]] then
											VIP = VIP + 1;
										else
											VIP = Inst[3];
										end
									end
								elseif (Enum <= 323) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									for Idx = Inst[2], Inst[3] do
										Stk[Idx] = nil;
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum > 324) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								else
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 328) then
								if (Enum <= 326) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									do
										return;
									end
								elseif (Enum == 327) then
									local A;
									Stk[Inst[2]] = Inst[3] ~= 0;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Env[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
								else
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
							elseif (Enum <= 330) then
								if (Enum > 329) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									local A;
									local K;
									local B;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									B = Inst[3];
									K = Stk[B];
									for Idx = B + 1, Inst[4] do
										K = K .. Stk[Idx];
									end
									Stk[Inst[2]] = K;
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Stk[A](Unpack(Stk, A + 1, Inst[3]));
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									do
										return Unpack(Stk, A, Top);
									end
									VIP = VIP + 1;
									Inst = Instr[VIP];
									VIP = Inst[3];
								end
							elseif (Enum > 331) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] ~= Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A = Inst[2];
								local Results = {Stk[A](Unpack(Stk, A + 1, Top))};
								local Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 338) then
							if (Enum <= 335) then
								if (Enum <= 333) then
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = {};
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum == 334) then
									local A;
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A](Unpack(Stk, A + 1, Inst[3]));
								else
									do
										return Stk[Inst[2]]();
									end
								end
							elseif (Enum <= 336) then
								if not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 337) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local Results;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Top))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 341) then
							if (Enum <= 339) then
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Enum == 340) then
								if (Stk[Inst[2]] < Stk[Inst[4]]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							else
								local A = Inst[2];
								local Results = {Stk[A](Stk[A + 1])};
								local Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
							end
						elseif (Enum <= 343) then
							if (Enum > 342) then
								local Edx;
								local Results, Limit;
								local VA;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, A + Inst[3]);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum == 344) then
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Inst[3]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						else
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						end
					elseif (Enum <= 358) then
						if (Enum <= 351) then
							if (Enum <= 348) then
								if (Enum <= 346) then
									local A;
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum == 347) then
									local A;
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									if Stk[Inst[2]] then
										VIP = VIP + 1;
									else
										VIP = Inst[3];
									end
								else
									Stk[Inst[2]] = Inst[3];
								end
							elseif (Enum <= 349) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							elseif (Enum == 350) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Stk[Inst[4]]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 354) then
							if (Enum <= 352) then
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							elseif (Enum == 353) then
								local B = Stk[Inst[4]];
								if B then
									VIP = VIP + 1;
								else
									Stk[Inst[2]] = B;
									VIP = Inst[3];
								end
							else
								local Edx;
								local Limit;
								local Results;
								local A;
								A = Inst[2];
								Results = {Stk[A]()};
								Limit = Inst[4];
								Edx = 0;
								for Idx = A, Limit do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if not Stk[Inst[2]] then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum <= 356) then
							if (Enum > 355) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
							else
								local A;
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								if (Stk[Inst[2]] == Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							end
						elseif (Enum > 357) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						else
							local B;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							B = Stk[Inst[4]];
							if not B then
								VIP = VIP + 1;
							else
								Stk[Inst[2]] = B;
								VIP = Inst[3];
							end
						end
					elseif (Enum <= 365) then
						if (Enum <= 361) then
							if (Enum <= 359) then
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
							elseif (Enum > 360) then
								Stk[Inst[2]] = Stk[Inst[3]] + Stk[Inst[4]];
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 363) then
							if (Enum > 362) then
								local Edx;
								local Results, Limit;
								local VA;
								local B;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Top = (A + Varargsz) - 1;
								for Idx = A, Top do
									VA = Vararg[Idx - A];
									Stk[Idx] = VA;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							else
								local Edx;
								local Results, Limit;
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							end
						elseif (Enum == 364) then
							Stk[Inst[2]] = Stk[Inst[3]] + Inst[4];
						else
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						end
					elseif (Enum <= 368) then
						if (Enum <= 366) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						elseif (Enum > 367) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						else
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum <= 370) then
						if (Enum == 369) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results;
							local A;
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum == 371) then
						local Edx;
						local Results, Limit;
						local A;
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
						Top = (Limit + A) - 1;
						Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
						Top = (Limit + A) - 1;
						Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						do
							return Stk[A](Unpack(Stk, A + 1, Top));
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						do
							return Unpack(Stk, A, Top);
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						VIP = Inst[3];
					else
						local B;
						local A;
						A = Inst[2];
						B = Stk[Inst[3]];
						Stk[A + 1] = B;
						Stk[A] = B[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
					end
				elseif (Enum <= 399) then
					if (Enum <= 385) then
						if (Enum <= 378) then
							if (Enum <= 375) then
								if (Enum <= 373) then
									local A;
									Stk[Inst[2]] = Upvalues[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Stk[A + 1]);
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									A = Inst[2];
									Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Stk[Inst[3]];
									VIP = VIP + 1;
									Inst = Instr[VIP];
									Stk[Inst[2]] = Inst[3];
								elseif (Enum == 374) then
									local A = Inst[2];
									do
										return Unpack(Stk, A, A + Inst[3]);
									end
								else
									local A = Inst[2];
									local Results = {Stk[A]()};
									local Limit = Inst[4];
									local Edx = 0;
									for Idx = A, Limit do
										Edx = Edx + 1;
										Stk[Idx] = Results[Edx];
									end
								end
							elseif (Enum <= 376) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
							elseif (Enum == 377) then
								local Edx;
								local Results;
								local B;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local Edx;
								local Results;
								local A;
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Stk[A + 1])};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 381) then
							if (Enum <= 379) then
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Env[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Stk[A + 1]));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Top));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							elseif (Enum > 380) then
								local Edx;
								local Results, Limit;
								local K;
								local B;
								local A;
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								B = Inst[3];
								K = Stk[B];
								for Idx = B + 1, Inst[4] do
									K = K .. Stk[Idx];
								end
								Stk[Inst[2]] = K;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Top));
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum <= 383) then
							if (Enum > 382) then
								local Results;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results = {Stk[A](Unpack(Stk, A + 1, Top))};
								Edx = 0;
								for Idx = A, Inst[4] do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							else
								local B;
								local Edx;
								local Results, Limit;
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
								Top = (Limit + A) - 1;
								Edx = 0;
								for Idx = A, Top do
									Edx = Edx + 1;
									Stk[Idx] = Results[Edx];
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								B = Stk[Inst[3]];
								Stk[A + 1] = B;
								Stk[A] = B[Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
							end
						elseif (Enum == 384) then
							local Edx;
							local Results, Limit;
							local B;
							local A;
							A = Inst[2];
							B = Stk[Inst[3]];
							Stk[A + 1] = B;
							Stk[A] = B[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
						end
					elseif (Enum <= 392) then
						if (Enum <= 388) then
							if (Enum <= 386) then
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							elseif (Enum > 387) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							else
								local A;
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Upvalues[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Stk[A + 1]);
								VIP = VIP + 1;
								Inst = Instr[VIP];
								for Idx = Inst[2], Inst[3] do
									Stk[Idx] = nil;
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3] ~= 0;
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								do
									return;
								end
							end
						elseif (Enum <= 390) then
							if (Enum == 389) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = {};
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Inst[3];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							else
								local A;
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								Stk[A](Unpack(Stk, A + 1, Inst[3]));
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							end
						elseif (Enum > 391) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
						end
					elseif (Enum <= 395) then
						if (Enum <= 393) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if (Stk[Inst[2]] ~= Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Enum == 394) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Inst[3]));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						end
					elseif (Enum <= 397) then
						if (Enum > 396) then
							local B;
							local T;
							local A;
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Env[Inst[3]] = Stk[Inst[2]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							T = Stk[A];
							B = Inst[3];
							for Idx = 1, B do
								T[Idx] = Stk[A + Idx];
							end
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						end
					elseif (Enum > 398) then
						local A;
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = {};
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					else
						local A;
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
					end
				elseif (Enum <= 412) then
					if (Enum <= 405) then
						if (Enum <= 402) then
							if (Enum <= 400) then
								local A;
								Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								Stk[Inst[2]] = Stk[Inst[3]];
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Stk[A](Unpack(Stk, A + 1, Inst[3]));
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								A = Inst[2];
								do
									return Unpack(Stk, A, Top);
								end
								VIP = VIP + 1;
								Inst = Instr[VIP];
								VIP = Inst[3];
							elseif (Enum > 401) then
								if (Stk[Inst[2]] ~= Inst[4]) then
									VIP = VIP + 1;
								else
									VIP = Inst[3];
								end
							elseif (Inst[2] < Stk[Inst[4]]) then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						elseif (Enum <= 403) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							for Idx = Inst[2], Inst[3] do
								Stk[Idx] = nil;
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Enum > 404) then
							local A;
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Env[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						else
							local A = Inst[2];
							Stk[A](Stk[A + 1]);
						end
					elseif (Enum <= 408) then
						if (Enum <= 406) then
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Stk[A + 1]));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Enum == 407) then
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
						else
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						end
					elseif (Enum <= 410) then
						if (Enum > 409) then
							local A;
							Stk[Inst[2]] = Inst[3] ~= 0;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							VIP = Inst[3];
						else
							local Edx;
							local Results, Limit;
							local A;
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Upvalues[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							for Idx = Inst[2], Inst[3] do
								Stk[Idx] = nil;
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Top)));
							Top = (Limit + A) - 1;
							Edx = 0;
							for Idx = A, Top do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Stk[A](Unpack(Stk, A + 1, Top));
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							do
								return Unpack(Stk, A, Top);
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						end
					elseif (Enum > 411) then
						local A;
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						if Stk[Inst[2]] then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					else
						local A = Inst[2];
						local T = Stk[A];
						for Idx = A + 1, Inst[3] do
							Insert(T, Stk[Idx]);
						end
					end
				elseif (Enum <= 419) then
					if (Enum <= 415) then
						if (Enum <= 413) then
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]][Stk[Inst[3]]] = Inst[4];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = {};
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						elseif (Enum == 414) then
							local Edx;
							local Results;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							if Stk[Inst[2]] then
								VIP = VIP + 1;
							else
								VIP = Inst[3];
							end
						else
							local Edx;
							local Results;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Results = {Stk[A](Stk[A + 1])};
							Edx = 0;
							for Idx = A, Inst[4] do
								Edx = Edx + 1;
								Stk[Idx] = Results[Edx];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Inst[3];
						end
					elseif (Enum <= 417) then
						if (Enum > 416) then
							local K;
							local B;
							local A;
							Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							Stk[Inst[2]] = Stk[Inst[3]];
							VIP = VIP + 1;
							Inst = Instr[VIP];
							A = Inst[2];
							Stk[A] = Stk[A](Stk[A + 1]);
							VIP = VIP + 1;
							Inst = Instr[VIP];
							B = Inst[3];
							K = Stk[B];
							for Idx = B + 1, Inst[4] do
								K = K .. Stk[Idx];
							end
							Stk[Inst[2]] = K;
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return Stk[Inst[2]];
							end
							VIP = VIP + 1;
							Inst = Instr[VIP];
							do
								return;
							end
						elseif (Stk[Inst[2]] <= Stk[Inst[4]]) then
							VIP = VIP + 1;
						else
							VIP = Inst[3];
						end
					elseif (Enum == 418) then
						Stk[Inst[2]] = Stk[Inst[3]] - Inst[4];
					else
						local Edx;
						local Results;
						local A;
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results = {Stk[A](Unpack(Stk, A + 1, Inst[3]))};
						Edx = 0;
						for Idx = A, Inst[4] do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
					end
				elseif (Enum <= 422) then
					if (Enum <= 420) then
						local A;
						Stk[Inst[2]] = Upvalues[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Stk[A + 1]);
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						do
							return Stk[A](Unpack(Stk, A + 1, Inst[3]));
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						do
							return Unpack(Stk, A, Top);
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						VIP = Inst[3];
					elseif (Enum == 421) then
						local Edx;
						local Results, Limit;
						local A;
						Stk[Inst[2]] = Env[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
						Top = (Limit + A) - 1;
						Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
					else
						local Edx;
						local Results, Limit;
						local A;
						Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Results, Limit = _R(Stk[A](Unpack(Stk, A + 1, Inst[3])));
						Top = (Limit + A) - 1;
						Edx = 0;
						for Idx = A, Top do
							Edx = Edx + 1;
							Stk[Idx] = Results[Edx];
						end
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Top));
					end
				elseif (Enum <= 424) then
					if (Enum == 423) then
						local A;
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
					else
						local A;
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Stk[Inst[3]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]] = Inst[3];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						Stk[Inst[2]][Stk[Inst[3]]] = Stk[Inst[4]];
						VIP = VIP + 1;
						Inst = Instr[VIP];
						A = Inst[2];
						Stk[A](Unpack(Stk, A + 1, Inst[3]));
					end
				elseif (Enum == 425) then
					local A;
					Stk[Inst[2]] = Stk[Inst[3]][Inst[4]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Stk[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Inst[3];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Inst[3];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = {};
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Stk[Inst[3]];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Inst[3];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					Stk[Inst[2]] = Inst[3];
					VIP = VIP + 1;
					Inst = Instr[VIP];
					A = Inst[2];
					Stk[A] = Stk[A](Unpack(Stk, A + 1, Inst[3]));
				else
					local A = Inst[2];
					do
						return Stk[A](Unpack(Stk, A + 1, Inst[3]));
					end
				end
				VIP = VIP + 1;
			end
		end;
	end
	return Wrap(Deserialize(), {}, vmenv)(...);
end
return VMCall("LOL!8D012O0003063O00737472696E6703043O006368617203043O00627974652O033O0073756203053O0062697433322O033O0062697403043O0062786F7203053O007461626C6503063O00636F6E63617403063O00696E7365727403073O00726571756972652O033O005448FE03053O0072322E97E703043O006361737403023O006F732O033O0016958D03083O00A059C6D549EA59D72O033O0061626903053O001E25B6F7D103053O00A52811D49E03043O006C6F6164030F3O00E9D00A3C24EFDA461268E1C0043A2403053O004685B9685303043O006364656603573O006E2C5033D9012O412C89004A5128C50105670DEF084A453E926E2C5033D9012O412C89082O4A2D892A766D24DD01424138926E2C5033D9012O412C89114B5723CE0A2O406AC50B4B436AE737706D24DD01424138926E2C03053O00A96425244A03543O006AEEB6491082A65506C7A45C0F86B61023A0845C0F86B60B6AEEB6491082A65506C7AB5E14C78C632989B6550782B00B6AEEB6491082A65506C7B75E138EA55E0583E2590E93E27E33B28B5E1482A55512DCC83903043O003060E7C203960C2O0074797065646566207369676E6564206368617220422O4F4C3B2O0A7479706564656620737472756374206F626A635F636C612O734O202A436C612O733B0A7479706564656620737472756374206F626A635F6F626A6563743O202A69643B0A7479706564656620737472756374206F626A635F73656C6563746F72202A53454C3B0A7479706564656620737472756374206F626A635F6D6574686F643O202A4D6574686F643B0A747970656465662069649O209O2020282A494D5029202869642C2053454C2C203O2E293B0A74797065646566207374727563742050726F746F636F6C6O2050726F746F636F6C3B0A7479706564656620737472756374206F626A635F70726F7065727479202A6F626A635F70726F70657274795F743B0A7479706564656620737472756374206F626A635F697661725O202A497661723B2O0A737472756374206F626A635F636C612O732O207B20436C612O73206973613B207D3B0A737472756374206F626A635F6F626A656374207B20436C612O73206973613B207D3B2O0A737472756374206F626A635F6D6574686F645F6465736372697074696F6E207B0A0953454C206E616D653B0A0963686172202A74797065733B0A7D3B2O0A2O2F7374646C69620A696E7420612O63652O7328636F6E73742063686172202A706174682C20696E7420616D6F6465293B4O202O2F207573656420746F20636865636B20696620612066696C65206578697374730A766F69642066722O652028766F69642A293B9O209O208O202O2F207573656420666F722066722O65696E672072657475726E65642064796E2E20612O6C6F6361746564206F626A656374732O0A2O2F73656C6563746F72730A53454C2073656C5F72656769737465724E616D6528636F6E73742063686172202A737472293B0A636F6E737420636861722A2073656C5F6765744E616D652853454C206153656C6563746F72293B2O0A2O2F636C612O7365730A436C612O73206F626A635F676574436C612O7328636F6E73742063686172202A6E616D65293B0A636F6E73742063686172202A636C612O735F6765744E616D6528436C612O7320636C73293B0A436C612O7320636C612O735F6765745375706572636C612O7328436C612O7320636C73293B0A436C612O73206F626A635F612O6C6F63617465436C612O735061697228436C612O73207375706572636C612O732C20636F6E73742063686172202A6E616D652C2073697A655F742065787472614279746573293B0A766F6964206F626A635F7265676973746572436C612O735061697228436C612O7320636C73293B0A766F6964206F626A635F646973706F7365436C612O735061697228436C612O7320636C73293B0A422O4F4C20636C612O735F69734D657461436C612O7328436C612O7320636C73293B2O0A2O2F696E7374616E6365730A436C612O73206F626A6563745F676574436C612O7328766F69642A206F626A656374293B8O202O2F20757365207468697320696E7374656164206F66206F626A2E6973612062656361757365206F662074612O67656420706F696E746572732O0A2O2F6D6574686F64730A4D6574686F6420636C612O735F676574496E7374616E63654D6574686F6428436C612O732061436C612O732C2053454C206153656C6563746F72293B0A53454C206D6574686F645F6765744E616D65284D6574686F64206D6574686F64293B0A636F6E73742063686172202A6D6574686F645F67657454797065456E636F64696E67284D6574686F64206D6574686F64293B0A494D50206D6574686F645F676574496D706C656D656E746174696F6E284D6574686F64206D6574686F64293B0A422O4F4C20636C612O735F726573706F6E6473546F53656C6563746F7228436C612O7320636C732C2053454C2073656C293B0A494D5020636C612O735F7265706C6163654D6574686F6428436C612O7320636C732C2053454C206E616D652C20494D5020696D702C20636F6E73742063686172202A7479706573293B0A766F6964206D6574686F645F65786368616E6765496D706C656D656E746174696F6E73284D6574686F64206D312C204D6574686F64206D32293B2O0A2O2F70726F746F636F6C730A50726F746F636F6C202A6F626A635F67657450726F746F636F6C28636F6E73742063686172202A6E616D65293B0A636F6E73742063686172202A70726F746F636F6C5F6765744E616D652850726F746F636F6C202A70293B0A737472756374206F626A635F6D6574686F645F6465736372697074696F6E2070726F746F636F6C5F6765744D6574686F644465736372697074696F6E2850726F746F636F6C202A702C0A0953454C206153656C2C20422O4F4C20697352657175697265644D6574686F642C20422O4F4C206973496E7374616E63654D6574686F64293B0A422O4F4C20636C612O735F636F6E666F726D73546F50726F746F636F6C28436C612O7320636C732C2050726F746F636F6C202A70726F746F636F6C293B0A422O4F4C20636C612O735F612O6450726F746F636F6C28436C612O7320636C732C2050726F746F636F6C202A70726F746F636F6C293B2O0A2O2F70726F706572746965730A6F626A635F70726F70657274795F7420636C612O735F67657450726F706572747928436C612O7320636C732C20636F6E73742063686172202A6E616D65293B0A6F626A635F70726F70657274795F742070726F746F636F6C5F67657450726F70657274792850726F746F636F6C202A70726F746F2C20636F6E73742063686172202A6E616D652C0A09422O4F4C206973526571756972656450726F70657274792C20422O4F4C206973496E7374616E636550726F7065727479293B0A636F6E73742063686172202A70726F70657274795F6765744E616D65286F626A635F70726F70657274795F742070726F7065727479293B0A636F6E73742063686172202A70726F70657274795F676574412O7472696275746573286F626A635F70726F70657274795F742070726F7065727479293B2O0A2O2F69766172730A4976617220636C612O735F676574496E7374616E63655661726961626C6528436C612O7320636C732C20636F6E737420636861722A206E616D65293B0A636F6E73742063686172202A697661725F6765744E616D6528497661722069766172293B0A636F6E73742063686172202A697661725F67657454797065456E636F64696E6728497661722069766172293B0A70747264692O665F7420697661725F6765744F2O6673657428497661722069766172293B2O0A2O2F696E7370656374696F6E0A436C612O73202A6F626A635F636F7079436C612O734C69737428756E7369676E656420696E74202A6F7574436F756E74293B0A50726F746F636F6C202O2A6F626A635F636F707950726F746F636F6C4C69737428756E7369676E656420696E74202A6F7574436F756E74293B0A4D6574686F64202A636C612O735F636F70794D6574686F644C69737428436C612O7320636C732C20756E7369676E656420696E74202A6F7574436F756E74293B0A737472756374206F626A635F6D6574686F645F6465736372697074696F6E202A70726F746F636F6C5F636F70794D6574686F644465736372697074696F6E4C6973742850726F746F636F6C202A702C0A09422O4F4C20697352657175697265644D6574686F642C20422O4F4C206973496E7374616E63654D6574686F642C20756E7369676E656420696E74202A6F7574436F756E74293B0A6F626A635F70726F70657274795F74202A636C612O735F636F707950726F70657274794C69737428436C612O7320636C732C20756E7369676E656420696E74202A6F7574436F756E74293B0A6F626A635F70726F70657274795F74202A70726F746F636F6C5F636F707950726F70657274794C6973742850726F746F636F6C202A70726F746F2C20756E7369676E656420696E74202A6F7574436F756E74293B0A50726F746F636F6C202O2A636C612O735F636F707950726F746F636F6C4C69737428436C612O7320636C732C20756E7369676E656420696E74202A6F7574436F756E74293B0A50726F746F636F6C202O2A70726F746F636F6C5F636F707950726F746F636F6C4C6973742850726F746F636F6C202A70726F746F2C20756E7369676E656420696E74202A6F7574436F756E74293B0A49766172202A20636C612O735F636F7079497661724C69737428436C612O7320636C732C20756E7369676E656420696E74202A6F7574436F756E74293B0A766F6964204D53482O6F6B4D652O73616765457828436C612O73205F636C612O732C2053454C206D652O736167652C20494D5020682O6F6B2C20494D50202A6F6C64293B0A03013O0043030C3O007365746D6574617461626C6503073O00F76507231DDDB703083O00E3A83A6E4D79B8CF03023O005F4703073O0073657466656E76026O00F03F03063O00666F726D617403063O00747970656F6603023O00723803083O00C51B5CDF20D1BB1103083O000A51D7EB174DFCEF03043O009B633FA303063O00652O726F727303083O00652O72636F756E7403093O006C6F67746F70696373030A3O00636865636B7265646566030A3O007072696E74636465636C03063O00636E616D657303063O0014A0895E12A003043O003C73CCE6028O0003063O00F42EF965E42E03043O0010875A8B03013O006303043O005EBDA39503043O00E73DD5C203013O00692O034O00A32903043O001369CD5D03013O007303053O00BA00D1932B03053O005FC968BEE103013O006C03043O00A3C4CFC903043O00AECFABA103013O007103093O00E1F103F4B8DBE2F00A03063O00B78D9E6D9398030D3O003907F5052B07E3086C0AEE0D3E03043O006C4C698603013O0049030C3O00FECBA2E8C9E5C0B5A1C7E5D103053O00AE8BA5D18103013O0053030E3O00B6BDF1C8C10D757CE3A0EACED41703083O0018C3D382A1A6631003013O004C030D3O00530DFA2554184307A9205C184103063O00762663894C3303013O005103123O00E828161B0E2EF822451E062EFA66091D072703063O00409D4665726903013O006603053O0046A4A8E20403053O007020C8C78303013O006403063O00285F49BACFAE03073O00424C303CD8A3CB03013O0044030B3O00B68977F41FCA2BAF8475F603073O0044DAE619933FAE03013O004203043O008F057C6003053O00D6CD4A332C03013O007603043O00EC43EBF803053O00179A2C829C03013O003F03043O0007A9A4AA03063O007371C6CDCE5603013O004003023O008D5303043O003AE4379E03013O002303053O009785D13D2F03073O0055D4E9B04E5CCD03013O003A2O033O00797DA403043O00822A38E803013O005B03013O007B03013O002803013O006203013O005E03013O002A03013O0072030F3O004D53482O6F6B4D652O73616765457803093O006C617A7966756E637303083O006C6F612O6465707303063O0072656E616D6503063O003EF839D306DB03073O00E24D8C4BBA68BC03043O00BCC0C53203053O002FD9AEB05F03073O00ACC46607B6517E03083O0046D8BD1662D2341803053O00D9D0AD94C703053O00B3BABFC3E703083O00FF2A16E7ED3617EA03043O0084995F7803073O007479706564656603123O006D6163685F74696D65626173655F696E666F03143O00BCB30D25C8CEA9BCB70C2CE4DF9FB8BC0822C8CE03073O00C0D1D26E4D97BA03053O00636F6E737403063O00546B466F6E74030C3O00E30C2CFAEBFBD40804E6F1D003063O00A4806342899F030A3O00646570656E64735F6F6E03063O00EC362E2D831103083O0024984F5E48B5256203043O00C3C1573A03043O005FB7B82703073O00A33EEB3351D65603073O0062D55F874634E003053O00E8A2C5625103053O00349EC3A917030F3O00737472696E675F636F6E7374616E7403043O00656E756D03083O00636F6E7374616E7403063O0073747275637403063O0063667479706503063O006F706171756503083O001E6B2D48BF11712D03053O00CB781E432B03113O00696E666F726D616C5F70726F746F636F6C3O010003053O00636C612O73030E3O0066756E6374696F6E5F616C69617303073O007573657870617403123O006C6F61645F62726964676573752O706F727403093O006C6F61647479706573031A3O002F53797374656D2F4C6962726172792F4672616D65776F726B7303133O002F4C6962726172792F4672616D65776F726B7303143O007E2F4C6962726172792F4672616D65776F726B73030E3O0066696E645F6672616D65776F726B03063O006C6F6164656403093O006C6F616465645F6273030E3O006C6F61645F6672616D65776F726B03083O006D6574617479706503143O009E5DF85D8E5DAA478F43E9779E4CE64D8E5DE55A03043O0028ED298A030A3O00F84BEEF759D366F3F64D03053O002AA7149A9803073O0075C1AB4C75245203063O00412A9EC2221103043O0014265F0903083O008E7A47326C4D8D7B030F3O0006B6ED0D3801E2CF0A3401ADFC173703053O005B75C29F78030A3O0025222A1726E5362O133903073O00447A7D5E78559103073O002823C650CCDCA203073O00DA777CAF3EA8B903063O00A3FF5AC9A4FC03043O00A4C5902803043O008DF1A78E03063O00D6E390CAEBBD03093O00FDB7886F1FB05C30FE03083O005C8DC5E71B70D333030A3O00F6ED85B3D4F4EB83A6C203053O00B1869FEAC303083O00ADF930B0CCAFFF2603053O00A9DD8B5FC003073O00D38E6B372D22CD03063O0046BEEB1F5F4203053O00B7F603F6E003053O0085DA827A8603053O003AEBFAD4D903073O00585C9F83A4BCC303053O00833AA65BD203073O00BDE04EDF2BB78B03023O002DE803053O00A14E9CEA7603063O00A1B8DBD1A6BB03043O00BCC7D7A903073O00C3365675ECF91103053O00889C693F1B03043O006E616D65030A3O002O5F746F737472696E6703093O0070726F746F636F6C73030A3O0070726F7065727469657303083O0070726F706572747903073O006D6574686F647303053O006D7479706503053O00667479706503053O00637479706503023O00637403013O005403013O005603013O004703013O005203143O0032C9A8670C359DB5700522E2AA600031D8A8661603053O006F41BDDA12030A3O007C740F3A1848BD4A451C03073O00CF232B7B556B3C03073O004F95A9E47D75B203053O001910CAC08A03043O00F3CAA0E703063O00949DABCD82C903063O0024D1603DD4E403063O009643B41449B103063O009E1D0E59880A03043O002DED787A03053O00C4FCBB3CD203043O004CB788C203053O0079F2FC285503073O00741A868558302F03083O000CC4A1E0B27C12D803063O00127EA1C084DD03043O00563EAF1603053O00363F48CE64031E3O006D6574686F645F65786368616E6765496D706C656D656E746174696F6E7303123O00DB4D576FE66F88564770E644C55C5172EA7F03063O001BA839251A85030A3O00129568A7C439B875A6D003053O00B74DCA1CC803073O00280C800613369103043O00687753E903083O00E6FD2B2740E1F73503053O00239598474203043O0017E94FB503053O005A798822D003053O00CA1A4C0EC203043O007EA76E3503093O002F1139C7DA2B24002B03063O005F5D704E98BC03093O00D3F4922AE7AACBD1F003073O00B2A195E57584DE030C3O009ADACA93A202BF338DE4DEAE03083O0043E8BBBDCCC176C62O033O008223A503073O008FEB4ED5405B62030C3O00885087E171B88A4DBBE07DA603063O00D6ED28E4891003053O00A6EFEECA1003063O00C6E5838FB963030F3O006F626A6563745F676574436C612O7303073O0063626672616D6503083O0012C17B1CE038DC3F03053O00D867A8156803103O006BB951B17BB903AB7AA7409B71BB42B603043O00C418CD23030A3O0011B4F7093D9FF10F208C03043O00664EEB8303073O00C5113D4A433CAF03083O00549A4E54242759D703043O00F3E05B5D03053O00659D81363803053O000EBD93BB2603063O00197DC9EACB4303053O007AE001131103073O007319947863744703023O000F2903053O00216C5DD94403063O00D44DA7BEDE5F03043O00CDBB2BC103083O006E6F72657461696E03073O00900E562E83185F03043O004BE26B3A030B3O0059CB057503C7C15DDF027F03073O00AD38BE711A71A203063O00D9DB3904FEC503053O0097ABBE4D6503053O00C423F4A6FB03073O006BA54F98C9981D2O033O00594BFF03063O001F372E88AB3403043O00D227CCED03043O0094B148BC030B3O00ABA343D2A4BA52F0A9A64E03043O00B3C6D63703113O0053F0F4D843F0A6C242EEE5F243E8E7DE5303043O00AD208486030A3O0071241CE0BD25DF47150F03073O00AD2E7B688FCE5103073O008B222B8441861903073O0061D47D42EA25E3030A3O00B5DCB8300983EDB2300603053O007EEA83D65503063O0073697A656F66026O00104003123O00A35509C2CAE5AFF0B24B18E8C6F3E5FAB35503083O009FD0217BB7A9918F030A3O00CD652C39E14E2A3FFC5D03043O0056923A5803073O0067E0E3CEAAEC2E03083O009A38BF8AA0CE8956030A3O00B966FB826B338FC8834103083O00ACE63995E71C5AE1037C022O007479706564656620766F696420282A646973706F73655F68656C7065725F74292028766F6964202A737263293B0A7479706564656620766F696420282A636F70795F68656C7065725F74294O2028766F6964202A6473742C20766F6964202A737263293B2O0A73747275637420626C6F636B5F64657363726970746F72207B0A09756E7369676E6564206C6F6E6720696E742072657365727665643B9O202O2F204E552O4C0A09756E7369676E6564206C6F6E6720696E742073697A653B9O204O202O2F2073697A656F662873747275637420626C6F636B5F6C69746572616C290A09636F70795F68656C7065725F745O20636F70795F68656C7065723B6O202O2F20492O462028312O3C3235290A09646973706F73655F68656C7065725F742O20646973706F73655F68656C7065723B3O202O2F20492O462028312O3C3235290A7D3B2O0A73747275637420626C6F636B5F6C69746572616C207B0A0973747275637420626C6F636B5F6C69746572616C202A6973613B0A09696E7420666C6167733B0A09696E742072657365727665643B0A09766F6964202A696E766F6B653B0A0973747275637420626C6F636B5F64657363726970746F72202A64657363726970746F723B0A0973747275637420626C6F636B5F64657363726970746F7220643B202O2F2062656361757365207468657920636F6D6520696E2070616972730A7D3B2O0A73747275637420626C6F636B5F6C69746572616C202A5F4E53436F6E6372657465476C6F62616C426C6F636B3B0A73747275637420626C6F636B5F6C69746572616C202A5F4E53436F6E6372657465537461636B426C6F636B3B0A03053O0014A58FD66203063O00BB62CAE6B24803143O0032F5B6254935A1A63C4522EA9B3C4335E4B6314603053O002A4181C450030D3O0001454DC3280F07E2122O4FE52O03083O008E622A3DBA77676203103O003CB6111837AC073730BA0E183DAD3D1C03043O006858DF6203053O006465627567030B3O007573655F63626672616D6503123O0073746F705F7573696E675F63626672616D65030B3O00612O6466756E6374696F6E030B3O00612O6470726F746F636F6C03113O00612O6470726F746F636F6C6D6574686F64030B3O00736561726368706174687303073O006D656D6F697A65030D3O0066696E646672616D65776F726B030B3O0073747970655F6374797065030B3O006D747970655F6674797065030B3O0066747970655F637479706503083O0063747970655F637403083O0066747970655F6374030C3O006D6574686F645F66747970652O033O0053454C03083O0070726F746F636F6C03073O00636C612O73657303073O006973636C612O7303053O0069736F626A030B3O0069736D657461636C612O7303093O00636C612O736E616D65030A3O007375706572636C612O7303093O006D657461636C612O732O033O0069736103083O00636F6E666F726D7303063O006D6574686F6403083O00726573706F6E647303053O00697661727303043O006976617203073O00636F6E666F726D03053O00746F61726703083O006F76652O7269646503093O00612O646D6574686F6403073O007377692O7A6C6503063O0063612O6C657203093O0063612O6C737570657203053O00626C6F636B03053O00742O6F626A03053O00746F6C756103043O006E70747203063O0069706169727303073O00EA381FFBCBB02F03073O005B83566C8BAED3030C3O00F429B21462F225AB0758F83F03053O003D9B4BD87703084O00A2A12C591DDE0C03073O00BD64CBD25C3869030D3O002053F72B1055F43B3F50E92B2703043O00484F319D03073O00B78F38B28CB52903043O00DCE8D051030A3O00CA81E4253855ADFABFE103073O00C195DE85504C3A03053O00706169727303053O007072696E7403083O0083101E82D51D0AC103043O00B2A63D2F03043O007479706503053O00F448E2798403063O005E9B2A881AAA03053O00803A24A08303043O00D5E45F4603083O006FF693D4646AFED103053O00174ADBA2E4030B3O0036E44CAC753DE344BA3C7703053O005B598626CF00A0062O00121F3O00013O002059014O000200121F000100013O0020592O010001000300121F000200013O00205901020002000400121F000300053O0006500103000A00010001000405012O000A000100121F000300063O00205901040003000700121F000500083O00205901050005000900121F000600083O00205901060006000A0006A800073O000100062O00523O00064O00528O00523O00044O00523O00014O00523O00024O00523O00053O0012A50108000B6O000900073O00122O000A000C3O00122O000B000D6O0009000B6O00083O000200202O00090008000E00202O000A0008000F4O000B00073O00122O000C00103O00125C010D00114O0002010B000D000200062B000A00250001000B000405012O002500012O0067010A6O0023010A00013O002003000B000800124O000C00073O00122O000D00133O00122O000E00146O000C000E6O000B3O000200062O000A003500013O000405012O00350001002059010C000800152O0052000D00073O00125C010E00163O00125C010F00174O0002010D000F00022O0023010E00014O008C000C000E00010006E5000B003E00013O000405012O003E0001002059010C000800182O0079000D00073O00122O000E00193O00122O000F001A6O000D000F6O000C3O000100044O00440001002059010C000800182O0052000D00073O00125C010E001B3O00125C010F001C4O0032010D000F4O004C000C3O0001002059010C000800180012B8000D001D6O000C0002000100202O000C0008001E00122O000D001F6O000E8O000F3O00014O001000073O00122O001100203O00122O001200216O00100012000200121F001100224O0095010F001000114O000D000F00024O000E5O00122O000F00233O00122O001000246O0011000D6O000F0011000100122O000F00013O00202O000F000F002500202O0010000800262O0052001100073O00125C011200273O00125C011300284O0032011100134O004E00103O000200025C001100013O00207C0012000800264O001300073O00122O001400293O00122O0015002A6O001300156O00123O00020006A800130002000100032O00523O000B4O00523O00094O00523O00123O0006A800140003000100022O00523O00084O00523O000C3O0006A800150004000100012O00523O000C3O0006A800160005000100012O00523O00153O0006A800170006000100022O00523O00074O00523O00133O0006A800180007000100012O00523O00173O0006A800190008000100012O00523O000C3O00025C001A00094O001D011B00013O00122O001B002B6O001B5O00122O001B002C6O001B5O00122O001B002D3O0006A8001B000A000100012O00523O000F3O0006A8001C000B000100012O00523O001B3O0006A8001D000C000100012O00523O001B3O0006A8001E000D000100022O00523O000F4O00523O00074O001B011F5O00122O001F002E6O001F5O00122O001F002F6O001F3O00024O002000073O00122O002100313O00122O002200326O0020002200024O002100013O00125C012200334O00F90021000100012O0038001F002000212O00F0002000073O00122O002100343O00122O002200356O0020002200024O002100013O00122O002200336O0021000100012O0038001F002000210012CC001F00303O00025C001F000E3O0006A80020000F000100022O00523O001D4O00523O00073O0006A800210010000100042O00523O00204O00523O00084O00523O00074O00523O001D3O00025C002200114O00B9002300233O0006A800240012000100032O00523O000F4O00523O00074O00523O00233O0006A800250013000100072O00523O001F4O00523O00074O00523O00214O00523O000F4O00523O00224O00523O00234O00523O001D3O0006A800260014000100022O00523O00074O00523O000F3O0006A800270015000100012O00523O00233O0006A800280016000100022O00523O00274O00523O00073O0006A800290017000100012O00523O00223O0006A8002A0018000100022O00523O00074O00523O00234O0095002B3O00154O002C00296O002D00073O00122O002E00373O00122O002F00386O002D002F6O002C3O000200102O002B0036002C4O002C00296O002D00073O00122O002E003A3O00122O002F003B6O002D002F6O002C3O000200102O002B0039002C4O002C00296O002D00073O00122O002E003D3O00122O002F003E6O002D002F6O002C3O000200102O002B003C002C4O002C00296O002D00073O00122O002E00403O00122O002F00416O002D002F6O002C3O000200102O002B003F002C4O002C00296O002D00073O00122O002E00433O00122O002F00446O002D002F6O002C3O000200102O002B0042002C4O002C00296O002D00073O00122O002E00453O00122O002F00466O002D002F6O002C3O000200102O002B001E002C4O002C00296O002D00073O00122O002E00483O00122O002F00496O002D002F6O002C3O000200102O002B0047002C4O002C00296O002D00073O00122O002E004B3O00122O002F004C6O002D002F6O002C3O000200102O002B004A002C4O002C00296O002D00073O00122O002E004E3O00122O002F004F6O002D002F6O002C3O000200102O002B004D002C4O002C00296O002D00073O00122O002E00513O00122O002F00526O002D002F6O002C3O000200102O002B0050002C4O002C00296O002D00073O00122O002E00543O00122O002F00556O002D002F6O002C3O000200102O002B0053002C4O002C00296O002D00073O0012FA002E00573O00122O002F00586O002D002F6O002C3O000200102O002B0056002C4O002C00296O002D00073O00122O002E005A3O00122O002F005B6O002D002F4O004E002C3O0002001092002B0059002C4O002C00296O002D00073O00122O002E005D3O00122O002F005E6O002D002F6O002C3O000200102O002B005C002C4O002C00296O002D00073O0012FA002E00603O00122O002F00616O002D002F6O002C3O000200102O002B005F002C4O002C00296O002D00073O00122O002E00633O00122O002F00646O002D002F4O004E002C3O0002001092002B0062002C4O002C00296O002D00073O00122O002E00663O00122O002F00676O002D002F6O002C3O000200102O002B0065002C4O002C00296O002D00073O0012FA002E00693O00122O002F006A6O002D002F6O002C3O000200102O002B0068002C4O002C00296O002D00073O00122O002E006C3O00122O002F006D6O002D002F4O004E002C3O0002001012002B006B002C001012002B006E0024001012002B006F0025001012002B00700025001012002B00710026001012002B00720027001012002B00730028001012002B0074002A0006A800230019000100012O00523O002B3O0006A8002C001A000100012O00523O00073O0006A8002D001B000100012O00523O00073O0006A8002E001C000100032O00523O00074O00523O000F4O00523O00233O00025C002F001D4O0052003000173O0006A80031001E000100012O00523O002C4O00270130000200022O0052003100173O0006A80032001F000100022O00523O00084O00523O001E4O00270131000200020006A800320020000100032O00523O00074O00523O00314O00523O002E3O0006A800330021000100052O00523O002E4O00523O00084O00523O00074O00523O000C4O00523O002C3O001009000E007500334O003300013O00122O003300766O00335O00122O003300776O00333O00054O003400073O00122O003500793O00122O0036007A6O0034003600022O007F00358O0033003400354O003400073O00122O0035007B3O00122O0036007C6O0034003600024O00358O0033003400354O003400073O00122O0035007D3O00125C0136007E4O00020134003600022O007F00358O0033003400354O003400073O00122O0035007F3O00122O003600806O0034003600024O00358O0033003400354O003400073O00122O003500813O00125C013600824O00090134003600024O00358O00330034003500122O003300783O00122O003300783O00202O0033003300834O003400073O00122O003500853O00122O003600866O00340036000200101200330084003400121F003300783O0020590133003300872O0052003400073O00125C013500893O00125C0136008A4O000201340036000200101200330088003400025C003300224O007700345O0006A800350023000100022O00523O001D4O00523O00073O0010120034008B00350006E5000B00AE2O013O000405012O00AE2O012O0052003500073O00125C0136008C3O00125C0137008D4O0002013500370002000650013500B22O010001000405012O00B22O012O0052003500073O00125C0136008E3O00125C0137008F4O00020135003700020006E5000B00BA2O013O000405012O00BA2O012O0052003600073O00125C013700903O00125C013800914O0002013600380002000650013600BE2O010001000405012O00BE2O012O0052003600073O00125C013700923O00125C013800934O00020136003800020006A800370024000100032O00523O000E4O00523O00334O00523O00073O0010120034009400370006A800370025000100042O00523O000E4O00523O00334O00523O00074O00523O00363O0010120034009500370006A800370026000100072O00523O00334O00523O001F4O00523O00074O00523O00354O00523O00234O00523O00214O00523O000F3O0006A800380027000100022O00523O00374O00523O00073O0010120034009600380006A800380028000100022O00523O00374O00523O00073O0010120034009700380006A800380029000100022O00523O00374O00523O00073O0010120034009800380006A80038002A000100022O00523O00374O00523O00073O0010120034009900380006A80038002B000100032O00523O00074O00523O00354O00523O00384O00B9003900393O0006A8003A002C000100072O00523O00214O00523O00074O00523O002E4O00523O00164O00523O000E4O00523O001D4O00523O00394O0052003B00073O00125C013C009A3O00125C013D009B4O0002013B003D00020006A8003C002D000100062O00523O00334O00523O00074O00523O001F4O00523O00354O00523O00384O00523O003A4O00380034003B003C2O00B9003B003C3O0006A8003D002E000100042O00523O003B4O00523O00074O00523O00354O00523O003C3O00108F0034009C003D4O003D3O00024O003E5O00102O003D009D003E4O003E5O00102O003D009E003E0006A8003E002F000100042O00523O00074O00523O00384O00523O00354O00523O003D3O0010120034009F003E0006A8003E0030000100012O00523O003D3O0006A8003F0031000100012O00523O000E3O001012003400A0003F0006A8003F0032000100022O00523O00074O00523O00343O0006A800400033000100012O00523O00073O0006A800410034000100022O00523O00404O00523O00074O002301425O0012CC004200A13O0006A800420035000100022O00523O00074O00523O00413O0006A800430036000100022O00523O00424O00523O003F3O00128D014300A26O004300013O00122O004300A36O004300033O00122O004400A43O00122O004500A53O00122O004600A66O0043000300010006A800440037000100042O00523O00194O00523O00074O00523O00434O00523O000F3O0012B3004400A76O00445O00122O004400A86O00445O00122O004400A93O0006A800440038000100072O00523O001E4O00523O00074O00523O000F4O00523O00084O00523O001C4O00523O00194O00523O000A3O0012CC004400AA4O0052004400173O0006A800450039000100032O00523O00074O00523O00114O00523O000C4O00270144000200020006A80045003A000100022O00523O00074O00523O00443O0006A80046003B000100022O00523O00084O00523O000C3O0020A90147000800AB4O004800073O00122O004900AC3O00122O004A00AD6O0048004A00024O00493O00024O004A00073O00122O004B00AE3O00122O004C00AF6O004A004C00022O00380049004A00462O006E014A00073O00122O004B00B03O00122O004C00B16O004A004C00024O004B3O00014O004C00073O00122O004D00B23O00122O004E00B36O004C004E00024O004B004C00462O00380049004A004B2O008C0047004900010006A80047003C000100032O00523O001A4O00523O00144O00523O000C3O0006A80048003D000100022O00523O00114O00523O000C3O0006A80049003E000100022O00523O00084O00523O000C3O0006A8004A003F000100032O00523O001A4O00523O00144O00523O000C3O0006A8004B0040000100032O00523O001A4O00523O00144O00523O000C3O0006A8004C0041000100022O00523O00114O00523O000C3O0006A8004D0042000100042O00523O00144O00523O000C4O00523O00464O00523O00083O0006A8004E0043000100022O00523O00084O00523O000C3O0006A8004F0044000100022O00523O00304O00523O004E3O0006A800500045000100022O00523O002E4O00523O004F3O0006A800510046000100022O00523O00324O00523O004F3O00209D0152000800AB4O005300073O00122O005400B43O00122O005500B56O0053005500024O00543O00024O005500073O00122O005600B63O00122O005700B76O0055005700024O0054005500494O005500073O00122O005600B83O00122O005700B96O0055005700024O00563O000A4O005700073O00122O005800BA3O00122O005900BB6O00570059000200202O00560057009D4O005700073O00122O005800BC3O00122O005900BD6O0057005900024O0056005700494O005700073O00122O005800BE3O00122O005900BF6O0057005900024O00560057004A4O005700073O00122O005800C03O00122O005900C16O0057005900024O00560057004B4O005700073O00122O005800C23O00122O005900C36O0057005900024O00560057004C4O005700073O00122O005800C43O00122O005900C56O0057005900024O00560057004D4O005700073O00122O005800C63O00122O005900C76O0057005900024O00560057004E4O005700073O00122O005800C83O00122O005900C96O0057005900024O00560057004F4O005700073O00122O005800CA3O00122O005900CB6O0057005900024O0056005700504O005700073O00122O005800CC3O00122O005900CD6O0057005900024O0056005700514O0054005500564O0052005400014O00528O00533O00014O005400073O00122O005500CE3O00122O005600CF6O00540056000200202O00530054009E4O00543O00014O005500073O00122O005600D03O00122O005700D16O0055005700022O00380054005500530006A800550047000100012O00523O00523O0006A8003B0048000100052O00523O00524O00523O000A4O00523O00484O00523O00074O00523O00543O0006A8003C0049000100012O00523O00073O00025C0056004A3O001012005300D200560020590156005300D2001012005400D3005600025C0056004B3O0006A80057004C000100012O00523O00563O001012005300D400570006A80057004D000100012O00523O00563O001012005300D50057001012005300D600560006A80057004E000100012O00523O00563O001012005300D700570006A80057004F000100012O00523O00463O001012005300D800570006A800570050000100012O00523O00303O001012005300D900570006A800570051000100012O00523O002E3O001012005300DA00570006A800570052000100012O00523O00323O001012005300DB00570006A800570053000100022O00523O00474O00523O00523O0006A800580054000100042O00523O00074O00523O001E4O00523O00484O00523O00553O0006A800590055000100022O00523O00084O00523O000C4O0077005A3O000500025C005B00563O001012005A00DC005B00025C005B00573O001012005A00DD005B00025C005B00583O001012005A00DE005B00025C005B00593O001012005A004A005B00025C005B005A3O001012005A00DF005B2O0052005B00173O0006A8005C005B000100042O00523O00074O00523O005A4O00523O00084O00523O000C4O0027015B000200020006A8005C005C000100022O00523O005B4O00523O00593O0006A8005D005D000100042O00523O005B4O00523O00594O00523O000F4O00523O00073O0006A8005E005E000100012O00523O005B3O0006A8005F005F000100022O00523O005B4O00523O00233O0006A800600060000100012O00523O005B3O0006A800610061000100012O00523O005B3O0020A90162000800AB4O006300073O00122O006400E03O00122O006500E16O0063006500024O00643O00024O006500073O00122O006600E23O00122O006700E36O0065006700022O00380064006500592O006E016500073O00122O006600E43O00122O006700E56O0065006700024O00663O00074O006700073O00122O006800E63O00122O006900E76O0067006900024O0066006700592O0052006700073O001231006800E83O00122O006900E96O0067006900024O00660067005C4O006700073O00122O006800EA3O00122O006900EB6O0067006900024O00660067005D4O006700073O001231006800EC3O00122O006900ED6O0067006900024O00660067005E4O006700073O00122O006800EE3O00122O006900EF6O0067006900024O00660067005F4O006700073O00125C016800F03O00124E016900F16O0067006900024O0066006700604O006700073O00122O006800F23O00122O006900F36O0067006900024O0066006700614O0064006500664O0062006400010006A800620062000100022O00523O00114O00523O000C3O0006A800630063000100022O00523O00464O00523O00623O0006A800640064000100022O00523O00084O00523O000C3O0006A800650065000100022O00523O002C4O00523O00643O0006A800660066000100022O00523O002E4O00523O00653O0006A800670067000100022O00523O002E4O00523O00653O0006A800680068000100022O00523O00114O00523O000C3O000661016900760301000A000405012O007603010020590169000C00F4002059016A000800AB2O006E016B00073O00122O006C00F53O00122O006D00F66O006B006D00024O006C3O00024O006D00073O00122O006E00F73O00122O006F00F86O006D006F00024O006C006D00632O006E016D00073O00122O006E00F93O00122O006F00FA6O006D006F00024O006E3O00084O006F00073O00122O007000FB3O00122O007100FC6O006F007100024O006E006F00622O0052006F00073O001231007000FD3O00122O007100FE6O006F007100024O006E006F00634O006F00073O00122O007000FF3O00122O00712O00015O006F007100024O006E006F00644O006F00073O0012310070002O012O00122O00710002015O006F007100024O006E006F00654O006F00073O00122O00700003012O00122O00710004015O006F007100024O006E006F00664O006F00073O00123100700005012O00122O00710006015O006F007100024O006E006F00674O006F00073O00122O00700007012O00122O00710008015O006F007100024O006E006F00684O006F00073O00125C01700009012O00125C0171000A013O0002016F007100022O0038006E006F00692O0038006C006D006E2O008C006A006C00010006A8006A0069000100032O00523O001A4O00523O00144O00523O000C4O00B9006B006B3O0006A8006C006A000100022O00523O00084O00523O00103O00207C006D000800264O006E00073O00122O006F000B012O00122O0070000C015O006E00706O006D3O00020006A8006E006B000100022O00523O00084O00523O006D3O0006A8006F006C000100012O00523O000C3O000661017000C70301000A000405012O00C7030100125C0170000D013O003C0070000C00700006A80071006D000100092O00523O000C4O00523O006B4O00523O001E4O00523O00714O00523O00074O00523O00114O00523O006E4O00523O006C4O00523O00703O0006A80072006E000100052O00523O006C4O00523O00704O00523O00084O00523O000C4O00523O00713O0006A80073006F000100052O00523O006C4O00523O00704O00523O00114O00523O000C4O00523O00713O0006A800740070000100052O00523O006F4O00523O00114O00523O00704O00523O00714O00523O006C3O0006A800750071000100052O00523O00754O00523O00734O00523O00714O00523O006C4O00523O00704O007700765O0006A800770072000100052O00523O001A4O00523O00144O00523O000C4O00523O00764O00523O00133O0006A800780073000100052O00523O000C4O00523O00764O00523O00134O00523O00714O00523O00583O0006A8006B0074000100062O00523O00714O00523O00584O00523O000C4O00523O00764O00523O00134O00523O006B3O0006A800790075000100042O00523O006F4O00523O00774O00523O00734O00523O00793O0006A8007A0076000100032O00523O001A4O00523O00144O00523O000C3O0006A8007B0077000100022O00523O00114O00523O000C3O0006A8007C0078000100042O00523O001A4O00523O00144O00523O000C4O00523O00713O0006A8007D0079000100042O00523O00114O00523O000C4O00523O00714O00523O00453O0006A8007E007A000100032O00523O000C4O00523O00734O00523O00454O00B9007F007F4O002301805O0012CC0080000E013O007700805O0006A80081007B000100012O00523O00803O0006A80082007C000100012O00523O00803O0006A80083007D0001000F2O00523O001C4O00523O00074O00523O00724O00523O00464O00523O006F4O00523O002E4O00523O00714O00523O00454O00523O002D4O00523O00094O00523O00324O00523O007F4O00523O000C4O00523O002C4O00523O002F3O0006A80084007E000100032O00523O001A4O00523O00144O00523O000C3O0006A80085007F000100022O00523O00114O00523O000C3O0006A800860080000100022O00523O00084O00523O000C3O0006A800870081000100012O00523O000C3O0006A800880082000100022O00523O00084O00523O000C3O0006A800890083000100022O00523O00074O00523O00233O0006A8008A0084000100022O00523O00894O00523O00884O0052008B00173O0006A8008C0085000100022O00523O00084O00523O00894O0027018B000200020006A8008C0086000100022O00523O008B4O00523O00883O00207C008D000800264O008E00073O00122O008F000F012O00122O00900010015O008E00906O008D3O00020006A8008E0087000100042O00523O00094O00523O008C4O00523O008D4O00523O00873O0006A8008F0088000100042O00523O00094O00523O008C4O00523O008D4O00523O00873O0020A90190000800AB4O009100073O00122O00920011012O00122O00930012015O0091009300024O00923O00024O009300073O00122O00940013012O00122O00950014015O0093009500022O00380092009300862O006E019300073O00122O00940015012O00122O00950016015O0093009500024O00943O00054O009500073O00122O00960017012O00122O00970018015O0095009700024O0094009500862O0052009500073O00123100960019012O00122O0097001A015O0095009700024O0094009500884O009500073O00122O0096001B012O00122O0097001C015O0095009700024O00940095008A4O009500073O00125C0196001D012O00124E0197001E015O0095009700024O00940095008C4O009500073O00122O0096001F012O00122O00970020015O0095009700024O0094009500874O0092009300944O0090009200012O007700905O0006A800910089000100022O00523O00904O00523O00133O0006A80092008A000100022O00523O00904O00523O00133O0006A80093008B000100032O00523O00454O00523O007D4O00523O00933O0006A80094008C000100042O00523O00074O00523O00944O00523O00454O00523O00793O0006A80095008D000100062O00523O003E4O00523O00724O00523O00464O00523O006F4O00523O00954O00523O00733O00025C0096008E3O0006A80097008F000100062O00523O00964O00523O00654O00523O00304O00523O00644O00523O007D4O00523O00953O0006A800980090000100042O00523O001E4O00523O00074O00523O00934O00523O00974O007700995O0006A8009A0091000100032O00523O00994O00523O00134O00523O00073O0006A8009B0092000100032O00523O009A4O00523O00904O00523O00133O00025C009C00934O0018009D3O00074O009E00073O00122O009F0022012O00122O00A00023015O009E00A0000200122O009F00246O009D009E009F4O009E00073O00122O009F0024012O00122O00A00025013O00A7019E00A0000200122O009F00246O009D009E009F4O009E00073O00122O009F0026012O00122O00A00027015O009E00A0000200122O009F00246O009D009E009F4O009E00073O00125C019F0028012O00129F00A00029015O009E00A0000200122O009F00246O009D009E009F4O009E00073O00122O009F002A012O00122O00A0002B015O009E00A0000200122O009F00246O009D009E009F2O0052009E00073O00125C019F002C012O00129F00A0002D015O009E00A0000200122O009F00246O009D009E009F4O009E00073O00122O009F002E012O00122O00A0002F015O009E00A0000200122O009F00246O009D009E009F0012CC009D0021013O0052009D00183O0006A8009E00940001000E2O00523O00934O00523O00974O00523O00394O00523O00074O00523O001E4O00523O009A4O00523O00084O00523O009B4O00523O006C4O00523O009C4O00523O001C4O00523O00324O00523O00684O00523O00094O0027019D000200020006A8009E0095000100072O00523O00744O00523O009E4O00523O00944O00523O00304O00523O00834O00523O00934O00523O00973O0006A8009F0096000100022O00523O009D4O00523O00733O0006A800A000970001000A2O00523O00934O00523O00744O00523O00A04O00523O001E4O00523O00074O00523O00714O00523O00454O00523O00834O00523O007D4O00523O00973O0006A800A10098000100072O00523O00734O00523O009D4O00523O00744O00523O005C4O00523O00914O00523O00074O00523O007B3O0006A800A20099000100082O00523O005D4O00523O009D4O00523O00744O00523O009E4O00523O00914O00523O00924O00523O007B4O00523O00733O0006A800A3009A000100032O00523O00924O00523O00074O00523O00A23O0020A901A4000800AB4O00A500073O00122O00A60030012O00122O00A70031015O00A500A700024O00A63O00034O00A700073O00122O00A80032012O00122O00A90033015O00A700A900022O000401A600A700724O00A700073O00122O00A80034012O00122O00A90035015O00A700A900024O00A600A700A14O00A700073O00122O00A80036012O00122O00A90037015O00A700A900022O003800A600A700A32O008C00A400A600010006A800A4009B000100092O00523O007B4O00523O009D4O00523O005C4O00523O00854O00523O008E4O00523O00074O00523O00914O00523O00704O00523O00A13O0006A800A5009C0001000B2O00523O00924O00523O008F4O00523O00A24O00523O00704O00523O007B4O00523O005D4O00523O009D4O00523O001E4O00523O00854O00523O00074O00523O00914O00B900A600A63O00125C01A70038013O003C00A7000800A72O005200A800124O002701A70002000200125C01A80039012O00065401A80057050100A7000405012O005705010006A800A6009D000100042O00523O000F4O00523O00074O00523O00724O00523O00093O000405012O005C05010006A800A6009E000100042O00523O00074O00523O000F4O00523O00724O00523O00093O00205901A7000800AB2O006E01A800073O00122O00A9003A012O00122O00AA003B015O00A800AA00024O00A93O00034O00AA00073O00122O00AB003C012O00122O00AC003D015O00AA00AC00024O00A900AA00A62O005200AA00073O00125C01AB003E012O00125C01AC003F013O000201AA00AC00022O003800A900AA00A42O005200AA00073O00125C01AB0040012O00125C01AC0041013O000201AA00AC00022O003800A900AA00A52O008C00A700A9000100205901A70008001800126401A80042015O00A70002000100202O00A7000800264O00A800073O00122O00A90043012O00122O00AA0044015O00A800AA6O00A73O000200202O00A8000800264O00A900073O00125C01AA0045012O00120400AB0046015O00A900AB6O00A83O000200202O00A9000800264O00AA00073O00122O00AB0047012O00122O00AC0048015O00AA00AC6O00A93O000200202O00AA000800262O005200AB00073O00125C01AC0049012O00125C01AD004A013O003201AB00AD4O004E00AA3O00020006A800AB009F0001000F2O00523O006C4O00523O00074O00523O002C4O00523O002D4O00523O00094O00523O007F4O00523O00324O00523O001C4O00523O00A94O00523O00084O00523O00A84O00523O00104O00523O00A74O00523O00AA4O00523O000C3O0006A800AC00A0000100062O00523O00074O00523O000E4O00523O00AC4O00523O006E4O00523O00094O00523O00103O0006A800AD00A1000100012O00523O00073O0006A800AE00A2000100062O00523O00754O00523O000E4O00523O00AE4O00523O00084O00523O00074O00523O00AD3O0006A800AF00A3000100042O00523O00074O00523O00AB4O00523O00324O00523O00093O0006A800B000A4000100042O00523O00454O00523O00714O00523O00AC4O00523O00AF3O0006A800B100A5000100022O00523O00B04O00523O00B13O0006A800B200A6000100022O00523O00B04O00523O00983O0006A800B300A7000100022O00523O00074O00523O00083O0006A8003900A8000100052O00523O00B34O00523O00B04O00523O00AC4O00523O00454O00523O00B13O0006A800B400A9000100022O00523O00094O00523O00323O0006A800B500AA000100012O00523O00B43O0006A800B600AB000100022O00523O00B54O00523O00B63O0006A8007F00AC000100022O00523O00AC4O00523O00B63O0006A800B700AD000100012O00523O00AD3O0006A800B800AE000100012O00523O00B73O0006A800B900AF000100022O00523O00574O00523O00773O001023000E001E000C00122O00BA004B015O000E00BA000D00122O00BA004C015O000E00BA008100122O00BA004D015O000E00BA008200122O00BA004E015O000E00BA003A00122O00BA004F013O0038000E00BA003B00121501BA0050015O000E00BA003C00122O00BA00AA3O00102O000E001500BA00122O00BA0051015O000E00BA004300122O00BA0052015O000E00BA001700122O00BA0053012O00122O00BB00A74O008E000E00BA00BB00122O00BA0054015O000E00BA002300122O00BA0055015O000E00BA002C00122O00BA0056015O000E00BA002E00122O00BA0057015O000E00BA003100122O00BA0058013O0038000E00BA003200125C01BA0059013O0058010E00BA009700122O00BA005A015O000E00BA004500102O000E00D400B900122O00BA005B015O000E00BA005800122O00BA005C015O000E00BA006A00122O00BA005D015O000E00BA006E00125C01BA005E013O0058010E00BA006C00122O00BA005F015O000E00BA006F00102O000E009F007100122O00BA0060015O000E00BA007200122O00BA0061015O000E00BA007300122O00BA0062015O000E00BA007400125C01BA0063013O0057000E00BA007500122O00BA0064015O000E00BA007800102O000E00D5007A00102O000E00D6007B00102O000E00D7007C00122O00BA0065015O000E00BA007D00122O00BA0066015O000E00BA007E00129801BA0067015O000E00BA008400122O00BA0068015O000E00BA008500122O00BA0069015O000E00BA006B00122O00BA006A015O000E00BA00B200122O00BA006B015O000E00BA009E00125C01BA006C013O0038000E00BA008300125C01BA006D013O0038000E00BA00A000125C01BA006E012O0006A800BB00B0000100032O00523O009D4O00523O00714O00523O00744O008E000E00BA00BB00122O00BA006F015O000E00BA009F00122O00BA0070015O000E00BA00AB00122O00BA0071015O000E00BA00AC00122O00BA0072015O000E00BA00AE00122O00BA0073013O0038000E00BA001300124D01BA0074015O000E00BA00B84O00BA3O00024O00BB00073O00122O00BC0075012O00122O00BD0076015O00BB00BD00024O00BC00073O00122O00BD0077012O00122O00BE0078013O000201BC00BE00022O00CA00BA00BB00BC4O00BB00073O00122O00BC0079012O00122O00BD007A015O00BB00BD00024O00BC00073O00122O00BD007B012O00122O00BE007C015O00BC00BE00024O00BA00BB00BC0006A800BB00B1000100022O00523O00BA4O00523O000E3O00122800BC001F6O00BD000E6O00BE3O00024O00BF00073O00122O00C0007D012O00122O00C1007E015O00BF00C100020006A800C000B2000100032O00523O00714O00523O00164O00523O00BB4O003800BE00BF00C02O005200BF00073O00125C01C0007F012O00125C01C10080013O000201BF00C100022O003800BE00BF00BA2O008C00BC00BE00012O003F00BC00BD3O00065001BC009E06010001000405012O009E060100121F00BC0081013O005200BD000E4O005501BC000200BE000405012O009C060100125C01C100333O00125C01C200333O0006D900C10069060100C2000405012O0069060100121F00C20082013O002600C3000F6O00C400073O00122O00C50083012O00122O00C60084015O00C400C6000200122O00C50085015O00C600C06O00C5000200024O00C600073O00122O00C70086012O00125C01C80087013O007D01C600C800024O00C700BF6O00C600C600C74O00C300C66O00C23O00012O005200C200073O00125C01C30088012O00125C01C40089013O000201C200C400020006D900BF009C060100C2000405012O009C060100121F00C20081013O005200C3000D4O005501C2000200C4000405012O0098060100121F00C70082013O002600C8000F6O00C900073O00122O00CA008A012O00122O00CB008B015O00C900CB000200122O00CA0085015O00CB00C66O00CA000200024O00CB00073O00122O00CC008C012O00125C01CD008D013O007D01CB00CD00024O00CC00C56O00CB00CB00CC4O00C800CB6O00C73O00010006D500C2008706010002000405012O00870601000405012O009C0601000405012O006906010006D500BC006806010002000405012O006806012O000B000E00024O00113O00013O00B33O00023O00026O00F03F026O00704002264O003300025O00122O000300016O00045O00122O000500013O00042O0003002100012O009D00076O0052000800024O009D000900014O009D000A00024O009D000B00034O009D000C00044O0052000D6O0052000E00063O00206C010F000600012O0032010C000F4O004E000B3O00022O009D000C00034O0056000D00046O000E00016O000F00016O000F0006000F00102O000F0001000F4O001000016O00100006001000102O00100001001000202O0010001000014O000D00104O0017000C6O004E000A3O0002002012010A000A00022O003B0009000A4O004C00073O000100041F0103000500012O009D000300054O0052000400024O00AA010300044O008101036O00113O00017O00023O00029O00010A3O00125C2O0100013O0026C60001000100010001000405012O000100010026C63O000700010002000405012O000700012O00B9000200024O000B000200024O000B3O00023O000405012O000100012O00113O00017O00063O00028O00027O0040026O00F03F03083O00746F6E756D62657203083O00746F737472696E670001273O00125C2O0100014O00B9000200033O0026C60001000500010002000405012O000500012O000B000300023O0026C60001001900010003000405012O0019000100121F000400044O004A010500026O0004000200024O000300046O00045O00062O0004001800013O000405012O001800012O009D000400014O009D000500024O0052000600034O000201040006000200062B0004001800010002000405012O0018000100121F000400054O0052000500024O00270104000200022O0052000300043O00125C2O0100023O0026C60001000200010001000405012O000200010026C63O001F00010006000405012O001F00012O00B9000400044O000B000400024O009D000400014O0018010500026O00068O0004000600024O000200043O00122O000100033O00044O000200012O00113O00017O00034O0003023O00676303043O0066722O65010D3O002692012O000A00010001000405012O000A00012O009D00015O0020BC0001000100024O00028O000300013O00202O0003000300034O00010003000200062O0001000B00010001000405012O000B00012O00B9000100014O000B000100024O00113O00019O002O0001044O009D00016O003C000100014O000B000100024O00113O00017O00033O00028O00026O00F03F03053O007063612O6C01133O00125C2O0100014O00B9000200033O0026C60001000500010002000405012O000500012O000B000300023O0026C60001000200010001000405012O0002000100121F000400034O00E700058O00068O0004000600054O000300056O000200043O00062O0002001000010001000405012O001000012O00113O00013O00125C2O0100023O000405012O000200012O00113O00017O00013O00028O00020F3O00125C010200013O0026C60002000100010001000405012O000100010006502O01000700010001000405012O000700012O007700036O0052000100033O0006A800033O000100042O00523O00014O00528O009D8O009D3O00014O000B000300023O000405012O000100012O00113O00013O00013O00093O00028O00027O004000026O00F03F03063O0072617773657403043O007479706503053O0081D5A099B803063O00E4E2B1C1EDD903063O0072617767657401393O00125C2O0100014O00B9000200033O0026C60001001B00010002000405012O001B00010026C60003001A00010003000405012O001A000100125C010400013O0026C60004000F00010004000405012O000F000100121F000500054O008201068O000700026O000800036O00050008000100044O001A0001000ECF0001000700010004000405012O000700012O009D000500014O005200066O00270105000200022O0052000300053O0026C60003001800010003000405012O001800012O00113O00013O00125C010400043O000405012O000700012O000B000300023O0026C60001002C00010001000405012O002C00012O005200025O0012C8000400066O000500026O0004000200024O000500023O00122O000600073O00122O000700086O00050007000200062O0004002B00010005000405012O002B00012O009D000400034O0052000500024O00270104000200022O0052000200043O00125C2O0100043O000ECF0004000200010001000405012O000200010026C60002003100010003000405012O003100012O00113O00013O00121F000400094O001801058O000600026O0004000600024O000300043O00122O000100023O00044O000200012O00113O00017O00013O00028O0002103O00125C010200014O00B9000300033O0026C60002000200010001000405012O000200012O009D00045O0006A800053O000100022O009D8O00528O0052000600014O00020104000600022O0052000300043O0006A800040001000100012O00523O00034O000B000400023O000405012O000200012O00113O00013O00027O0001074O009D00015O0006A800023O000100022O009D3O00014O00528O00AA2O0100024O00812O016O00113O00013O00017O0001064O009D00016O0014000200016O00038O000100036O00019O0000019O002O0002074O003A01028O00038O0002000200024O000300016O000200036O00029O0000017O00033O0003063O00612O63652O73026O001040028O00010B4O00DC00015O00202O0001000100014O00025O00122O000300026O00010003000200262O0001000800010003000405012O000800012O00672O016O00232O0100014O000B000100024O00113O00017O00023O00028O00026O00F0BF010B3O00125C2O0100014O00B9000200023O000ECF0001000200010001000405012O0002000100125C010200023O0006A800033O000100022O00528O00523O00024O000B000300023O000405012O000200012O00113O00013O00013O00033O00028O00026O00F03F2O00193O00125C012O00013O0026C63O000D00010002000405012O000D00012O009D00016O009D000200014O003C0001000100020026C60001000900010003000405012O000900012O00113O00014O009D00016O009D000200014O003C0001000100022O000B000100023O000ECF0001000100013O000405012O000100012O009D00015O0026C60001001300010003000405012O001300012O00113O00014O009D000100013O00206C2O01000100022O00A6000100013O00125C012O00023O000405012O000100012O00113O00017O00043O0003023O00696F03063O00737464652O7203053O00777269746503103O005B6F626A635D20252D3136732025730A020D3O00126B010300013O00202O00030003000200202O0003000300034O00055O00122O000600046O00078O00088O000900016O000A8O00088O00058O00033O00016O00017O00013O0003093O006C6F67746F7069637301093O00121F000200014O003C000200023O0006E50002000800013O000405012O000800012O009D00026O005200036O005A00046O004C00023O00012O00113O00017O00043O00028O0003083O00652O72636F756E74026O00F03F03063O00652O726F727301163O00125C010200013O0026C60002000100010001000405012O0001000100121F000300023O00121F000400024O003C000400043O0006500104000900010001000405012O0009000100125C010400013O00206C01040004000300206C0104000400012O003800033O000400121F000300043O0006E50003001500013O000405012O001500012O009D00036O005200046O005A00056O004C00033O0001000405012O00150001000405012O000100012O00113O00017O00053O00028O0003053O00652O726F7203113O0035A330E326A42AE93AF025E73DBC26E27503043O008654D043026O00084002153O00125C010300013O0026C60003000100010001000405012O000100010006E53O000600013O000405012O000600012O000B3O00023O00121F000400024O009D00055O0006420106000E00010001000405012O000E00012O009D000600013O00125C010700033O00125C010800044O00020106000800022O005A00076O004E00053O000200125C010600054O008C000400060001000405012O00140001000405012O000100012O00113O00017O00023O00030A3O00636865636B726564656603063O00636E616D6573020B3O00121F000200013O0006500102000700010001000405012O0007000100121F000200024O003C0002000200012O003C000200023O000405012O000900012O006701026O0023010200014O000B000200024O00113O00017O00083O00028O00026O00F03F030A3O00636865636B7265646566027O0040030C3O0046710236485D765D600F3C4003073O0018341466532E3403143O0025730A6F6C643A0A0925730A6E65773A0A09257303063O00636E616D657303263O00125C010300014O00B9000400043O0026C60003000D00010002000405012O000D000100121F000500033O0006500105000800010001000405012O000800012O00113O00013O0006D90004000C00010002000405012O000C00012O0023010500014O000B000500023O00125C010300043O0026C60003001B00010004000405012O001B00012O009D00056O000D010600013O00122O000700053O00122O000800066O00060008000200122O000700076O00088O000900046O000A00026O0005000A00014O000500016O000500023O0026C60003000200010001000405012O0002000100121F000500084O003C0005000500012O003C000400053O0006500104002300010001000405012O002300012O00113O00013O00125C010300023O000405012O000200012O00113O00017O00123O00028O00027O004003053O007063612O6C03043O0063646566026O00F03F03063O00636E616D6573030A3O007072696E74636465636C03053O007072696E7403013O003B030E3O00D02E23280A842037211DC2232E3303053O006FA44F414403053O00652O726F72030F3O00D2D68C9E23EBC8C0C3DD3AF3D6DC9003063O008AA6B9E3BE4E03043O00C870C03103073O0079AB14A557324303063O0025730A092573030A3O00636865636B726564656603563O00125C010300014O00B9000400053O0026C60003000500010002000405012O000500012O000B000400023O0026C60003001700010001000405012O001700012O009D00066O00F300078O000800016O000900026O00060009000200062O0006000F00013O000405012O000F00012O00113O00013O00121F000600034O00C3000700013O00202O0007000700044O000800026O0006000800074O000500076O000400063O00122O000300053O0026C60003000200010005000405012O000200010006E50004003000013O000405012O0030000100125C010600013O0026C60006001C00010001000405012O001C000100121F000700064O00AA00070007000100122O000800066O00080008000100202O00080008000500202O00080008000500102O00070005000800122O000700073O00062O0007004A00013O000405012O004A000100121F000700084O0052000800023O00125C010900094O00ED0008000800092O0094010700020001000405012O004A0001000405012O001C0001000405012O004A000100125C010600013O0026C60006003100010001000405012O003100012O009D000700023O00125C0108000A3O00125C0109000B4O00020107000900020006D90005003F00010007000405012O003F000100121F0007000C4O008A000800023O00122O0009000D3O00122O000A000E6O0008000A6O00073O00012O009D000700034O009D000800023O00125C0109000F3O00125C010A00104O00020108000A000200125C010900114O0052000A00054O0052000B00024O008C0007000B0001000405012O004A0001000405012O0031000100121F000600064O003C00060006000100121F000700123O0006E50007005100013O000405012O005100010006420107005200010002000405012O005200012O0023010700014O003800063O000700125C010300023O000405012O000200012O00113O00017O00023O0003013O0020034O00010A3O0006E53O000700013O000405012O0007000100125C2O0100014O005200026O00ED0001000100020006502O01000800010001000405012O0008000100125C2O0100024O000B000100024O00113O00017O000C3O00028O00026O00F03F03063O00832B8273BD3F03063O0062A658D956D9034O0003053O006D61746368030F3O00C8B34249C3D8BDBF314FCB95B3CB3D03063O00BC2O961961E62O033O0073756203013O002A03043O0092CC4C4B03063O008DBAE93F626C02323O00125C010300014O00B9000400053O0026C60003001500010002000405012O001500012O009D00066O0059000700013O00122O000800033O00122O000900046O00070009000200062O0008000C00010001000405012O000C000100125C010800054O0052000900044O00020106000900022O0052000100064O009D000600024O0052000700054O0052000800014O005A00096O009B00066O008101065O0026C60003000200010001000405012O0002000100201E0106000500062O00AD000800013O00122O000900073O00122O000A00086O0008000A6O00063O00074O000500076O000400063O00062O0001002F00013O000405012O002F000100201E01060001000900125C010800023O00125C010900024O00020106000900020026C60006002F0001000A000405012O002F00012O009D00066O0013010700013O00122O0008000B3O00122O0009000C6O0007000900024O000800014O00020106000800022O0052000100063O00125C010300023O000405012O000200012O00113O00017O00313O00028O00026O00084003063O00E2FE3EA326E503053O0045918A4CD6027O0040034O0003043O006773756203153O005E22285B5E225D2A2922285B255E5D2A25627B7D2903153O005E22285B5E225D2A2922285B255E5D2A2562282O29026O00F03F03063O00612O7365727403153O005E22285B5E225D2B2922285B255E5D2A25625B5D29030F3O005E22285B5E225D2B2922284029253F03193O005E22285B5E225D2B29222840225B412D5A5D5B5E225D2B222903113O005E22285B5E225D2A2922285B5E225D2B29026O00104003063O0063DB9B9CBC0203063O007610AF2OE9DF030D3O0025732573207B0A0925733B0A7D03053O007461626C6503063O00636F6E6361742O033O003B0A0903013O000A03023O000A0903043O00CE9770A803073O001DEBE455DB8EEB03073O009BB71B0957995B03073O0028BEC43B2C24BC03053O006D6174636803133O00020D92FDB24633617896FDA72245720F95FABE03073O006D5C25BCD49A1D03013O007B03063O0017FBB6D6324E03063O003A648FC4A35103053O000F4C2AAC3103083O006E7A2243C35F298503043O0063BE524E03053O00B615D13B2A03043O00B453C01B03063O00DED737A57D4103053O003CD0D409F703083O002A4CB1A67A92A18D03233O00A4840AC0607BAA9F168E6A62B79F06DA3978AA9E45D8787AAC8E45C67C64A0D0458B6A03063O0016C5EA65AE1903043O002O3BACD803083O00E64D54C5BC16CFB703073O00BC0786B99FE4E303083O00559974A69CECC19003013O003F0412012O00125C010400014O00B9000500073O0026C6000400AA00010002000405012O00AA00010006E50006000F00013O000405012O000F00012O009D00086O0052000900064O0051010A00013O00122O000B00033O00122O000C00046O000A000C6O00083O000200062O0008009E00010001000405012O009E000100125C010800014O00B90009000D3O0026C60008005B00010005000405012O005B00012O00B9000C000C3O002692010B005A00010006000405012O005A000100125C010E00013O0026C6000E002800010001000405012O0028000100201E010F000B00070012A3011100086O0012000A6O000F001200104O000C00106O000B000F3O0026C6000C002700010001000405012O0027000100201E010F000B00070012A3011100096O0012000A6O000F001200104O000C00106O000B000F3O00125C010E000A3O0026C6000E003200010002000405012O0032000100121F000F000B3O000EBF0001002E0001000C000405012O002E00012O006701106O0023011000014O00520011000B4O008C000F00110001000405012O001400010026C6000E00450001000A000405012O004500010026C6000C003C00010001000405012O003C000100201E010F000B00070012A30111000C6O0012000A6O000F001200104O000C00106O000B000F3O0026C6000C004400010001000405012O0044000100201E010F000B00070012A30111000D6O0012000A6O000F001200104O000C00106O000B000F3O00125C010E00053O000ECF000500170001000E000405012O001700010026C6000C004F00010001000405012O004F000100201E010F000B00070012A30111000E6O0012000A6O000F001200104O000C00106O000B000F3O0026C6000C005700010001000405012O0057000100201E010F000B00070012A30111000F6O0012000A6O000F001200104O000C00106O000B000F3O00125C010E00023O000405012O00170001000405012O0014000100125C010800023O0026C60008006600010010000405012O006600012O009D000E00024O002D000F00066O001000013O00122O001100113O00122O001200126O0010001200024O0011000D6O000E0011000100044O009D00010026C60008008E00010002000405012O008E00012O009D000E00033O00125C010F00134O0052001000054O009D001100044O0052001200064O002701110002000200121F001200143O0020590112001200152O0052001300093O00125C011400164O0032011200144O004E000E3O00022O0052000D000E3O0006500106008D00010001000405012O008D000100125C010E00013O0026C6000E007800010001000405012O007800010006E50003008100013O000405012O0081000100201E010F000D000700125C011100173O00125C011200184O0002010F001200022O0052000D000F4O009D000F00034O0013011000013O00122O001100193O00122O0012001A6O0010001200024O0011000D4O0078011200046O001300016O001200136O000F8O000F5O000405012O0078000100125C010800103O0026C6000800960001000A000405012O009600010006A8000A3O000100032O00523O00094O009D3O00054O009D3O00014O0052000B00073O00125C010800053O000ECF0001001100010008000405012O001100012O0077000E6O00520009000E4O00B9000A000A3O00125C0108000A3O000405012O001100012O00B200086O009D000800034O00E3000900013O00122O000A001B3O00122O000B001C6O0009000B00024O000A00056O000B00066O000C00046O000D00016O000C000D6O00088O00085O0026C6000400C300010001000405012O00C3000100201E01083O001D2O0052010A00013O00122O000B001E3O00122O000C001F6O000A000C6O00083O000A4O0007000A6O000600096O000500083O00262O000500BD00010020000405012O00BD00012O009D000800013O00125C010900213O00125C010A00224O00020108000A0002000642010500C200010008000405012O00C200012O009D000800013O00125C010900233O00125C010A00244O00020108000A00022O0052000500083O00125C0104000A3O0026C6000400052O010005000405012O00052O01000650010700D200010001000405012O00D20001000650010600D200010001000405012O00D200012O009D000800013O0012E8000900253O00122O000A00266O0008000A00024O000900046O000A00016O0009000200024O0008000800094O000800023O0006E5000700DA00013O000405012O00DA00012O009D000800013O00125C010900273O00125C010A00284O00020108000A000200062B000200042O010008000405012O00042O0100125C010800013O0026C6000800DB00010001000405012O00DB0001000650010600F700010001000405012O00F7000100125C010900013O0026C6000900E000010001000405012O00E000012O009D000A00064O0016000B00013O00122O000C00293O00122O000D002A6O000B000D00024O000C00013O00122O000D002B3O00122O000E002C6O000C000E00024O000D8O000A000D00014O000A00013O00122O000B002D3O00122O000C002E6O000A000C00024O000B00046O000C00016O000B000200024O000A000A000B4O000A00023O00044O00E000012O009D000900034O00E3000A00013O00122O000B002F3O00122O000C00306O000A000C00024O000B00056O000C00066O000D00046O000E00016O000D000E6O00098O00095O000405012O00DB000100125C010400023O0026C6000400020001000A000405012O000200010026920106000B2O010031000405012O000B2O010026C60006000C2O010006000405012O000C2O012O00B9000600063O0026C60007000F2O010006000405012O000F2O012O00B9000700073O00125C010400053O000405012O000200012O00113O00013O00013O00073O00028O00026O00F03F034O0003053O007461626C6503063O00696E7365727403043O003ED0BFDB03083O00325DB4DABD172E47021A3O00125C010200013O000ECF0002000500010002000405012O0005000100125C010300034O000B000300023O0026C60002000100010001000405012O000100010026C63O000A00010003000405012O000A00012O00B97O00121F000300043O0020FB0003000300054O00048O000500016O000600016O00078O000800023O00122O000900063O00122O000A00076O0008000A00024O000900016O000500096O00033O000100122O000200023O00044O000100012O00113O00017O00073O00028O0003053O006D6174636803083O009AE205F6E04BEDA403063O0060C4802DD384030F3O0020836856D5A1B1DC75C8680592EAB003083O00B855ED1B3FB2CFD403013O005F03183O00125C010300014O00B9000400043O0026C60003000200010001000405012O0002000100201E01053O00022O003B01075O00122O000800033O00122O000900046O000700096O00053O00024O000400056O000500014O005900065O00122O000700053O00122O000800066O00060008000200062O0007001300010001000405012O0013000100125C010700074O0052000800044O00AA010500084O008101055O000405012O000200012O00113O00017O00043O002O033O00737562027O004003013O002A034O00020D4O003601035O00202O00043O000100122O000600026O00040006000200122O000500033O00062O0006000800010001000405012O0008000100125C010600044O00ED0005000500062O005A00066O009B00036O008101036O00113O00017O00023O0003023O00365A03043O003F68396901094O009D00026O009D000300013O00125C010400013O00125C010500024O00020103000500022O005A00046O009B00026O008101026O00113O00019O002O0001053O0006A800013O000100022O00528O009D8O000B000100024O00113O00013O00017O0002074O008400028O000300016O000400016O0003000200024O0002000200034O000200028O00017O00043O0003063O000888AA571FC703043O00246BE7C42O033O00737562027O0040010D4O00A500025O00122O000300013O00122O000400026O0002000400024O000300013O00202O00043O000300122O000600046O0004000600024O00058O00033O00024O0002000200034O000200028O00017O00043O00028O0003063O00612O736572742O033O00737562026O00F03F02163O00125C010300014O00B9000400043O0026C60003000200010001000405012O0002000100121F000500024O003001065O00202O00073O000300122O000900043O00122O000A00046O0007000A00024O0006000600074O00078O0005000700024O000400056O000500044O005200066O0022010700016O00088O00058O00055O00044O000200012O00113O00017O00143O00028O00026O00084003013O007603063O0072657476616C026O00F03F027O0040034O0003063O00612O7365727403043O0067737562031B3O00D4FD1FF14E11E59A16D57D75A3FD1FA67E02A0F026F85D76AFB16E03063O005F8AD5448320031B3O0014609A517804278E71401762E80B4D6F169C09332860E80A332E6203053O00164A48C123031B3O001231DF4A2257EB771E4FD9126531DF1D1244AE1D2E42D911697DAE03043O00384C198403153O0060899034C170CE8414F9638BE26EEF1B9EE263CB1403053O00AF3EA1CB46031F3O005E285B726E4E6F4F52565D2A292840225B412D5A5D5B5E225D2B222925642A03303O000295F8013B12D2EC210301978A5B0E79E3FE590E3FD4D01F241FF4F03F043AD9E731237982E350706698892E7C79D98903053O00555CBDA37301733O00125C2O0100014O00B9000200063O0026C60001000800010002000405012O000800010026920103000700010003000405012O000700010010120002000400032O000B000200023O0026C60001000F00010005000405012O000F00012O00B9000400043O0006A800043O000100022O00523O00034O00523O00023O00125C2O0100063O0026C60001006B00010006000405012O006B00012O005200076O00B9000800084O0052000600084O0052000500073O0026920105006A00010007000405012O006A000100125C010700013O0026C60007002200010002000405012O0022000100121F000800083O000EBF0001001E00010006000405012O001E00012O006701096O0023010900014O0052000A6O008C0008000A0001000405012O001500010026C60007003900010001000405012O0039000100201E0108000500092O002E010A5O00122O000B000A3O00122O000C000B6O000A000C00024O000B00046O0008000B00094O000600096O000500083O0026C60006003800010001000405012O0038000100201E0108000500092O002E010A5O00122O000B000C3O00122O000C000D6O000A000C00024O000B00046O0008000B00094O000600096O000500083O00125C010700053O0026C60007005200010005000405012O005200010026C60006004600010001000405012O0046000100201E0108000500092O002E010A5O00122O000B000E3O00122O000C000F6O000A000C00024O000B00046O0008000B00094O000600096O000500083O0026C60006005100010001000405012O0051000100201E0108000500092O002E010A5O00122O000B00103O00122O000C00116O000A000C00024O000B00046O0008000B00094O000600096O000500083O00125C010700063O0026C60007001800010006000405012O001800010026C60006005C00010001000405012O005C000100201E0108000500090012A3010A00126O000B00046O0008000B00094O000600096O000500083O0026C60006006700010001000405012O0067000100201E0108000500092O002E010A5O00122O000B00133O00122O000C00146O000A000C00024O000B00046O0008000B00094O000600096O000500083O00125C010700023O000405012O00180001000405012O0015000100125C2O0100023O0026C60001000200010001000405012O000200012O007700076O0052000200074O00B9000300033O00125C2O0100053O000405012O000200012O00113O00013O00013O00073O00028O00026O00F03F034O0003043O0066696E6403013O007203053O007461626C6503063O00696E73657274021C3O00125C010200013O0026C60002000500010002000405012O0005000100125C010300034O000B000300023O0026C60002000100010001000405012O0001000100201E01033O000400125C010500054O00020103000500020006E50003000F00013O000405012O000F000100125C010300054O0052000400014O00ED0001000300042O009D00035O0006500103001400010001000405012O001400012O00A600015O000405012O0019000100121F000300063O0020590103000300072O009D000400014O0052000500014O008C00030005000100125C010200023O000405012O000100012O00113O00017O00093O00028O0003083O007661726961646963026O00F03F03043O0066696E6403073O00179775236CE40D03043O005849CC5003063O0072657476616C03073O0010B8555D6C921303063O00BA4EE3702649012C3O00125C2O0100013O0026C60001001900010001000405012O0019000100205901023O00020006E50002000800013O000405012O000800012O0023010200014O000B000200023O00125C010200034O005F00035O00125C010400033O0004880002001800012O003C00063O00050020800106000600044O00085O00122O000900053O00122O000A00066O0008000A6O00063O000200062O0006001700013O000405012O001700012O0023010600014O000B000600023O00041F0102000C000100125C2O0100033O0026C60001000100010003000405012O0001000100205901023O00070006E50002002B00013O000405012O002B000100205901023O00070020800102000200044O00045O00122O000500083O00122O000600096O000400066O00023O000200062O0002002B00013O000405012O002B00012O0023010200014O000B000200023O000405012O002B0001000405012O000100012O00113O00017O001B3O00028O0003063O0072657476616C026O00F03F03043O0066696E6403073O00C26CB84E1632C103063O001A9C379D353303073O00B2E353C2FD18B103063O0030ECB876B9D8027O0040026O001040030C3O00A0AE1775DC74ADF84475DC7D03063O005485DD3750AF030D3O00F8F464EE8D15FDAF61B5824FF403063O003CDD8744C6A7026O00084003043O00F8B2F18703063O00B98EDD98E32203083O00766172696164696303053O00148519B40D03073O009738A5379A23532O033O00EE0D4B03043O008EC02365034O0003053O007461626C6503063O00636F6E63617403023O009A3503083O0076B61549C387ECCC03833O00125C010300014O00B9000400083O0026C60003000700010001000405012O0007000100205901043O00022O005F00055O00125C010300033O0026C60003002D00010003000405012O002D00010006E50002002A00013O000405012O002A000100125C010900013O000ECF0001000C00010009000405012O000C000100125C010A00034O005F000B5O00125C010C00033O000488000A001D00012O003C000E3O000D002080010E000E00044O00105O00122O001100053O00122O001200066O001000126O000E3O000200062O000E001C00013O000405012O001C00010020A20105000D000300041F010A001200010006E50004002A00013O000405012O002A000100201E010A000400042O005D000C5O00122O000D00073O00122O000E00086O000C000E6O000A3O000200062O000A002A00013O000405012O002A00012O00B9000400043O000405012O002A0001000405012O000C00012O007700096O0052000600093O00125C010300093O0026C6000300480001000A000405012O004800010006E50001003D00013O000405012O003D00012O009D000900014O009D000A5O00125C010B000B3O00125C010C000C4O0002010A000C00022O0070010B00046O000C00016O000D00076O000E00086O0009000E6O00095O00044O008200012O009D000900014O0029000A5O00122O000B000D3O00122O000C000E6O000A000C00024O000B00046O000C00076O000D00086O0009000D6O00095O00044O008200010026C60003006C0001000F000405012O006C00010006E50004005100013O000405012O005100012O009D000900024O0052000A00044O00270109000200020006420104005600010009000405012O005600012O009D00095O00125C010A00103O00125C010B00114O00020109000B00022O0052000400093O0006500102006A00010001000405012O006A000100205901093O00120006E50009006A00013O000405012O006A00012O005F000900063O000E912O01006400010009000405012O006400012O009D00095O00125C010A00133O00125C010B00144O00020109000B00020006420108006B00010009000405012O006B00012O009D00095O00125C010A00153O00125C010B00164O00020109000B00020006420108006B00010009000405012O006B000100125C010800173O00125C0103000A3O0026C60003000200010009000405012O0002000100125C010900034O0052000A00053O00125C010B00033O0004880009007700012O009D000D00024O003C000E3O000C2O0027010D000200022O00380006000C000D00041F01090072000100121F000900183O0020590109000900192O0052000A00064O0066010B5O00122O000C001A3O00122O000D001B6O000B000D6O00093O00024O000700093O00122O0003000F3O000405012O000200012O00113O00017O00043O0003063O0072657476616C03013O007603053O007461626C6503063O00636F6E636174010B3O0020592O013O00010006502O01000400010001000405012O0004000100125C2O0100023O00121F000200033O0020A10102000200044O00038O0002000200024O0001000100024O000100028O00019O002O0001054O001400018O00028O000100026O00019O0000017O00053O00028O00026O00F03F03053O007063612O6C03063O00747970656F6603183O00637479706520652O726F7220666F7220222573223A20257301173O00125C2O0100014O00B9000200033O0026C60001000500010002000405012O000500012O000B000300023O000ECF0001000200010001000405012O0002000100121F000400034O002D01055O00202O0005000500044O00068O0004000600054O000300056O000200046O000400016O000500023O00122O000600056O00076O0052000800034O008C00040008000100125C2O0100023O000405012O000200012O00113O00017O00063O00028O0003053O000B3E25431003073O009D685C7A20646D03023O00A0B203083O00CBC3C6AFAA5D47ED026O00F03F03213O00125C010300014O00B9000400053O0026C60003001B00010001000405012O001B00012O009D00065O00125C010700023O00125C010800034O00020106000800020006420104000F00010006000405012O000F00012O009D00065O00125C010700043O00125C010800054O00020106000800022O0052000400064O003C00063O00040006420105001A00010006000405012O001A00012O009D000600014O00E4000700026O00088O000900016O000A00026O0007000A6O00063O00024O000500063O00125C010300063O0026C60003000200010006000405012O000200012O00383O000400052O000B000500023O000405012O000200012O00113O00017O00133O00028O00026O00F03F03053O007072696E7403043O006361737403063O00747970656F662O033O0007660E03073O009C4E2B5EB53171027O0040030D3O006F626A635F676574436C612O7303103O0073656C5F72656769737465724E616D6503063O00737472696E6703163O006D6574686F645F67657454797065456E636F64696E6703173O00636C612O735F676574496E7374616E63654D6574686F642O033O006E657703063O005BC5F4985A7E03073O00191288A4C36B23030F3O004D53482O6F6B4D652O7361676545782O033O00C1009903083O00D8884DC92F12DCA103593O00125C010300014O00B90004000A3O000ECF0002002000010003000405012O002000012O009D000B6O0072000C00076O000D000D6O000E8O000B000E00024O0008000B3O00122O000B00036O000C00086O000B000200014O000B00013O00202O000B000B00042O009D000C00013O002078000C000C00054O000D00086O000C000200024O000D00026O000B000D00024O0009000B6O000B00013O00202O000B000B00044O000C00023O00122O000D00063O00125C010E00074O0003010C000E00024O000D00096O000B000D00024O0009000B3O00122O000300083O0026C60003003D00010001000405012O003D00012O009D000B00033O00206C000B000B00094O000C8O000B000200024O0004000B6O000B00033O00202O000B000B000A4O000C00016O000B000200024O0005000B6O000B00013O00202O000B000B000B4O000C00033O00202O000C000C000C4O000D00033O00202O000D000D000D4O000E00046O000F00056O000D000F6O000C8O000B3O00024O0006000B6O000B00046O000C00066O000B000200024O0007000B3O00122O000300023O0026C60003000200010008000405012O000200012O009D000B00013O002073000B000B000E4O000C00023O00122O000D000F3O00122O000E00106O000C000E6O000B3O00024O000A000B6O000B00033O00202O000B000B00114O000C00046O000D00056O000E00096O000F000A6O000B000F00014O000B00013O00202O000B000B00044O000C00023O00122O000D00123O00122O000E00136O000C000E000200202O000D000A00014O000B000D6O000B5O00044O000200012O00113O00017O00013O0003063O0072656E616D6502083O00121F000200014O003C0002000200012O003C000200023O0006500102000600010001000405012O000600012O005200026O000B000200024O00113O00017O000A3O00028O0003083O006C6F612O6465707303053O007063612O6C030E3O006C6F61645F6672616D65776F726B03043O0070617468026O00F03F03043O000C86E8BA03043O00DE60E98903023O00FCA003073O0090D9D3C77FE89301213O00125C2O0100014O00B9000200033O000ECF0001000F00010001000405012O000F000100121F000400023O0006500104000800010001000405012O000800012O00113O00013O00121F000400033O001272010500043O00202O00063O00054O0004000600054O000300056O000200043O00122O000100063O0026C60001000200010006000405012O000200010006500102002000010001000405012O002000012O009D00046O0097010500013O00122O000600073O00122O000700086O0005000700024O000600013O00122O000700093O00122O0008000A6O0006000800024O000700036O000400070001000405012O00200001000405012O000200012O00113O00017O00053O0003063O0072617773657403043O006E616D6503063O0069A8207D883203083O00EB1ADC5214E6551B03053O0076616C7565010C3O0012372O0100016O00028O000300013O00202O00043O00024O000500023O00122O000600033O00122O000700046O000500076O00033O000200202O00043O00054O0001000400016O00017O000B3O00028O00026O00F03F03063O0072617773657403043O006E616D6503043O008DAFFCCF03053O0014E8C189A203083O00746F6E756D62657203063O0069676E6F726503043O0036CDD0A303083O001142BFA5C687EC7703053O0076616C756501273O00125C2O0100014O00B9000200023O0026C60001001500010002000405012O001500010006500102000700010001000405012O000700012O00113O00013O00121F000300034O00F200048O000500013O00202O00063O00044O000700023O00122O000800053O00122O000900066O000700096O00053O000200122O000600076O000700024O003B000600074O004C00033O0001000405012O00260001000ECF0001000200010001000405012O0002000100205901033O00082O0035010400023O00122O000500093O00122O0006000A6O00040006000200062O0003001F00010004000405012O001F00012O00113O00014O009D000300034O003C00033O00030006420102002400010003000405012O0024000100205901023O000B00125C2O0100023O000405012O000200012O00113O00017O000B3O00028O0003043O006E616D6503063O0008A3A111FEE403083O00B16FCFCE739F888C026O00F03F03043O0074797065027O004003063O0002851F16D54303073O003F65E97074B42F03053O008628AD57EB03063O0056A35B8D729803393O00125C010300014O00B9000400063O0026C60003001400010001000405012O001400012O009D00075O00208B01083O00024O000900016O0007000900024O000400076O000700016O000800046O000900023O00122O000A00033O00122O000B00046O0009000B6O00073O000200062O0007001300013O000405012O001300012O00113O00013O00125C010300053O0026C60003001F00010005000405012O001F00012O009D000700034O003C00073O00070006420105001B00010007000405012O001B000100205901053O00060006500105001E00010001000405012O001E00012O00113O00013O00125C010300073O000ECF0007000200010003000405012O000200012O009D000700044O00FC000800056O000900046O000A00026O0007000A00024O000600074O0028010700056O000800046O000900023O00122O000A00083O00122O000B00096O0009000B00022O00DD000A00066O000B00023O00122O000C000A3O00122O000D000B6O000B000D00024O000C00016O000D00066O000A000D6O00073O000100044O00380001000405012O000200012O00113O00017O00023O0003053O0050047A602E03053O005A336B141301084O00CE00018O00028O000300013O00122O000400013O00122O000500026O000300056O00013O00016O00017O00073O0003073O0099E995EA3988F603053O005DED90E58F03063O006F706171756503043O0001E4E51C03063O0026759690796B03043O002EBFEB3C03043O005A4DDB8E01164O00282O018O00028O000300013O00122O000400013O00122O000500026O00030005000200203C01043O00034O000500013O00122O000600043O00122O000700056O00050007000200062O0004001300010005000405012O001300012O009D000400013O00125C010500063O00125C010600074O00020104000600020006500104001400010001000405012O001400012O00B9000400044O008C0001000400012O00113O00017O00043O0003073O00F21D313C48027C03073O001A866441592C6703043O00F2E7352503053O00C491835043010C4O00282O018O00028O000300013O00122O000400013O00122O000500026O0003000500022O008A000400013O00122O000500033O00122O000600046O000400066O00013O00012O00113O00017O00023O0003073O000AA9160D1CED1803063O00887ED066687801084O00CE00018O00028O000300013O00122O000400013O00122O000500026O000300056O00013O00016O00017O001E3O00028O0003103O0066756E6374696F6E5F706F696E74657203043O006C98DB4603083O003118EAAE23CF325D03043O0074797065026O00F03F027O00402O033O000DE0FA03053O00116C929DE803063O0059C600FB2EA403063O00C82BA3748D4F03063O00AD332995B1F803073O0083DF565DE3D09403063O00F140A2A01CB903063O00D583252OD67D03063O00342E31A9E02A03053O0081464B45DF03013O007603023O00667003063O0054CEE7FF7DE303063O008F26AB93891C03063O00C287ADE502EF03073O00B4B0E2D993638303073O00DAAA2D0BDCBA2403043O0067B3D94F03023O006AE803073O00C32AD77CB521EC03073O006973626C6F636B03023O00334F03063O00986D39575E4503AB3O00125C010300014O00B9000400053O0026C60003001200010001000405012O001200010020590106000100022O007101075O00122O000800033O00122O000900046O00070009000200062O0006000C00010007000405012O000C00012O00113O00014O009D000600014O003C0006000100060006420104001100010006000405012O0011000100205901040001000500125C010300063O0026C60003008D00010007000405012O008D00012O0052000600024O005200076O0055010600020008000405012O008A00012O009D000B5O00125C010C00083O00125C010D00094O0002010B000D000200062B000900240001000B000405012O002400012O009D000B5O00125C010C000A3O00125C010D000B4O0002010B000D00020006D90009008A0001000B000405012O008A000100125C010B00014O00B9000C000C3O000ECF0001005E0001000B000405012O005E00010006E50005005700013O000405012O0057000100125C010D00014O00B9000E000E3O000ECF0001002C0001000D000405012O002C00012O009D000F00014O003C000F000A000F000642010E00330001000F000405012O00330001002059010E000A0005000650010E003700010001000405012O003700012O00B9000500053O000405012O0057000100125C010F00014O00B9001000103O0026C6000F003900010001000405012O003900012O009D00115O00125C0112000C3O00125C0113000D4O00020111001300020006D90009004700010011000405012O004700012O009D00115O00125C0112000E3O00125C0113000F4O00020111001300020006420110004A00010011000405012O004A00012O005F001100053O00206C01110011000600206C0110001100012O009D00115O00125C011200103O00125C011300114O00020111001300020006D90010005200010011000405012O00520001002692010E005700010012000405012O005700012O003800050010000E000405012O00570001000405012O00390001000405012O00570001000405012O002C00012O009D000D00026O000E00096O000F000A6O001000026O000D001000024O000C000D3O00122O000B00063O0026C6000B002600010006000405012O002600010006E50005008200013O000405012O008200010006E5000C008200013O000405012O0082000100125C010D00014O00B9000E000E3O0026C6000D006B00010006000405012O006B0001002059010F000500132O0038000F000E000C000405012O008200010026C6000D006600010001000405012O006600012O009D000F5O00125C011000143O00125C011100154O0002010F001100020006D9000900790001000F000405012O007900012O009D000F5O00125C011000163O00125C011100174O0002010F00110002000642010E007B0001000F000405012O007B00012O005F000F00053O00206C010E000F0006002059010F00050013000650010F007F00010001000405012O007F00012O0077000F5O00101200050013000F00125C010D00063O000405012O006600012O0052000D00024O0052000E00094O0055010D0002000F000405012O008600010006D5000D008600010001000405012O00860001000405012O008A0001000405012O002600010006D50006001800010002000405012O001800012O000B000500023O0026C60003000200010006000405012O000200012O007700063O00012O009D00075O00125C010800183O00125C010900194O00020107000900022O007101085O00122O0009001A3O00122O000A001B6O0008000A000200062O0004009D00010008000405012O009D00012O00B9000800083O000405012O009E00012O006701086O0023010800014O00380006000700082O0052000500063O00205901060005001C0006E5000600A800013O000405012O00A800012O009D00065O00125C0107001D3O00125C0108001E4O000201060008000200101200050006000600125C010300073O000405012O000200012O00113O00017O00053O00028O00026O00F03F03063O007261777365740003093O006C617A7966756E637303233O00125C010300014O00B9000400043O0026C60003001A00010002000405012O001A00010006A800043O000100092O009D8O00528O009D3O00014O009D3O00024O00523O00014O009D3O00034O009D3O00044O009D3O00054O009D3O00063O0006E50002001700013O000405012O0017000100121F000500034O009D000600044O005200075O0006A800080001000100012O00523O00044O008C000500080001000405012O002200012O0052000500044O004F000500010001000405012O002200010026C60003000200010001000405012O000200010026C60002001F00010004000405012O001F000100121F000200054O00B9000400043O00125C010300023O000405012O000200012O00113O00013O00023O000A3O00028O0003063O00FEDB05A1BFDE03083O00C899B76AC3DEB234026O00F03F027O004003063O0072617773657403063O0021FA853F465603063O003A5283E85D2903163O008E5EC30654318417F3555B2A8D54C41C5231D917950603063O005FE337B0753D00383O00125C012O00014O00B9000100023O0026C63O001400010001000405012O001400012O009D00036O00F5000400016O000500023O00122O000600023O00122O000700036O0005000700024O000600036O000700046O000800016O000600086O00033O00012O009D000300054O009D000400014O00270103000200022O0052000100033O00125C012O00043O0026C63O001C00010005000405012O001C000100121F000300064O0026010400066O000500016O000600026O0003000600014O000200023O0026C63O000200010004000405012O000200010006502O01003000010001000405012O0030000100125C010300013O000ECF0001002100010003000405012O002100012O009D000400074O0048010500023O00122O000600073O00122O000700086O0005000700024O000600023O00122O000700093O00122O0008000A6O0006000800024O000700016O0004000700012O00113O00013O000405012O002100012O009D000300084O0018010400046O000500016O0003000500024O000200033O00124O00053O00044O000200012O00113O00017O00023O00028O00026O00F03F00133O00125C2O0100014O00B9000200023O0026C60001000B00010001000405012O000B00012O009D00036O00D30003000100022O0052000200033O0006500102000A00010001000405012O000A00012O00113O00013O00125C2O0100023O000ECF0002000200010001000405012O000200012O0052000300024O005A00046O009B00036O008101035O000405012O000200012O00113O00017O001C3O00028O0003043O006E616D6503083O00F73043ECCDF82A4303053O00B991452D8F03063O008D1316A4DD8603053O00BCEA7F79C6026O00F03F03083O002E33018A39361A8003043O00E358527303083O00766172696164696303043O00570DAFA203063O0013237FDAC76203083O001AEE04E108F205EC03043O00827C9B6A2O033O00D4D9F103083O00DFB5AB96CFC3961C03063O005E3FF7B8084003053O00692C5A83CE03043O007479706503023O00667003063O00EDE5A6AF093203063O005E9F80D2D96803063O0042FC12A95E7303083O001A309966DF3F1F9903063O001045F9E5034C03043O009362208D03013O0076027O004002913O00125C010200014O00B9000300043O000ECF0001001700010002000405012O001700012O009D00055O00208C01063O00024O000700013O00122O000800033O00122O000900046O000700096O00053O00024O000300056O000500026O000600036O000700013O00122O000800053O00122O000900066O000700096O00053O000200062O0005001600013O000405012O001600012O00113O00013O00125C010200073O0026C60002008600010007000405012O008600012O007700053O00012O009D000600013O00125C010700083O00125C010800094O000201060008000200203C01073O000A4O000800013O00122O0009000B3O00122O000A000C6O0008000A000200062O0007002800010008000405012O002800012O00B9000700073O000405012O002900012O006701076O0023010700014O00380005000600072O00EC000400056O000500016O000600013O00122O0007000D3O00122O0008000E6O000600086O00053O000700044O008300010006E50004008300013O000405012O008300012O009D000A00013O00125C010B000F3O00125C010C00104O0002010A000C000200062B000800400001000A000405012O004000012O009D000A00013O00125C010B00113O00125C010C00124O0002010A000C00020006D9000800830001000A000405012O0083000100125C010A00014O00B9000B000B3O0026C6000A004200010001000405012O004200012O009D000C00034O003C000C0009000C000642010B00490001000C000405012O00490001002059010B00090013000650010B004D00010001000405012O004D00012O00B9000400043O000405012O0083000100125C010C00014O00B9000D000E3O000ECF000700660001000C000405012O006600012O009D000F00044O0022001000086O001100096O001200016O000F001200024O000E000F3O00062O000E008300013O000405012O0083000100125C010F00013O000ECF0001005A0001000F000405012O005A00010020590110000400140006500110006000010001000405012O006000012O007700105O0010120004001400100020590110000400142O00380010000D000E000405012O00830001000405012O005A0001000405012O008300010026C6000C004F00010001000405012O004F00012O009D000F00013O00125C011000153O00125C011100164O0002010F001100020006D9000800740001000F000405012O007400012O009D000F00013O00125C011000173O00125C011100184O0002010F00110002000642010D00760001000F000405012O007600012O005F000F00043O00206C010D000F00072O009D000F00013O00125C011000193O00125C0111001A4O0002010F001100020006D9000D007E0001000F000405012O007E0001002692010B007F0001001B000405012O007F00012O00380004000D000B00125C010C00073O000405012O004F0001000405012O00830001000405012O004200010006D50005003200010002000405012O0032000100125C0102001C3O0026C6000200020001001C000405012O000200010006E50004009000013O000405012O009000012O009D000500054O0052000600034O0052000700044O008C000500070001000405012O00900001000405012O000200012O00113O00017O000B3O00028O0003043O006E616D6503113O00114DE5C5145B4A147CF3D80942441B4CEF03073O002B782383AA663603063O00590393BEAAB403073O00E43466E7D6C5D003043O007479706503083O0073656C6563746F72030C3O00636C612O735F6D6574686F6403043O000AF260CF03083O00B67E8015AA8AEB7902373O00125C010200014O00B9000300033O0026C60002000200010001000405012O000200012O009D00045O00206B00053O00024O0004000200024O000300046O000400016O000500013O00122O000600033O00122O000700046O000500076O00043O000600044O003200010006E50003003200013O000405012O003200012O009D000900013O00125C010A00053O00125C010B00064O00020109000B00020006D90007003200010009000405012O0032000100125C010900014O00B9000A000A3O0026C60009001900010001000405012O001900012O009D000B00024O003C000B0008000B000642010A00200001000B000405012O00200001002059010A000800070006E5000A003200013O000405012O003200012O009D000B00034O00AE000C00033O00202O000D0008000800202O000E000800094O000F00013O00122O0010000A3O00122O0011000B6O000F0011000200062O000E002D0001000F000405012O002D00012O0067010E6O0023010E00014O0052000F000A4O008C000B000F0001000405012O00320001000405012O001900010006D50004000F00010002000405012O000F0001000405012O00360001000405012O000200012O00113O00017O00233O00028O00026O00F03F03043O006E616D6503053O0088D634F59503083O0066EBBA5586E6735003063O005A092A577DD003073O0042376C5E3F12B4027O004003063O001988913F285D03063O003974EDE557472O033O00ABA3EA03073O0027CAD18D87178E03063O00ED361D1C33F403063O00989F53696A5203063O0093C345E4C85003063O003CE1A63192A903013O004203063O0072657476616C03023O00667003043O007479706503063O003D1B3B3C000B03063O00674F7E4F4A6103063O00A87AC7655F1603063O007ADA1FB3133E03053O00696E64657803043O006E657874030C3O00636C612O735F6D6574686F6403043O00A7C4D8C403073O0025D3B6ADA1A9C103083O00766172696164696303043O00E32858DC03073O00D9975A2DB9481B03083O0073656C6563746F723O010002B63O00125C010200014O00B9000300053O0026C60002000900010001000405012O000900012O007700066O0052000300064O007700066O0052000400063O00125C010200023O0026C6000200A100010002000405012O00A1000100205901053O00032O0052000600014O007F01075O00122O000800043O00122O000900056O000700096O00063O000800044O009E00012O009D000B5O00125C010C00063O00125C010D00074O0002010B000D00020006D90009009E0001000B000405012O009E000100125C010B00014O00B9000C000E3O0026C6000B007F00010008000405012O007F00012O0052000F00014O007F01105O00122O001100093O00122O0012000A6O001000126O000F3O001100044O007000010006E5000C007000013O000405012O007000012O009D00145O00125C0115000B3O00125C0116000C4O000201140016000200062B0012003200010014000405012O003200012O009D00145O00125C0115000D3O00125C0116000E4O00020114001600020006D90012007000010014000405012O0070000100125C011400014O00B9001500173O0026C60014004600010002000405012O004600012O009D00185O00125C0119000F3O00125C011A00104O00020118001A00020006D90012003F00010018000405012O003F00010026C60015003F00010011000405012O003F0001003020010C001200112O009D001800016O001900126O001A00136O001B00016O0018001B00024O001700183O00122O001400083O0026C60014005700010008000405012O005700010006E50017007000013O000405012O0070000100125C011800013O0026C60018004B00010001000405012O004B00010020590119000C00130006500119005100010001000405012O005100012O007700195O001012000C001300190020590119000C00132O0038001900160017000405012O00700001000405012O004B0001000405012O007000010026C60014003400010001000405012O003400012O009D001800024O003C0018001300180006420115005E00010018000405012O005E00010020590115001300142O009D00185O00125C011900153O00125C011A00164O00020118001A00020006D90012006A00010018000405012O006A00012O009D00185O00125C011900173O00125C011A00184O00020118001A00020006420116006E00010018000405012O006E000100205901180013001900206C01180018000200206C01180018000100206C01160018000800125C011400023O000405012O003400010006D5000F002400010002000405012O002400010006E5000C009E00013O000405012O009E000100121F000F001A4O00520010000C4O0027010F000200020006E5000F009E00013O000405012O009E00010006E5000D007D00013O000405012O007D00012O00380003000E000C000405012O009E00012O00380004000E000C000405012O009E00010026C6000B008D00010001000405012O008D00012O0077000F6O0087000C000F3O00202O000F000A001B4O00105O00122O0011001C3O00122O0012001D6O00100012000200062O000F008B00010010000405012O008B00012O0067010D6O0023010D00013O00125C010B00023O0026C6000B001B00010002000405012O001B0001002059010F000A001E2O007101105O00122O0011001F3O00122O001200206O00100012000200062O000F009900010010000405012O009900012O00B9000F000F3O000405012O009A00012O0067010F6O0023010F00013O001012000C001E000F002059010E000A002100125C010B00083O000405012O001B00010006D50006001300010002000405012O0013000100125C010200083O0026C60002000200010008000405012O0002000100121F0006001A4O0052000700034O00270106000200020006E5000600AB00013O000405012O00AB00012O009D000600033O0020590106000600222O003800060005000300121F0006001A4O0052000700044O00270106000200020006E5000600B500013O000405012O00B500012O009D000600033O0020590106000600232O0038000600050004000405012O00B50001000405012O000200012O00113O00017O00013O00028O00030D3O00125C010300014O00B9000400043O000ECF0001000200010003000405012O000200012O009D00056O003C0005000500022O003C000400053O0006610105000A00010004000405012O000A00012O003C0005000400012O000B000500023O000405012O000200012O00113O00017O00053O00028O0003043O006E616D6503083O006F726967696E616C026O00F03F03063O0072617773657401143O00125C2O0100014O00B9000200033O0026C60001000700010001000405012O0007000100205901023O000200205901033O000300125C2O0100043O0026C60001000200010004000405012O0002000100121F000400054O009D00056O0052000600023O0006A800073O000100032O009D8O00523O00034O00523O00024O008C000400070001000405012O00130001000405012O000200012O00113O00013O00013O00033O00028O00026O00F03F03063O0072617773657400153O00125C2O0100014O00B9000200023O0026C60001000800010002000405012O000800012O0052000300024O005A00046O009B00036O008101035O0026C60001000200010001000405012O000200012O009D00036O0048000400016O00020003000400122O000300036O00048O000500026O000600026O00030006000100122O000100023O00044O000200012O00113O00017O00053O00028O00027O0040030A3O00D075E01C57D769F5174503053O0036A31C8772026O00F03F01263O00125C2O0100014O00B9000200033O000ECF0002001700010001000405012O001700012O0052000400034O007F01055O00122O000600033O00122O000700046O000500076O00043O000600044O001400012O009D000900014O003C0009000900070006E50009001400013O000405012O001400012O009D000900014O003C0009000900072O0052000A00084O0052000B00034O008C0009000B00010006D50004000B00010002000405012O000B0001000405012O002500010026C60001001D00010005000405012O001D00012O00B9000300033O0006A800033O000100012O00523O00023O00125C2O0100023O0026C60001000200010001000405012O000200012O00B9000200023O0006A800020001000100022O00528O00523O00023O00125C2O0100053O000405012O000200012O00113O00013O00027O0001044O009D00016O005200026O00E0000100034O00113O00017O00023O00028O00026O00F03F011E3O00125C2O0100014O00B9000200043O0026C60001000700010002000405012O000700012O0052000500034O0052000600044O00E0000500033O0026C60001000200010001000405012O000200012O009D00056O00620105000100074O000400076O000300066O000200053O00062O0002001B00010001000405012O001B000100125C010500013O0026C60005001100010001000405012O001100010006D90003001600013O000405012O001600012O00113O00014O009D000600014O005200076O00AA010600074O008101065O000405012O0011000100125C2O0100023O000405012O000200012O00113O00017O000B3O00028O0003063O00612O7365727403023O00696F03043O006F70656E03023O003AD903063O001F48BB3DE22E03043O007265616403023O00890703073O0044A36623B2271E026O00F03F03053O00636C6F7365011E3O00125C2O0100014O00B9000200033O0026C60001001700010001000405012O0017000100121F000400023O001237000500033O00202O0005000500044O00068O00075O00122O000800053O00122O000900066O000700096O00058O00043O00024O000200043O00201E0104000200072O006601065O00122O000700083O00122O000800096O000600086O00043O00024O000300043O00122O0001000A3O0026C6000100020001000A000405012O0002000100201E01040002000B2O00940104000200012O000B000300023O000405012O000200012O00113O00017O000D3O00028O0003063O00676D61746368031F3O003C282F3F29285B25615F5D5B25775F5D2A29285B5E2F3E5D2A29282F3F293E03013O002F031E3O00285B25615F5D5B25775F5D2A293D5B22275D285B5E22275D2A295B22275D03043O0066696E6403063O00F861CFC817EE03083O0071DE10BAA763D5E3026O00F03F03043O006773756203063O00681FEEF93A5503043O00964E6E9B03013O0022024C3O00125C010200014O00B9000300033O0026C60002000200010001000405012O000200012O009D00046O007901058O0004000200024O000300043O00202O00040003000200122O000600036O00040006000600044O004700010026C60007001300010004000405012O001300012O0052000B00014O0023010C6O0052000D00084O008C000B000D0001000405012O0047000100125C010B00014O00B9000C000C3O0026C6000B003800010001000405012O003800012O0077000D6O009C000C000D3O00202O000D0009000200122O000F00056O000D000F000F00044O0035000100125C011200013O000ECF0001001E00010012000405012O001E000100201E0113001100062O0088011500013O00122O001600073O00122O001700086O00150017000200122O001600096O001700016O00130017000200062O0013003200013O000405012O0032000100201E01130011000A2O003A001500013O00122O0016000B3O00122O0017000C6O00150017000200122O0016000D6O0013001600024O001100134O0038000C00100011000405012O00350001000405012O001E00010006D5000D001D00010002000405012O001D000100125C010B00093O0026C6000B001500010009000405012O001500012O0052000D00014O0063010E00016O000F00086O0010000C6O000D0010000100262O000A004700010004000405012O004700012O0052000D00014O0023010E6O0052000F00084O008C000D000F0001000405012O00470001000405012O001500010006D50004000C00010004000405012O000C0001000405012O004B0001000405012O000200012O00113O00017O00103O00028O00026O00F03F03073O007573657870617403073O007265717569726503053O0080DD37E0B003083O0020E5A54781C47EDF03053O00706172736503043O00D388D08903063O00B5A3E9A42OE103093O00439F3F6544B42A765703043O001730EB5E03073O0079D4DC624332D503073O00B21CBAB83D375303093O00636F726F7574696E6503043O007772617003053O007969656C6402403O00125C010300014O00B9000400043O0026C60003003100010002000405012O0031000100121F000500033O0006E50005002C00013O000405012O002C000100125C010500014O00B9000600063O0026C60005000900010001000405012O0009000100121F000700044O00C900085O00122O000900053O00122O000A00066O0008000A6O00073O00024O000600073O00202O0007000600074O00083O00014O00095O00122O000A00083O00125C010B00094O00020109000B00022O0038000800094O007700093O00022O009D000A5O00125C010B000A3O00125C010C000B4O0002010A000C00020006A8000B3O000100012O00523O00044O00170109000A000B4O000A5O00122O000B000C3O00122O000C000D6O000A000C00020006A8000B0001000100012O00523O00044O00380009000A000B2O008C000700090001000405012O003F0001000405012O00090001000405012O003F00012O009D000500014O005200066O0052000700044O008C000500070001000405012O003F00010026C60003000200010001000405012O0002000100121F0005000E3O00207B00050005000F4O000600016O0005000200024O000400056O000500043O00122O0006000E3O00202O0006000600104O00078O00053O000100122O000300023O000405012O000200012O00113O00013O00027O0002064O003D01028O000300016O00048O000500016O0002000500016O00019O002O0001054O004100018O00028O00038O0001000300016O00019O002O0001054O003500018O00028O000300016O0001000300016O00017O00193O00028O0003043O0066696E6403023O005E2F03053O006D6174636803133O00285B5E2F5D2B29252E6672616D65776F726B24026O00F03F03083O00285B5E2F5D2B29242O033O00737562027O004003043O006773756203023O00818903073O0095A4AD275C926E030A3O00BD21021E171EE428021403063O007B9347707F7A030A3O00285B5E252E2F5D2B2924030B3O008983846347C1C8957E54C703053O0026ACADE21103023O00085503043O008F2D714C03023O00FDF603043O005C2OD87C03273O002E6672616D65776F726B2F56657273696F6E732F43752O72656E742F4672616D65776F726B732F03053O007061697273030F3O0025732F25732E6672616D65776F726B03273O002F53797374656D2F4C6962726172792F4672616D65776F726B732F25732E6672616D65776F726B018A3O00125C2O0100014O00B9000200023O0026C60001008300010001000405012O0083000100201E01033O000200125C010500034O00020103000500020006E50003003600013O000405012O0036000100125C010300014O00B9000400053O000ECF0001001300010003000405012O001300012O0052000400053O00207401060004000400122O000800056O0006000800024O000500063O00122O000300063O000ECF0006000B00010003000405012O000B00010006500105002900010001000405012O0029000100125C010600013O0026C60006001800010001000405012O0018000100201E01070004000400125C010900074O00020107000900022O0052000500073O0006610104002700010005000405012O0027000100201E010700040008001262000900066O000A00056O000A000A3O00202O000A000A00094O0007000A00024O000400073O000405012O00290001000405012O001800010006E50005007D00013O000405012O007D00012O009D00066O0052000700044O00270106000200020006E50006007D00013O000405012O007D00012O0052000600044O0052000700054O00E0000600033O000405012O007D0001000405012O000B0001000405012O007D000100125C010300014O00B9000400043O000ECF0006004A00010003000405012O004A000100201E01050004000A2O0087010700013O00122O0008000B3O00122O0009000C6O0007000900024O000800013O00122O0009000D3O00122O000A000E6O0008000A6O00053O00024O000400053O00207401053O000400122O0007000F6O0005000700026O00053O00122O000300093O0026C60003006000010001000405012O0060000100201E01053O000A2O007E010700013O00122O000800103O00122O000900116O0007000900024O000800013O00122O000900123O00122O000A00136O0008000A6O00053O00024O000400053O00202O00050004000A4O000700013O00122O000800143O00122O000900156O00070009000200122O000800166O0005000800024O000400053O00122O000300063O0026C60003003800010009000405012O0038000100121F000500174O009D000600024O0055010500020007000405012O0079000100125C010A00013O0026C6000A006700010001000405012O006700012O009D000B00033O001253010C00186O000D00096O000E00046O000B000E00024O0009000B6O000B8O000C00096O000B0002000200062O000B007900013O000405012O007900012O0052000B00094O0052000C6O00E0000B00033O000405012O00790001000405012O006700010006D50005006600010002000405012O00660001000405012O007D0001000405012O003800012O009D000300033O001243000400196O00058O0003000500024O000200033O00122O000100063O000ECF0006000200010001000405012O000200012O0052000300024O005200046O00E0000300033O000405012O000200012O00113O00017O001B3O00028O00026O00F03F03163O005D20AD4DF84C3DBE4BBD553DB800FB5427A244BD1E2103053O009D3B52CC2003063O006C6F6164656403053O0025732F257303043O006C6F6164027O004003043O003431E2FE03083O00D1585E839A898AB303023O006DB203083O004248C1A41C7E43512O0103233O0025732F5265736F75726365732F42726964676553752O706F72742F25732E64796C696203023O006F7303053O00C838A05D3403063O0016874CC8384603053O00652O726F7203103O009D3CF9305BEE9F3DB82A52F5CD1FCB1C03063O0081ED5098443D030E3O0066696E645F6672616D65776F726B03093O006C6F6164747970657303073O005FA710EA0C124B03073O003831C864937C7703093O006C6F616465645F6273032B3O0025732F5265736F75726365732F42726964676553752O706F72742F25732E62726964676573752O706F727403123O006C6F61645F62726964676573752O706F727402853O00125C010200014O00B9000300043O0026C60002004500010002000405012O004500012O009D00056O004B000600036O000700013O00122O000800033O00122O000900046O0007000900024O00088O00050008000100122O000500056O00050005000300062O0005004400010001000405012O0044000100125C010500014O00B9000600063O0026C60005002000010001000405012O002000012O009D000700023O001244010800066O000900036O000A00046O0007000A00024O000600076O000700033O00202O0007000700074O000800066O000900016O00070009000100122O000500023O0026C60005003000010008000405012O003000012O009D000700044O00D2000800013O00122O000900093O00122O000A000A6O0008000A00024O000900013O00122O000A000B3O00122O000B000C6O0009000B00024O000A00036O0007000A000100122O000700053O00202O00070003000D00044O004400010026C60005001200010002000405012O001200012O009D000700023O0012530108000E6O000900036O000A00046O0007000A00024O000600076O000700056O000800066O00070002000200062O0007004200013O000405012O004200012O009D000700033O0020590107000700072O0052000800064O0023010900014O008C00070009000100125C010500083O000405012O0012000100125C010200083O0026C60002005F00010001000405012O005F00012O009D000500063O0006500105005900010001000405012O005900012O009D000500033O00203C01050005000F4O000600013O00122O000700103O00122O000800116O00060008000200062O0005005900010006000405012O0059000100121F000500124O00FE000600013O00122O000700133O00122O000800146O00060008000200122O000700086O00050007000100121F000500154O009F01068O0005000200064O000400066O000300053O00122O000200023O0026C60002000200010008000405012O0002000100121F000500163O0006E50005008400013O000405012O008400012O009D000500013O00125C010600173O00125C010700184O000201050007000200062B0001008400010005000405012O0084000100121F000500194O003C0005000500030006500105008400010001000405012O0084000100125C010500014O00B9000600063O0026C60005007B00010001000405012O007B000100121F000700193O0020E600070003000D2O009D000700023O00125C0108001A4O008B000900036O000A00046O0007000A00024O000600073O00122O000500023O0026C60005007000010002000405012O0070000100121F0007001B4O0052000800064O0094010700020001000405012O00840001000405012O00700001000405012O00840001000405012O000200012O00113O00017O000B3O00028O0003053O006D617463682O033O00F201F503043O0090AC5EDF03043O00677375622O033O001A30E803043O0027446FC2034O0003013O005F03013O003A03103O0073656C5F72656769737465724E616D65011E3O00125C2O0100013O0026C60001000100010001000405012O0001000100201E01023O00022O005B00045O00122O000500033O00122O000600046O000400066O00023O000200202O00033O00054O00055O00122O000600063O00122O000700076O00050007000200122O000600086O00030006000200202O00030003000500122O000500093O00122O0006000A6O0003000600026O000200034O000200016O000300023O00202O00030003000B4O00048O000300046O00028O00025O00044O000100012O00113O00017O00043O00028O0003043O007479706503063O00C5B2F5CE77B003063O00D7B6C687A71901133O00125C2O0100013O0026C60001000100010001000405012O0001000100121F000200024O008901038O0002000200024O00035O00122O000400033O00122O000500046O00030005000200062O0002000D00010003000405012O000D00012O000B3O00024O009D000200014O005200036O00AA010200034O008101025O000405012O000100012O00113O00017O00023O0003063O00737472696E67030B3O0073656C5F6765744E616D6501094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000017O00013O0003153O006F626A635F636F707950726F746F636F6C4C697374000A4O006E9O00000100016O000200023O00202O0002000200014O000300036O000200036O00019O009O009O0000017O00013O0003103O006F626A635F67657450726F746F636F6C01084O00382O018O000200013O00202O0002000200014O00038O000200036O00018O00019O0000017O00023O0003063O00737472696E6703103O0070726F746F636F6C5F6765744E616D6501094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000017O00013O0003193O0070726F746F636F6C5F636F707950726F746F636F6C4C697374010B4O00992O018O000200016O000300023O00202O0003000300014O00048O000500056O000300056O00028O00018O00019O0000017O00013O0003193O0070726F746F636F6C5F636F707950726F70657274794C697374010B4O00992O018O000200016O000300023O00202O0003000300014O00048O000500056O000300056O00028O00018O00019O0000017O00013O0003143O0070726F746F636F6C5F67657450726F7065727479040B4O000B01048O000500013O00202O0005000500014O00068O000700016O000800026O000900036O000500096O00048O00049O0000017O00043O00028O0003223O0070726F746F636F6C5F636F70794D6574686F644465736372697074696F6E4C697374026O00F0BF026O00F03F031A3O00125C010300014O00B9000400053O0026C60003001000010001000405012O001000012O009D00066O00D1000700013O00202O0007000700024O00088O000900026O000A00016O000B000B6O0007000B6O00063O00024O000400063O00122O000500033O00122O000300043O0026C60003000200010004000405012O000200010006A800063O000100042O00523O00044O00523O00054O009D3O00024O009D3O00034O000B000600023O000405012O000200012O00113O00013O00013O00063O00028O00026O00F03F03043O006E616D650003063O00737472696E6703053O00747970657300243O00125C012O00013O0026C63O001800010002000405012O001800012O009D00016O009D000200014O003C0001000100020020592O01000100030026C60001000A00010004000405012O000A00012O00113O00014O009D000100025O0001028O000300016O00020002000300202O0002000200034O0001000200024O000200033O00202O0002000200054O00038O000400016O00030003000400202O0003000300064O000200036O00015O0026C63O000100010001000405012O000100012O009D000100013O00206C2O01000100022O00A6000100014O009D00015O0026C60001002100010004000405012O002100012O00113O00013O00125C012O00023O000405012O000100012O00113O00017O00073O00028O00026O00F03F03063O00737472696E6703053O007479706573031D3O0070726F746F636F6C5F6765744D6574686F644465736372697074696F6E03043O006E616D6500041A3O00125C010400014O00B9000500053O0026C60004000900010002000405012O000900012O009D00065O0020590106000600030020590107000500042O00AA010600074O008101065O0026C60004000200010001000405012O000200012O009D000600013O0020190106000600054O00078O000800016O000900036O000A00026O0006000A00024O000500063O00202O00060005000600262O0006001700010007000405012O001700012O00113O00013O00125C010400023O000405012O000200012O00113O00019O003O00074O00F100018O000200016O00038O00028O00018O00019O0000019O002O00050C4O004900058O000600016O00078O000800016O000900026O000A00036O0006000A00024O000700076O000800046O000500084O008101056O00113O00019O002O00050C4O004900058O000600016O00078O000800016O000900026O000A00036O0006000A00024O000700076O000800046O000500084O008101056O00113O00019O002O0001044O009D00016O003C000100014O000B000100024O00113O00017O00073O00028O00026O00F03F030C3O007365746D6574617461626C6503053O00248278391E03043O00547BEC1903083O00CF86AF03A4BAF49803063O00D590EBCA77CC01253O00125C2O0100014O00B9000200023O0026C60001000700010002000405012O000700012O009D00036O003800033O00022O000B000200023O0026C60001000200010001000405012O000200012O009D000300013O0006E50003001200013O000405012O001200012O009D000300024O005200046O00270103000200020006E50003001200013O000405012O001200012O00113O00013O00121F000300034O001E00043O00024O000500033O00122O000600043O00122O000700056O0005000700024O000400056O000500033O00122O000600063O00122O000700076O0005000700022O007700066O001A0004000500064O000500046O0003000500024O000200033O00122O000100023O00044O000200012O00113O00017O00053O0003083O005F6D6574686F647303053O001C11D0393C03073O002D4378BE4A484303063O001F2FF9BCE98D03083O008940428DC599E88E040E3O00204601043O00014O00053O00024O00065O00122O000700023O00122O000800036O0006000800024O0005000600024O00065O00122O000700043O00122O000800056O0006000800024O0005000600034O0004000100056O00017O00013O0003053O005F6E616D6501033O0020592O013O00012O000B000100024O00113O00019O003O00024O00113O00014O00113O00019O002O0001034O009D00016O000B000100024O00113O00019O002O0001034O009D00016O000B000100024O00113O00017O00033O00028O0003093O00636F726F7574696E6503043O007772617003103O00125C010300013O0026C60003000100010001000405012O000100010006E50002000700013O000405012O000700012O009D00046O000B000400023O00121F000400023O0020590104000400030006A800053O000100022O00528O00523O00014O00AA010400054O008101045O000405012O000100012O00113O00013O00013O00063O0003053O00706169727303083O005F6D6574686F647303053O005F696E737403093O00636F726F7574696E6503053O007969656C6403063O005F6D7479706500113O00127A012O00016O00015O00202O0001000100026O0002000200044O000E00010020590105000400032O009D000600013O0006D90005000E00010006000405012O000E000100121F000500043O0020590105000500052O0052000600033O0020590107000400062O008C0005000700010006D53O000500010002000405012O000500012O00113O00017O00053O00028O0003083O005F6D6574686F6473026O00F03F03053O005F696E737403063O005F6D74797065041B3O00125C010400014O00B9000500053O0026C60004000D00010001000405012O000D00010006E50003000700013O000405012O000700012O00113O00013O00205901063O00022O009900078O000800016O0007000200024O00050006000700122O000400033O0026C60004000200010003000405012O000200010006E50005001700013O000405012O001700010020590106000500040006D90006001700010002000405012O001700010020590106000500050006500106001800010001000405012O001800012O00B9000600064O000B000600023O000405012O000200012O00113O00017O00013O0003053O006D7479706501074O002F00025O00202O00033O00014O00058O00038O00028O00029O0000017O00013O0003053O006674797065050B4O007600055O00202O00063O00014O000800016O000900026O000A00036O0006000A00024O000700076O000800046O000500086O00056O00113O00017O00013O0003053O006674797065050B4O007600055O00202O00063O00014O000800016O000900026O000A00036O0006000A00024O000700076O000800046O000500086O00056O00113O00017O00023O0003093O00636F726F7574696E6503043O007772617000083O00121F3O00013O002059014O00020006A800013O000100022O009D8O009D3O00014O00AA012O00014O0081017O00113O00013O00013O00043O00028O0003093O00636F726F7574696E6503053O007969656C6403053O00706169727300193O00125C012O00013O0026C63O000100010001000405012O000100012O009D00016O00772O0100010003000405012O000A000100121F000500023O0020590105000500032O0052000600044O00940105000200010006D50001000600010001000405012O0006000100121F000100044O009D000200014O00552O0100020003000405012O0014000100121F000600023O0020590106000600032O0052000700054O00940106000200010006D50001001000010002000405012O00100001000405012O00180001000405012O000100012O00113O00017O00063O00028O0003043O007479706503063O0010C430AF860403053O00E863B042C603133O00F92F2308749AF76CFC332712748EF620AC643B03083O004C8C4148661BED99011F3O00125C2O0100013O0026C60001000100010001000405012O0001000100121F000200024O008901038O0002000200024O00035O00122O000400033O00122O000500046O00030005000200062O0002000D00010003000405012O000D00012O000B3O00024O009D000200014O009D000300024O005200046O00270103000200020006500103001600010001000405012O001600012O009D000300034O005200046O00270103000200022O009D00045O00126D000500053O00122O000600066O0004000600024O00058O000200056O00025O00044O000100012O00113O00017O00023O0003063O00737472696E6703103O0070726F70657274795F6765744E616D6501094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000017O00013O0003053O0073747970652O023O001012000100014O00113O00017O00013O0003043O00697661722O023O001012000100014O00113O00017O00013O0003063O0067652O7465722O023O001012000100014O00113O00017O00013O0003063O0073652O7465722O023O001012000100014O00113O00017O00023O0003083O00726561646F6E6C792O012O023O0030202O01000100022O00113O00017O00083O00028O00026O00F03F03013O002C03063O00676D61746368030B3O0002945F9AEC3FF277905F9E03073O00DE2ABA76B2B76103063O00737472696E6703163O0070726F70657274795F676574412O7472696275746573012E3O00125C2O0100014O00B9000200033O0026C60001001F00010002000405012O001F00012O0052000400023O001274000500036O00040004000500202O0004000400044O00065O00122O000700053O00122O000800066O000600086O00043O000600044O001C000100125C010900014O00B9000A000A3O0026C60009001000010001000405012O001000012O009D000B00014O003C000A000B00070006E5000A001C00013O000405012O001C00012O0052000B000A4O0052000C00084O0052000D00034O008C000B000D0001000405012O001C0001000405012O001000010006D50004000E00010002000405012O000E00012O000B000300023O0026C60001000200010001000405012O000200012O009D000400023O0020690004000400074O000500033O00202O0005000500084O00068O000500066O00043O00024O000200046O00048O000300043O00122O000100023O000405012O000200012O00113O00017O00033O00028O0003063O0067652O746572026O00F03F01163O00125C2O0100014O00B9000200023O0026C60001001000010001000405012O001000012O009D00036O005E00048O0003000200024O000200033O00202O00030002000200062O0003000F00010001000405012O000F00012O009D000300014O005200046O002701030002000200101200020002000300125C2O0100033O0026C60001000200010003000405012O000200010020590103000200022O000B000300023O000405012O000200012O00113O00017O00093O00028O0003083O00726561646F6E6C79026O00F03F03063O0073652O74657203083O004EE950CF4EA957D003043O00EA3D8C242O033O0073756203053O00752O706572027O004001303O00125C2O0100014O00B9000200023O0026C60001000D00010001000405012O000D00012O009D00036O005200046O00270103000200022O0052000200033O0020590103000200020006E50003000C00013O000405012O000C00012O00113O00013O00125C2O0100033O0026C60001000200010003000405012O000200010020590103000200040006500103002C00010001000405012O002C000100125C010300014O00B9000400043O0026C60003001400010001000405012O001400012O009D000500014O002O01068O0005000200024O000400056O000500026O000600033O00122O000700053O00122O000800066O00060008000200202O00070004000700122O000900033O00122O000A00036O0007000A000200202O0007000700084O00070002000200202O00080004000700122O000A00096O0008000A6O00053O000200102O00020004000500044O002C0001000405012O001400010020590103000200042O000B000300023O000405012O000200012O00113O00017O00013O0003053O00737479706501064O003F2O018O00028O00010002000200202O0001000100014O000100028O00017O00043O00028O0003053O00637479706503053O007374797065026O00F03F01163O00125C2O0100014O00B9000200023O0026C60001001000010001000405012O001000012O009D00036O005E00048O0003000200024O000200033O00202O00030002000200062O0003000F00010001000405012O000F00012O009D000300013O0020590104000200032O002701030002000200101200020002000300125C2O0100043O0026C60001000200010004000405012O000200010020590103000200022O000B000300023O000405012O000200012O00113O00017O00023O0003083O00726561646F6E6C793O010A4O00062O018O00028O00010002000200202O00010001000100262O0001000700010002000405012O000700012O00672O016O00232O0100014O000B000100024O00113O00017O00013O0003043O006976617201064O003F2O018O00028O00010002000200202O0001000100014O000100028O00017O00013O00030E3O006D6574686F645F6765744E616D6501084O00382O018O000200013O00202O0002000200014O00038O000200036O00018O00019O0000019O002O0001074O00962O018O000200016O00038O000200036O00018O00019O0000017O00023O0003063O00737472696E6703163O006D6574686F645F67657454797065456E636F64696E6701094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000019O002O0001074O00962O018O000200016O00038O000200036O00018O00019O0000019O002O0001074O00962O018O000200016O00038O000200036O00018O00019O0000019O002O0001094O00832O018O000200016O00038O0002000200024O000300036O000400016O000100046O00019O0000017O00013O0003183O006D6574686F645F676574496D706C656D656E746174696F6E01084O00382O018O000200013O00202O0002000200014O00038O000200036O00018O00019O0000017O00013O0003123O006F626A635F636F7079436C612O734C697374000A4O006E9O00000100016O000200023O00202O0002000200014O000300036O000200036O00019O009O009O0000017O00013O0003063O0069737479706501074O008A2O015O00202O0001000100014O000200016O00038O000100036O00019O0000017O00013O0003063O0069737479706501074O008A2O015O00202O0001000100014O000200016O00038O000100036O00019O0000017O00023O0003113O00636C612O735F69734D657461436C612O73026O00F03F010A4O002B2O015O00202O0001000100014O00028O00010002000200262O0001000700010002000405012O000700012O00672O016O00232O0100014O000B000100024O00113O00017O00223O00028O00026O00084003163O006F626A635F7265676973746572436C612O7350616972026O001040027O004003183O005280A96042CCA97F4389A97748CCAC765785A67655CCED6003043O001331ECC803163O006F626A635F612O6C6F63617465436C612O7350616972026O00F03F03173O00ED22E6B2F6B9F236E52OA4B4F123B6B1EBAFF033B6F2F703063O00DA9E5796D7840003043O007479706503063O00E80ACBEB382503073O00AD9B7EB9825642032D3O00EAA4B0C28BF8A9E6B9CB89FFF6EAFAC89AACE6AABBD49BACEBA7B7C2C8E9FDB6BFC49CE9E1EAFAC087F8A5E3A903063O008C85C6DAA7E8030D3O006F626A635F676574436C612O7303063O00A63AA6748AB203053O00E4D54ED41D031B3O008440B716F8C742B708EEC749AE15EE8458B301A7C74BB911ABC25F03053O008BE72CD66503063O00CAFB14571EB603083O0076B98F663E70D15103053O006D6174636803243O0062353AACED2E227D00353ADBEE5C592B163575A3B65F5403623577DBEE5C5966192O63A203083O00583C104986C5757C03063O0073656C65637403013O002303013O002C03063O00676D6174636803103O0018D1C6840443D7B3810443A0B48D521A03053O0021308A98A803063O00756E7061636B03E03O00125C010400014O00B9000500063O0026C60004001000010002000405012O001000012O009D00075O0020590107000700032O0052000800064O00940107000200010006E50002000F00013O000405012O000F00012O009D000700014O0052000800064O0052000900024O005A000A6O004C00073O000100125C010400043O0026C60004001300010004000405012O001300012O000B000600023O000ECF0005002C00010004000405012O002C00012O009D000700024O0096000800036O00098O0008000200024O000800086O000900043O00122O000A00063O00122O000B00076O0009000B00024O000A8O0007000A00014O000700026O000800056O00095O00202O0009000900084O000A00056O000B5O00122O000C00016O0009000C6O00088O00073O00024O000600073O00122O000400023O0026C60004004300010009000405012O004300012O00B9000500053O0006E50001004200013O000405012O0042000100125C010700013O0026C60007003200010001000405012O003200012O009D000800034O0052000900014O00270108000200022O0052000500084O009D000800024O002D000900056O000A00043O00122O000B000A3O00122O000C000B6O000A000C00024O000B00016O0008000B000100044O00420001000405012O0032000100125C010400053O0026C60004000200010001000405012O000200010026C6000100790001000C000405012O0079000100125C010700013O0026C60007005A00010001000405012O005A00012O009D000800064O005200096O00270108000200020006E50008005000013O000405012O005000012O000B3O00024O009D000800074O005200096O00270108000200020006E50008005900013O000405012O005900012O009D000800084O005200096O00AA010800094O008101085O00125C010700093O0026C60007004800010009000405012O004800012O009D000800023O0012AC0009000D6O000A8O0009000200024O000A00043O00122O000B000E3O00122O000C000F6O000A000C000200062O000900670001000A000405012O006700012O006701096O0023010900014O0029010A00043O00122O000B00103O00122O000C00116O000A000C000200122O000B000D6O000C8O000B000C6O00083O00012O002E000800056O00095O00202O0009000900124O000A8O0009000A6O00088O00085O00044O00480001000405012O008D00012O009D000700023O0012AC0008000D6O00098O0008000200024O000900043O00122O000A00133O00122O000B00146O0009000B000200062O0008008400010009000405012O008400012O006701086O0023010800014O0029010900043O00122O000A00153O00122O000B00166O0009000B000200122O000A000D6O000B8O000A000B6O00073O000100121F0007000D4O0032000800016O0007000200024O000800043O00122O000900173O00122O000A00186O0008000A000200062O000700DD00010008000405012O00DD000100125C010700014O00B9000800093O0026C60007009800010001000405012O0098000100201E010A000100192O00AD000C00043O00122O000D001A3O00122O000E001B6O000C000E6O000A3O000B4O0009000B6O0008000A3O00062O000800DD00013O000405012O00DD000100125C010A00014O00B9000B000B3O000ECF000900BC0001000A000405012O00BC00012O005F000C000B3O002042000C000C000900202O000C000C00014O000B000C000200122O000C00093O00122O000D001C3O00122O000E001D6O000F8O000D3O000200122O000E00093O00042O000C00BB00012O005F0010000B3O0020D800100010000900122O0011001C6O0012000F6O00138O00113O00024O000B0010001100041F010C00B3000100125C010A00053O0026C6000A00D000010001000405012O00D000012O0077000C6O00A9000B000C6O000C00093O00122O000D001E6O000C000C000D00202O000C000C001F4O000E00043O00122O000F00203O00122O001000216O000E00106O000C3O000E00044O00CD00012O005F0010000B3O00206C0110001000092O0038000B0010000F0006D5000C00CA00010001000405012O00CA000100125C010A00093O000ECF000500A60001000A000405012O00A600012O009D000C00034O007B010D8O000E00083O00122O000F00226O0010000B6O000F00106O000C8O000C5O00044O00A60001000405012O00DD0001000405012O0098000100125C010400093O000405012O000200012O00113O00017O00033O00028O0003063O00737472696E67030D3O00636C612O735F6765744E616D6501183O00125C2O0100013O0026C60001000100010001000405012O000100012O009D00026O005200036O00270102000200020006E50002000C00013O000405012O000C00012O009D000200014O005200036O00270102000200022O00523O00024O009D000200023O0020EE0002000200024O000300033O00202O0003000300034O000400046O00058O000400056O00038O00028O00025O00044O000100012O00113O00017O00023O00028O0003133O00636C612O735F6765745375706572636C612O7301173O00125C2O0100013O0026C60001000100010001000405012O000100012O009D00026O005200036O00270102000200020006E50002000C00013O000405012O000C00012O009D000200014O005200036O00270102000200022O00523O00024O009D000200024O009D000300033O0020590103000300022O009D000400044O005200056O003B000400054O001700036O009B00026O008101025O000405012O000100012O00113O00017O00023O00028O00026O00F03F01223O00125C2O0100013O0026C60001001000010002000405012O001000012O009D00026O005200036O00270102000200020006E50002000A00013O000405012O000A00012O00B9000200024O000B000200024O009D000200014O0078010300026O00048O000300046O00028O00025O000ECF0001000100010001000405012O000100012O009D000200034O001A01038O0002000200026O00026O000200046O00038O00020002000200062O0002001F00013O000405012O001F00012O009D000200024O005200036O00270102000200022O00523O00023O00125C2O0100023O000405012O000100012O00113O00017O00033O00028O00027O0040026O00F03F02363O00125C010200014O00B9000300033O0026C60002000900010002000405012O000900012O009D00046O0052000500034O0052000600014O00AA010400064O008101045O000ECF0003001900010002000405012O001900012O009D000400014O005200056O00270104000200022O0052000300043O0006D90003001400010001000405012O001400012O0023010400014O000B000400023O000405012O001800010006500103001800010001000405012O001800012O002301046O000B000400023O00125C010200023O000ECF0001000200010002000405012O000200012O009D000400024O001A010500016O0004000200024O000100046O000400036O00058O00040002000200062O0004003300013O000405012O003300012O009D000400044O005200056O002701040002000200062B0004003100010001000405012O003100012O009D00046O0047000500046O00068O0005000200024O000600016O00040006000200044O003200012O006701046O0023010400014O000B000400023O00125C010200033O000405012O000200012O00113O00017O00023O0003093O00636F726F7574696E6503043O0077726170010C3O00121F000100013O0020592O01000100020006A800023O000100062O009D8O009D3O00014O009D3O00024O00528O009D3O00034O009D3O00044O00AA2O0100024O00812O016O00113O00013O00013O00063O00028O0003163O00636C612O735F636F707950726F746F636F6C4C69737403093O00636F726F7574696E6503053O007969656C64026O00F03F03053O007061697273002C3O00125C012O00014O00B9000100013O000ECF0001001A00013O000405012O001A00012O009D00026O009D000300014O009D000400023O0020590104000400022O009D000500034O00B9000600064O0032010400064O001700036O004B01023O0004000405012O0012000100121F000600033O0020590106000600042O0052000700054O00940106000200010006D50002000E00010001000405012O000E00012O009D000200044O007A000300056O000400036O0003000200024O00010002000300124O00053O0026C63O000200010005000405012O000200010006502O01001F00010001000405012O001F00012O00113O00013O00121F000200064O0052000300014O0055010200020004000405012O0027000100121F000700033O0020590107000700042O0052000800064O00940107000200010006D50002002300010002000405012O00230001000405012O002B0001000405012O000200012O00113O00017O00053O00028O00026O00F03F03063O00666F726D616C03183O00636C612O735F636F6E666F726D73546F50726F746F636F6C03043O006E616D6502353O00125C010200013O0026C60002002800010002000405012O002800010020590103000100030006E50003001100013O000405012O001100012O009D00035O00204C0103000300044O00048O000500016O00030005000200262O0003000E00010002000405012O000E00012O006701036O0023010300014O000B000300023O000405012O0034000100125C010300014O00B9000400043O0026C60003001300010001000405012O001300012O009D000500014O005F010600026O00078O0006000200024O00040005000600062O0004002400013O000405012O0024000100201E0105000100052O00270105000200022O003C0005000400050006E50005002400013O000405012O002400012O0023010500013O0006500105002500010001000405012O002500012O002301056O000B000500023O000405012O00130001000405012O00340001000ECF0001000100010002000405012O000100012O009D000300034O00CB00048O0003000200026O00036O000300046O000400016O0003000200024O000100033O00122O000200023O00044O000100012O00113O00017O00053O00028O00026O00F03F03063O00666F726D616C03113O00636C612O735F612O6450726F746F636F6C03043O006E616D6502423O00125C010300013O000ECF0001000C00010003000405012O000C00012O009D00046O008E01058O0004000200026O00046O000400016O000500016O0004000200024O000100043O00122O000300023O0026C60003000100010002000405012O000100010020590104000100030006E50004001900013O000405012O001900012O009D000400023O0020450104000400044O00058O00068O0005000200024O000600016O00040006000100044O0038000100125C010400014O00B9000500053O0026C60004002100010002000405012O0021000100201E0106000100052O00270106000200022O0038000500060001000405012O003800010026C60004001B00010001000405012O001B00012O009D000600034O0040010700046O00088O0007000200024O00050006000700062O0005003600010001000405012O0036000100125C010600013O0026C60006002B00010001000405012O002B00012O007700076O007C010500076O000700036O000800046O00098O0008000200024O00070008000500044O00360001000405012O002B000100125C010400023O000405012O001B00012O003F000400053O0006E50004004100013O000405012O004100012O009D000400054O005200056O005A00066O004C00043O0001000405012O00410001000405012O000100012O00113O00017O00033O00028O0003053O006D74797065026O00F03F02363O00125C010200014O00B9000300033O0026C60002002500010001000405012O002500012O009D00046O00DF00058O0004000200024O000300046O000400016O00058O00040002000600044O0022000100125C010800014O00B9000900093O0026C60008000E00010001000405012O000E000100201E010A000700022O0065010C00016O000D00036O000E8O000A000E000200062O0009001D0001000A000405012O001D000100201E010A000700022O00C1000C00016O000D00036O000E00016O000A000E00024O0009000A3O0006E50009002200013O000405012O002200012O000B000900023O000405012O00220001000405012O000E00010006D50004000C00010001000405012O000C000100125C010200033O0026C60002000200010003000405012O000200012O009D000400024O005200056O00270104000200020006E50004003500013O000405012O003500012O009D000400034O00A4010500026O00068O0005000200024O000600016O000400066O00045O00044O00350001000405012O000200012O00113O00017O00013O0003163O00636C612O735F636F707950726F70657274794C697374010B4O00992O018O000200016O000300023O00202O0003000300014O00048O000500056O000300056O00028O00018O00019O0000017O00013O0003113O00636C612O735F67657450726F706572747902094O00B100028O000300013O00202O0003000300014O00048O000500016O000300056O00028O00029O0000017O00013O0003143O00636C612O735F636F70794D6574686F644C697374010D4O000A2O018O000200016O000300023O00202O0003000300014O000400036O00058O0004000200024O000500056O000300056O00028O00018O00019O0000017O00013O0003173O00636C612O735F676574496E7374616E63654D6574686F64020D4O000C00028O000300013O00202O0003000300014O000400026O00058O0004000200024O000500036O000600016O000500066O00038O00028O00029O0000017O00023O0003183O00636C612O735F726573706F6E6473546F53656C6563746F72026O00F03F020F4O009D00025O0020590102000200012O009D000300014O005200046O00270103000200022O009D000400024O0052000500014O003B000400054O004E00023O00020026920102000C00010002000405012O000C00012O006701026O0023010200014O000B000200024O00113O00017O00043O00028O0003053O007461626C6503063O00696E7365727403073O0063626672616D65000D3O00125C012O00013O0026C63O000100010001000405012O0001000100121F000100023O0020440001000100034O00025O00122O000300046O0001000300014O000100013O00122O000100043O00044O000C0001000405012O000100012O00113O00017O00033O0003073O0063626672616D6503053O007461626C6503063O0072656D6F766500063O0012EF3O00023O00206O00034O00019O000002000200124O00018O00017O001F3O00028O00026O00104003093O006C6F67746F7069637303093O00612O646D6574686F6403093O007312345CC4237A193403063O005712765031A103153O000C5E9FEDE41C0D9AE5FD184EC9E0F50146C9E0F55F03053O00D02C7EBAC003053O00F416A5D50703083O002E977AC4A6749CA903043O00ECE3550E03053O009B858D267A026O00F03F026O00084003073O0063626672616D652O033O000C079C03073O00C5454ACC212F1F03013O007003073O007265717569726503073O00F34D5C95F1425F03043O00E7902F3A2O033O006E6577027O00402O033O009BF5EA03083O0059D2B8BA15785DAF03133O00636C612O735F7265706C6163654D6574686F642O033O00A7732603063O005AD1331CB51903043O007479706503063O00C36F45E7B1D703053O00DFB01B378E04B13O00125C010400014O00B9000500063O0026C60004002D00010002000405012O002D000100121F000700033O0020590107000700040006E5000700B000013O000405012O00B000012O009D00076O00E2000800013O00122O000900053O00122O000A00066O0008000A00024O000900013O00122O000A00073O00122O000B00086O0009000B00024O000A00026O000B8O000A000200024O000B00036O000C00016O000B000200024O000C00046O000D8O000C0002000200062O000C002200013O000405012O002200012O009D000C00013O00125C010D00093O00125C010E000A4O0002010C000E0002000650010C002600010001000405012O002600012O009D000C00013O00125C010D000B3O00125C010E000C4O0002010C000E00022O009D000D00054O00F6000E00036O000F000F6O001000016O000D00106O00073O000100044O00B000010026C60004003800010001000405012O003800012O009D000700064O008E01088O0007000200026O00076O000700076O000800016O0007000200024O000100073O00122O0004000D3O0026C60004008E0001000E000405012O008E000100121F0007000F3O0006E50007005F00013O000405012O005F00012O009D000700084O0052000800034O00270107000200020006E50007005F00013O000405012O005F000100125C010700014O00B9000800093O0026C60007004F0001000D000405012O004F00012O009D000A00094O007E000B00013O00122O000C00103O00122O000D00116O000B000D000200202O000C000900124O000A000C00024O0006000A3O00044O008600010026C60007004400010001000405012O0044000100121F000A00134O0051000B00013O00122O000C00143O00122O000D00156O000B000D6O000A3O00024O0008000A3O00202O000A000800164O000B00026O000A000200024O0009000A3O00122O0007000D3O00044O00440001000405012O0086000100125C010700014O00B90008000A3O0026C60007006F0001000D000405012O006F00012O009D000B000A4O0043010C00036O000D000D6O000E00016O000B000E00024O0009000B6O000B00096O000C00096O000D00086O000B000D00024O000A000B3O00122O000700173O0026C60007007900010001000405012O007900010006A800083O000100012O00523O00084O009D000B000B4O008B000C00036O000D00086O000B000D00024O0008000B3O00122O0007000D3O0026C60007006100010017000405012O006100012O009D000B00094O0005000C00013O00122O000D00183O00122O000E00196O000C000E00024O000D000A6O000B000D00024O0006000B3O00044O00850001000405012O006100012O00B200076O009D0007000C3O00206F01070007001A4O00088O000900016O000A00066O000B00056O0007000B000100122O000400023O000ECF000D009900010004000405012O009900010006500103009700010001000405012O009700012O009D000700013O00125C0108001B3O00125C0109001C4O00020107000900022O0052000300074O0052000500033O00125C010400173O000ECF0017000200010004000405012O0002000100121F0007001D4O0032000800036O0007000200024O000800013O00122O0009001E3O00122O000A001F6O0008000A000200062O000700A900010008000405012O00A900012O009D0007000D4O0052000800054O00270107000200022O0052000300073O000405012O00AD00012O009D0007000E4O0052000800034O00270107000200022O0052000500074O00B9000600063O00125C0104000E3O000405012O000200012O00113O00013O00017O0002064O005500038O00048O00058O00038O00039O0000017O00013O0003123O00636C612O735F636F7079497661724C697374010B4O00992O018O000200016O000300023O00202O0003000300014O00048O000500056O000300056O00028O00018O00019O0000017O00013O0003193O00636C612O735F676574496E7374616E63655661726961626C6502094O00B100028O000300013O00202O0003000300014O00048O000500016O000300056O00028O00029O0000017O00023O0003063O00737472696E67030C3O00697661725F6765744E616D6501094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000017O00013O00030E3O00697661725F6765744F2O6673657401064O003000015O00202O0001000100014O00028O000100026O00019O0000017O00023O0003063O00737472696E6703143O00697661725F67657454797065456E636F64696E6701094O00392O015O00202O0001000100014O000200013O00202O0002000200024O00038O000200036O00018O00019O0000017O000A3O00028O0003053O006D61746368030F3O001A80DCBB0AB4E187128684FD6AF18703043O00D544DBAE03013O005E03043O0066696E6403093O0035DB66FC6F8D023A5403083O001F6B8043874AA55F03043O00DBECF94B03063O00D1B8889C2D2101203O00125C2O0100014O00B9000200023O0026C60001000200010001000405012O0002000100201E0103000200022O003400055O00122O000600033O00122O000700046O000500076O00033O00024O000200036O000300013O00122O000400056O000500026O0004000400052O00B9000500053O0020800106000200064O00085O00122O000900073O00122O000A00086O0008000A6O00063O000200062O0006001C00013O000405012O001C00012O009D00065O00125C010700093O00125C0108000A4O00020106000800022O00AA010300064O008101035O000405012O000200012O00113O00019O002O0001074O00962O018O000200016O00038O000200036O00018O00019O0000017O00013O0003063O00747970656F6601084O00142O015O00202O0001000100014O000200016O00038O000200036O00018O00019O0000019O002O0001074O00962O018O000200016O00038O000200036O00018O00019O0000017O00013O00028O0003104O009A00038O000400016O000500026O0004000200024O00058O000600026O00078O0005000700024O000600036O000700026O0006000200024O0005000500064O00030005000200202O0003000300014O000300028O00017O00013O00028O00040F4O005000048O000500016O000600026O0005000200024O00068O000700026O00088O0006000800024O000700036O000800024O00270107000200022O00690106000600072O00020104000600020010120004000100032O00113O00017O00013O00028O00020F3O00125C010200014O00B9000300033O0026C60002000200010001000405012O000200012O009D00046O0034010500016O00068O0005000200024O00030004000500062O0004000C00010003000405012O000C00012O003C0004000300012O000B000400023O000405012O000200012O00113O00017O00023O00028O00026O00F03F031E3O00125C010300014O00B9000400043O0026C60003000600010002000405012O000600012O0038000400010002000405012O001D00010026C60003000200010001000405012O000200012O009D00056O0040010600016O00078O0006000200024O00040005000600062O0004001B00010001000405012O001B000100125C010500013O0026C60005001000010001000405012O001000012O007700066O007C010400066O00068O000700016O00088O0007000200024O00060007000400044O001B0001000405012O0010000100125C010300023O000405012O000200012O00113O00017O00053O00028O00026O00F03F03043O0066696E6403013O005F03013O003A022D3O00125C010200014O00B9000300043O0026C60002000E00010001000405012O000E00012O009D00056O0045000600016O0005000200024O000300056O000500016O00068O000700036O0005000700024O000400053O00122O000200023O0026C60002000200010002000405012O000200010006E50004001500013O000405012O001500012O0052000500034O0052000600044O00E0000500033O00201E010500010003001241010700046O000800016O000900016O00050009000200062O0005002C00010001000405012O002C000100201E010500010003001241010700056O000800016O000900016O00050009000200062O0005002C00010001000405012O002C00012O009D000500024O004901068O000700013O00122O000800046O0007000700084O000500076O00055O00044O002C0001000405012O000200012O00113O00017O00063O00028O00026O00F03F03043O0066696E6403063O00C54D4085C33603043O00BF9E126503013O005F02273O00125C010200014O00B9000300043O000ECF0002001900010002000405012O001900010006E50004000900013O000405012O000900012O0052000500034O0052000600044O00E0000500033O00201E0105000100032O005101075O00122O000800043O00122O000900056O000700096O00053O000200062O0005002600010001000405012O002600012O009D000500014O004901068O000700013O00122O000800066O0007000700084O000500076O00055O00044O002600010026C60002000200010001000405012O000200012O009D000500024O0045000600016O0005000200024O000300056O000500036O00068O000700036O0005000700024O000400053O00122O000200023O000405012O000200012O00113O00017O00033O00028O00026O00F03F027O004002283O00125C010200014O00B9000300033O000ECF0001001500010002000405012O001500012O009D00046O007D000500016O00068O0005000200024O000600026O000700016O0006000200024O000700036O00088O0007000200024O000700076O0004000700024O000300043O00062O0003001400013O000405012O001400012O000B000300023O00125C010200023O0026C60002001C00010003000405012O001C00012O009D000400044O005200056O0052000600014O00AA010400064O008101045O0026C60002000200010002000405012O000200012O009D000400054O005200056O00270104000200022O00523O00043O000650012O002500010001000405012O002500012O00113O00013O00125C010200033O000405012O000200012O00113O00017O00023O00028O0003053O007061697273020F3O00125C010200013O0026C60002000100010001000405012O000100010006E50001000C00013O000405012O000C000100121F000300024O0052000400014O0055010300020005000405012O000A00012O00383O000600070006D50003000900010002000405012O000900012O000B3O00023O000405012O000100012O00113O00017O00023O00028O00026O00F03F03263O00125C010300014O00B9000400043O0026C60003001500010002000405012O001500010006E50004000E00013O000405012O000E00012O009D00056O00A4010600016O000700026O0006000200024O000700046O000500076O00055O00044O002500012O009D000500024O0078010600036O000700026O000600076O00058O00055O000405012O00250001000ECF0001000200010003000405012O000200010006500102001E00010001000405012O001E00012O009D000500044O005200066O0052000700014O00020105000700022O0052000200054O009D000500054O008B00068O000700016O0005000700024O000400053O00122O000300023O000405012O000200012O00113O00017O00083O00028O00026O00084003113O00C4D180BEA1C1C69FF7AADDD382B4BBC0C703053O00CFA5A3E7D7026O00F03F027O004003063O00D4FCED40257C03063O0010A62O99364403343O00125C010300014O00B9000400063O0026C60003000700010002000405012O000700012O0052000700064O0052000800024O00E0000700033O0026C60003001700010001000405012O001700012O009D00076O0053000800026O000900013O00122O000A00033O00122O000B00046O0009000B6O00073O00014O000700026O00088O000900016O0007000900084O000500086O000400073O00122O000300053O0026C60003002600010006000405012O002600010006500102001C00010001000405012O001C000100125C010200054O009D000700013O00125C010800073O00125C010900084O00020107000900020006D90002002400010007000405012O002400010006500102002500010001000405012O0025000100206C01020002000600125C010300023O000ECF0005000200010003000405012O000200010006500104002B00010001000405012O002B00012O00113O00014O009D000700034O001C01088O000900046O000A00056O0007000A00024O000600073O00122O000300063O00044O000200012O00113O00017O00053O00028O00026O00F03F03063O00612O73657274030E3O00DDA5C5547933FCDEB6C1553D2FFE03073O0099B2D3A026544102273O00125C010200014O00B9000300033O000ECF0002000F00010002000405012O000F00012O009D00046O009D000500014O005200066O00270105000200020026920103000C00010001000405012O000C00010006420106000D00010003000405012O000D00012O00B9000600064O00380004000500062O000B000300023O0026C60002000200010001000405012O000200012O009D00046O0040010500016O00068O0005000200024O00040004000500062O0004001900010001000405012O0019000100125C010400014O006901030004000100121F000400033O000E940001001E00010003000405012O001E00012O006701056O0023010500014O008A000600023O00122O000700043O00122O000800056O000600086O00043O000100125C010200023O000405012O000200012O00113O00017O00033O00026O00F0BF029O00010C4O002C2O018O00025O00122O000300016O00010003000200262O0001000B00010002000405012O000B00012O009D000100014O009D000200024O005200036O00270102000200020020E60001000200032O00113O00017O00013O0003073O0072656C6561736501033O00201E2O013O00012O00942O01000200012O00113O00017O000D3O00028O00026O00F03F027O004003083O006E6F72657461696E03073O00E2097E7344C0F503063O00B3906C121625030B3O00C7B60F86DDC3AF1E88DCC303053O00AFA6C37BE9026O00084003063O00FDC74948F9E103053O00908FA23D2903093O006C6F67746F7069637303083O00726566636F756E74025E3O00125C010200014O00B90003000A3O0026C60002001400010001000405012O001400012O009D000B6O00C4000C8O000D00016O000B000D000C4O0004000C6O0003000B3O00062O0003000D00010001000405012O000D00012O00113O00014O009D000B00016O000C8O000D00036O000E00046O000B000E00024O0005000B3O00122O000200023O0026C60002002D00010003000405012O002D00012O009D000B00024O0052000C00054O0052000D00074O0002010B000D00022O00520007000B3O00121F000B00044O003C000B000B00012O00700008000B4O0071010B00033O00122O000C00053O00122O000D00066O000B000D000200062O0001002B0001000B000405012O002B00012O009D000B00033O00125C010C00073O00125C010D00084O0002010B000D000200062B0001002B0001000B000405012O002B00012O006701096O0023010900013O00125C010200093O0026C60002004C00010009000405012O004C00010006500109003700010001000405012O003700012O009D000B00033O00125C010C000A3O00125C010D000B4O0002010B000D00020006D90001003A0001000B000405012O003A000100121F000B000C3O002059010A000B000D000405012O003C00012O0067010A6O0023010A00013O0006A8000B3O0001000E2O00523O00074O00523O00034O009D3O00044O009D3O00034O00528O00523O000A4O009D3O00054O00523O00094O009D3O00064O009D3O00074O009D3O00084O00523O00084O009D3O00094O009D3O000A4O000B000B00023O0026C60002000200010002000405012O000200012O009D000B000B4O00FF000C00056O000B000200024O0006000B6O000B000C6O000C00046O000B000200024O0007000B6O000B000D6O000C00066O000D00076O000B000D00024O0007000B3O00122O000200033O00044O000200012O00113O00013O00013O00123O00028O00026O00F03F03063O00787063612O6C03053O00646562756703093O0074726163656261636B030A3O00DB960E1037940EA0960E03073O005380B37D3012E703083O00746F737472696E67027O0040026O00084003083O00746F6E756D626572030B3O0072657461696E436F756E7403023O00676303063O0072657461696E03083O004FB2F5DE480B53A303063O007E3DD793BD2703173O003DEC47053DFB5D0826BF584138B7584138B243053DFB5403043O0025189F7D01A03O00125C010200014O00B9000300093O0026C60002001F00010002000405012O001F000100121F000A00034O0025010B5O00122O000C00043O00202O000C000C00054O000D8O000E00016O000F8O000A3O000B4O0009000B6O0008000A3O00062O0008001E00010001000405012O001E00012O009D000A00024O0047010B8O000C00033O00122O000D00063O00122O000E00076O000C000E000200122O000D00086O000E00046O000D0002000200122O000E00086O000F00014O0027010E000200022O0052000F00094O008C000A000F000100125C010200093O0026C6000200220001000A000405012O002200012O000B000900023O0026C60002004400010001000405012O004400012O00B9000A000E4O003E0107000E6O0006000D6O0005000C6O0004000B6O0003000A6O000A00053O00062O000A004300013O000405012O0043000100125C010A00013O0026C6000A003600010002000405012O003600012O009D000B00064O0052000C5O00125C010D00014O0002010B000D00022O00520006000B3O000405012O00430001000ECF0001002E0001000A000405012O002E000100121F000B00084O003E000C8O000B000200024O0005000B3O00122O000B000B3O00202O000C3O000C4O000C000D6O000B3O00024O0003000B3O00122O000A00023O00044O002E000100125C010200023O0026C60002000200010009000405012O000200012O009D000A00073O0006E5000A005D00013O000405012O005D000100125C010A00013O0026C6000A005500010001000405012O005500012O009D000B00083O002059010B000B000D2O0052000C6O00B9000D000D4O008C000B000D00012O009D000B00094O0052000C6O0094010B0002000100125C010A00023O0026C6000A004A00010002000405012O004A00010026C60003007700010002000405012O0077000100125C010400013O000405012O00770001000405012O004A0001000405012O007700012O009D000A000A4O0052000B00094O0027010A000200020006E5000A007700013O000405012O007700012O009D000A000B3O0006E5000A006900013O000405012O0069000100201E010A0009000E2O0027010A000200022O00520009000A3O000405012O0077000100125C010A00013O0026C6000A006A00010001000405012O006A00012O009D000B00083O00200F010B000B000D4O000C00096O000D000C6O000B000D00014O000B00066O000C00093O00122O000D00026O000B000D000100044O00770001000405012O006A00012O009D000A00053O0006E5000A009D00013O000405012O009D000100125C010A00013O0026C6000A008D00010002000405012O008D00012O009D000B000D4O0011010C00033O00122O000D000F3O00122O000E00106O000C000E00024O000D00033O00122O000E00113O00122O000F00126O000D000F00024O000E00056O000F00064O0086011000076O001100036O001200046O000B0012000100044O009D00010026C6000A007B00010001000405012O007B00010006500104009600010001000405012O0096000100121F000B000B3O00201E010C3O000C2O003B000C000D4O004E000B3O00022O00520004000B4O009D000B00064O008D000C5O00122O000D00016O000B000D00024O0007000B3O00122O000A00023O00044O007B000100125C0102000A3O000405012O000200012O00113O00017O00033O00028O00027O0040026O00F03F04563O00125C010400014O00B9000500073O0026C60004001200010002000405012O001200012O009D00086O005200096O00270108000200022O00523O00083O0006E53O005500013O000405012O005500012O009D000800014O007001098O000A00016O000B00026O000C00036O0008000C6O00085O00044O005500010026C60004003200010003000405012O003200012O009D000800024O009E01098O000A00016O0008000A00094O000700096O000500083O00062O0005003100013O000405012O0031000100125C010800013O0026C60008002100010003000405012O002100012O0023010900014O000B000900023O0026C60008001D00010001000405012O001D00010006500103002900010001000405012O002900012O009D000900034O0052000A00074O00270109000200022O0052000300094O009D000900044O00A4000A8O000B00056O000C00026O000D00036O0009000D000100122O000800033O00044O001D000100125C010400023O0026C60004000200010001000405012O000200012O009D000800054O009E01098O000A00016O0008000A00094O000600096O000500083O00062O0005005300013O000405012O0053000100125C010800013O0026C60008004100010003000405012O004100012O0023010900014O000B000900023O0026C60008003D00010001000405012O003D00010006500103004B00010001000405012O004B00012O009D000900064O00FC000A8O000B00056O000C00066O0009000C00024O000300094O009D000900044O00A4000A8O000B00056O000C00026O000D00036O0009000D000100122O000800033O00044O003D000100125C010400033O000405012O000200012O00113O00017O00023O00028O00026O00F03F02183O00125C010300014O00B9000400043O0026C60003000C00010002000405012O000C00012O009D00056O0052000600044O0052000700014O00020105000700022O005200066O005A00076O009B00056O008101055O0026C60003000200010001000405012O000200012O009D000500014O005200066O00270105000200022O0052000400053O0006500104001500010001000405012O001500012O00113O00013O00125C010300023O000405012O000200012O00113O00017O000B3O00028O00026O00F03F03143O00D7A3614AD5A2354CD5B23544D5B37B4680E6305103043O0022BAC615027O004003063O00612O7365727403373O00F105D551C7F50DCB49C3EC01CA5382EA0DD448CBEA0DC11DC4F71A854ED5F112DF51CBF60F854ACBEC008553C7EF48D658CEFD0BD152D003053O00A29868A53D03233O00DE2AB1727EE18D3CB77175E6D920A03D71E9DF2AB37969A5C422A27175E8C821A6787403063O0085AD4FD21D10030C3O0065786368616E67655F696D7004723O00125C010400014O00B9000500083O0026C60004002800010002000405012O002800012O009D00096O00C4000A8O000B00026O0009000B000A4O0008000A6O000700093O00062O0005002700010001000405012O0027000100125C010900013O0026C60009000D00010001000405012O000D00012O009D000A00014O0052000B6O0027010A000200022O00523O000A3O0006E53O001D00013O000405012O001D00012O009D000A00024O0070010B8O000C00016O000D00026O000E00036O000A000E6O000A5O00044O002700012O009D000A00034O0019000B8O000C00043O00122O000D00033O00122O000E00046O000C000E00024O000D00016O000A000D000100044O00270001000405012O000D000100125C010400053O000ECF0001003500010004000405012O003500012O009D000900054O0060010A8O0009000200026O00096O00098O000A8O000B00016O0009000B000A4O0006000A6O000500093O00122O000400023O0026C60004000200010005000405012O000200010006500107006500010001000405012O0065000100125C010900014O00B9000A000A3O0026C60009004800010002000405012O004800012O009D000B00064O003D000C00026O000B000200024O0007000B6O000B00076O000C8O000D00076O000E00036O000F000A6O000B000F000100122O000900053O000ECF0005005300010009000405012O005300012O009D000B00084O006D010C8O000D00076O000B000D00024O0008000B3O00122O000B00066O000C00086O000B0002000100044O006C00010026C60009003B00010001000405012O003B00012O009D000B00034O0007010C00036O000D00043O00122O000E00073O00122O000F00086O000D000F6O000B3O00014O000B00096O000C8O000D00056O000E00066O000B000E00024O000A000B3O00122O000900023O00044O003B0001000405012O006C00012O009D000900034O0054000A00036O000B00043O00122O000C00093O00122O000D000A6O000B000D6O00093O000100201E01090006000B2O0052000B00084O008C0009000B0001000405012O00710001000405012O000200012O00113O00017O00093O00028O00026O000840026O001040027O0040026O00F03F0003063O00612O73657274031D3O008C68F92E806CF96B9973AD228378E833CD7DAD05B850C16B8E70EC389E03043O004BED1C8D02673O00125C010200014O00B9000300053O0026C60002000C00010002000405012O000C00010006E50005000700013O000405012O000700012O000B000500024O009D00066O005200076O00270106000200022O00523O00063O00125C010200033O000ECF0004002D00010002000405012O002D00010006E50004002500013O000405012O0025000100125C010600014O00B9000700073O0026C60006001200010001000405012O001200012O009D000800014O00B4000900026O000A8O0009000200024O000A00036O000B00046O000A000B6O00083O00024O000700083O00062O0007002500013O000405012O002500012O0052000800074O005200096O00AA010800094O008101085O000405012O00250001000405012O001200012O009D000600014O0075010700026O00088O0007000200024O000800016O0006000800024O000500063O00122O000200023O0026C60002004800010003000405012O004800010006E53O006600013O000405012O0066000100125C010600014O00B9000700073O0026C60006003A00010005000405012O003A00012O009D00086O005200096O00270108000200022O00523O00083O000405012O002F00010026C60006003300010001000405012O003300012O009D000800044O000E00098O000A00016O0008000A00024O000700083O00262O0007004400010006000405012O004400012O000B000700023O00125C010600053O000405012O00330001000405012O002F0001000405012O006600010026C60002005A00010001000405012O005A000100121F000600073O0026C63O004E00010006000405012O004E00012O006701076O0023010700014O008A000800053O00122O000900083O00122O000A00096O0008000A6O00063O00012O009D000600044O008B00078O000800016O0006000800024O000300063O00122O000200053O0026C60002000200010005000405012O000200010026920103005F00010006000405012O005F00012O000B000300024O009D000600064O008B00078O000800016O0006000800024O000400063O00122O000200043O000405012O000200012O00113O00017O00043O00028O00026O00F03F027O00400003743O00125C010300014O00B9000400043O0026C60003003500010002000405012O003500010006E50004002B00013O000405012O002B000100125C010500014O00B9000600063O0026C60005000800010001000405012O000800012O009D00076O0052000800044O00270107000200022O0052000600073O0006E50006002B00013O000405012O002B000100125C010700014O00B9000800083O0026C60007001200010001000405012O001200012O009D000900014O0090000A00026O000B8O000A000200024O000B00066O0009000B00024O000800093O00062O0008002B00013O000405012O002B000100125C010900013O0026C60009001E00010001000405012O001E00012O0052000A00084O000F000B8O000C00026O000A000C00014O000A00016O000A00023O00044O001E0001000405012O002B0001000405012O00120001000405012O002B0001000405012O000800012O009D000500034O00F300068O000700016O000800026O00050008000200062O0005003400013O000405012O003400012O0023010500014O000B000500023O00125C010300033O0026C60003004E00010001000405012O004E00012O009D000500044O005200066O0052000700014O00020105000700020026920105004800010004000405012O0048000100125C010500013O0026C60005003E00010001000405012O003E00012O009D000600054O00DE00078O000800016O000900026O0006000900014O000600016O000600023O00044O003E00012O009D000500064O008B00068O000700016O0005000700024O000400053O00122O000300023O0026C60003000200010003000405012O000200012O009D000500074O005200066O00270105000200022O00523O00053O0006E53O007300013O000405012O0073000100125C010500013O0026C60005005700010001000405012O005700012O009D000600044O005200076O0052000800014O00020106000800020026920106006A00010004000405012O006A000100125C010600013O0026C60006006000010001000405012O006000012O009D000700054O00DE00088O000900016O000A00026O0007000A00014O000700016O000700023O00044O006000012O009D000600074O005200076O00270106000200022O00523O00063O000405012O00540001000405012O00570001000405012O00540001000405012O00730001000405012O000200012O00113O00017O00063O00028O00026O00F03F03063O00612O7365727400031D3O00DD4BD8B4220BF3A1C8508CB8211FE2F99C5E8C9F1A37CBA1DF53CDA23C03083O0081BC3FACD14F7B8703203O00125C010300013O000ECF0002000900010003000405012O000900012O009D00046O008601058O000600016O000700026O00040007000100044O001F0001000ECF0001000100010003000405012O0001000100121F000400033O0026C63O000F00010004000405012O000F00012O006701056O0023010500014O0066000600013O00122O000700053O00122O000800066O000600086O00043O00014O000400026O00058O000600016O000700026O00040007000200062O0004001D00013O000405012O001D00012O00113O00013O00125C010300023O000405012O000100012O00113O00017O00073O00028O00026O00F03F027O004003063O00612O7365727400031E3O0085C15D5F4294C1094E40C4DC475E4A9C95481A61B1F9651A4086DF4C595B03053O002FE4B5293A02563O00125C010200014O00B9000300073O0026C60002002C00010002000405012O002C00012O009D00086O00C5000900046O000A00016O0008000A00024O000500083O00062O0005001E00013O000405012O001E000100125C010800014O00B9000900093O0026C60008000D00010001000405012O000D00012O009D000A00014O0082000B00046O000C00026O000D00056O000C000D6O000A3O00024O0009000A3O00062O0009001E00013O000405012O001E00012O0052000A00094O0052000B6O00AA010A000B4O0081010A5O000405012O001E0001000405012O000D00012O009D000800034O00C5000900046O000A00016O0008000A00024O000600083O00062O0006002B00013O000405012O002B00012O009D000800044O00BA00098O000A00016O000B00066O0008000B6O00085O00125C010200033O0026C60002004500010001000405012O0045000100121F000800043O0026C63O003200010005000405012O003200012O006701096O0023010900014O008A000A00053O00122O000B00063O00122O000C00076O000A000C6O00083O00012O009D000800064O000E00098O000A00016O0008000A00024O000300083O00262O0003004000010005000405012O004000012O000B000300024O009D000800074O005200096O00270108000200022O0052000400083O00125C010200023O0026C60002000200010003000405012O000200012O009D000800014O00C5000900046O000A00016O0008000A00024O000700083O00062O0007004F00013O000405012O004F00012O000B000700024O009D000800084O0065000900046O000A00016O0008000A6O00085O00044O000200012O00113O00017O000A3O00028O00026O001040026O000840026O00F03F027O0040032B3O00612O74656D707420746F20777269746520746F20726561642F6F6E6C792070726F7065727479202225732203063O00612O7365727400031E3O00A7E8CD3E0E200BE6E8D67B0A3E1BA3E4993A431E2A8AD09934013A1AA5E803073O007FC69CB95B6350037F3O00125C010300014O00B9000400063O000ECF0002000A00010003000405012O000A00012O009D00076O008601088O000900016O000A00026O0007000A000100044O007E00010026C60003002200010003000405012O002200010006E50006001900013O000405012O0019000100125C010700013O0026C60007000F00010001000405012O000F00012O009D000800014O00A200098O000A00016O000B00066O000C00026O0008000C00016O00013O00044O000F00012O009D000700024O00F3000800046O000900016O000A00026O0007000A000200062O0007002100013O000405012O002100012O00113O00013O00125C010300023O0026C60003002E00010004000405012O002E00012O009D000700034O004500088O0007000200024O000400076O000700046O000800046O000900016O0007000900024O000500073O00122O000300053O0026C60003006000010005000405012O006000010006E50005005A00013O000405012O005A000100125C010700014O00B9000800083O000ECF0001003400010007000405012O003400012O009D000900054O0052000A00054O00270109000200022O0052000800093O0006E50008005300013O000405012O0053000100125C010900014O00B9000A000A3O0026C60009003E00010001000405012O003E00012O009D000B00064O00C5000C00046O000D00086O000B000D00024O000A000B3O00062O000A005A00013O000405012O005A000100125C010B00013O0026C6000B004800010001000405012O004800012O0052000C000A4O0007000D8O000E00026O000C000E00016O00013O00044O00480001000405012O005A0001000405012O003E0001000405012O005A00012O009D000900074O009A010A5O00122O000B00066O000C00016O0009000C000100044O005A0001000405012O003400012O009D000700084O008B000800046O000900016O0007000900024O000600073O00122O000300033O0026C60003000200010001000405012O0002000100121F000700073O0026C63O006600010008000405012O006600012O006701086O0023010800014O0008010900093O00122O000A00093O00122O000B000A6O0009000B6O00073O00014O0007000A6O00088O000900016O00070009000200262O0007007C00010008000405012O007C000100125C010700013O0026C60007007300010001000405012O007300012O009D00086O006801098O000A00016O000B00026O0008000B00016O00013O00044O0073000100125C010300043O000405012O000200012O00113O00017O00123O00028O00026O00F03F03083O00746F6E756D626572026O00F04103043O006D61746803053O00666C2O6F72027O0040030A3O00A95FDFAAE75B219BE64403083O00BE957AAC90C76B5903063O00771DB4AEA62A03053O009E5265919E03023O0035E603053O0024109E6276002O033O00CE1FCF03083O0085A076A39B38884703093O00E3AB7FE6A60BA7C9B603073O00D596C21192D67F01433O00125C2O0100014O00B9000200043O0026C60001001000010002000405012O0010000100121F000500033O00201B0006000200044O0005000200024O000300053O00122O000500053O00202O00050005000600122O000600033O00202O0007000200044O000600076O00053O00024O000400053O00122O000100073O0026C60001002F00010007000405012O002F00012O009D00056O00A0000600013O00122O000700083O00122O000800096O0006000800024O000700026O00088O00070002000200262O0004002600010001000405012O002600012O009D00086O0081000900013O00122O000A000A3O00122O000B000B6O0009000B00024O000A00046O000B00036O0008000B000200062O0008002D00010001000405012O002D00012O009D00086O0013010900013O00122O000A000C3O00122O000B000D6O0009000B00024O000A00034O00020108000A00022O00AA010500084O008101055O000ECF0001000200010001000405012O000200010026C63O00380001000E000405012O003800012O009D000500013O00125C0106000F3O00125C010700104O00AA010500074O008101056O009D000500034O00AF000600013O00122O000700113O00122O000800126O0006000800024O00078O0005000700024O000200053O00122O000100023O00044O000200012O00113O00017O00093O00029O002O033O0015A0A803083O00567BC9C4B426C4C2030A3O00ABADCAF1A7F09CFFAFF003043O00CF9788B903083O00746F6E756D62657203093O00BD8A2696646C632O9703073O0011C8E348E21418011F3O00125C2O0100013O0026C60001000100010001000405012O000100010026C63O000A00010002000405012O000A00012O009D00025O00125C010300033O00125C010400044O00AA010200044O008101026O009D000200014O007301035O00122O000400053O00122O000500066O0003000500024O000400026O00058O00040002000200122O000500076O000600036O00075O00122O000800083O00122O000900096O0007000900024O00088O000600086O00058O00028O00025O00044O000100012O00113O00017O002A3O00028O0003013O007603043O007479706503063O0057E3F0C70CEA03063O008D249782AE62026O00F03F03073O006973626C6F636B2O0103053O007461626C6503063O00696E7365727403023O00BA6C03043O006DE41AA203073O0063626672616D6503013O007003073O007265717569726503073O005DE7FB6AE1EB5B03063O00863E859D18802O033O006E6577027O0040026O001040026O001440026O00224003023O00676303053O00F18BEE740B03063O002893E781176003153O0063726561746509726566636F756E743A20252D3864026O001C40030A3O0064657363726970746F7203013O006403083O00726573657276656403043O0073697A6503063O0073697A656F66026O002040030B3O00636F70795F68656C706572030E3O00646973706F73655F68656C706572026O000840026O00184003053O00666C616773026O00804103063O00696E766F6B652O033O0069736103153O005F4E53436F6E6372657465537461636B426C6F636B02D63O00125C010200014O00B90003000B3O0026C60002001E00010001000405012O001E00012O009D000C6O0052000D6O0027010C000200020006E5000C000A00013O000405012O000A00012O000B3O00023O0006502O01001000010001000405012O001000012O0077000C00013O00125C010D00024O00F9000C000100012O00520001000C3O00121F000C00034O0032000D00016O000C000200024O000D00013O00122O000E00043O00122O000F00056O000D000F000200062O000C001D0001000D000405012O001D00012O009D000C00024O0052000D00014O0027010C000200022O00520001000C3O00125C010200063O0026C60002007500010006000405012O00750001002059010C00010007000650010C003200010001000405012O0032000100125C010C00013O0026C6000C002400010001000405012O002400010030202O010007000800121F000D00093O002059010D000D000A2O0052000E00013O00125C010F00064O008A001000013O00122O0011000B3O00122O0012000C6O001000126O000D3O0001000405012O00320001000405012O002400012O00B9000C000D4O00520004000D4O00520003000C3O00121F000C000D3O0006E5000C005300013O000405012O005300012O009D000C00034O0052000D00014O0027010C000200020006E5000C005300013O000405012O0053000100125C010C00014O00B9000D000D3O0026C6000C004300010006000405012O0043000100205901040003000E000405012O007400010026C6000C003F00010001000405012O003F000100121F000E000F4O0051000F00013O00122O001000103O00122O001100116O000F00116O000E3O00024O000D000E3O00202O000E000D00124O000F8O000E000200024O0003000E3O00122O000C00063O00044O003F0001000405012O0074000100125C010C00014O00B9000D000F3O0026C6000C005E00010013000405012O005E00012O009D001000044O00520011000F4O00520012000E4O00020110001200022O0052000300104O0052000400033O000405012O007300010026C6000C006700010001000405012O006700012O009D001000054O0075001100016O0012000D6O0010001200024O000D00106O000E000E3O00122O000C00063O0026C6000C005500010006000405012O005500010006A8000E3O000100012O00523O000D4O009E001000066O001100016O001200126O001300016O0010001300024O000F00103O00122O000C00133O00044O005500012O00B2000C5O00125C010200133O0026C60002008600010014000405012O008600012O00B9000A000A3O0006A8000A0001000100072O00523O00054O00523O00074O00523O00034O00523O00084O00523O00094O009D3O00074O009D3O00014O0067000C00046O000D00086O000E00066O000C000E00024O0008000C3O00122O000200153O0026C60002009600010016000405012O009600012O009D000C00093O00202C000C000C00174O000D000B6O000E000A6O000C000E00014O000C00076O000D00013O00122O000E00183O00122O000F00196O000D000F000200122O000E001A6O000F00056O000C000F00014O000B00023O000ECF001B00A300010002000405012O00A30001002059010C0007001D0010270007001C000C00202O000C0007001D00302O000C001E000100202O000C0007001D4O000D00093O00202O000D000D00204O000E000A6O000D0002000200102O000C001F000D00122O000200213O0026C6000200AF00010021000405012O00AF0001002059010C0007001D00100C010C0022000800202O000C0007001D00102O000C002300094O000C00046O000D000B6O000E00076O000C000E00024O000B000C3O00122O000200163O0026C6000200B300010024000405012O00B300012O00B9000700093O00125C010200143O0026C6000200BD00010025000405012O00BD00010030200107002600270030210007001E00014O000C00046O000D000C6O000E00046O000C000E000200102O00070028000C00122O0002001B3O000ECF001500CB00010002000405012O00CB00012O009D000C00044O00AB000D000D6O000E000A6O000C000E00024O0009000C6O000C000A6O000C000100024O0007000C6O000C000E3O00202O000C000C002A00102O00070029000C00122O000200253O0026C60002000200010013000405012O0002000100125C010500064O00B9000600063O0006A800060002000100032O00523O00054O009D3O00074O009D3O00013O00125C010200243O000405012O000200012O00113O00013O00037O0001054O004600028O00038O00028O00029O0000017O00073O00028O00026O00F03F03043O0066722O6503053O0005A915DA2403073O00B667C57AB94FD103163O00646973706F736509726566636F756E743A20252D386403063O00612O7365727401313O00125C2O0100013O0026C60001001D00010001000405012O001D00012O009D00025O0020A20102000200022O00A600026O009D00025O0026C60002001C00010001000405012O001C000100125C010200013O0026C60002001200010001000405012O001200012O00B9000300034O0024000300016O000300023O00202O0003000300034O00030002000100122O000200023O0026C60002000A00010002000405012O000A00012O009D000300033O00202A0103000300034O0003000200014O000300043O00202O0003000300034O00030002000100044O001C0001000405012O000A000100125C2O0100023O000ECF0002000100010001000405012O000100012O009D000200054O00EB000300063O00122O000400043O00122O000500056O00030005000200122O000400066O00058O00020005000100122O000200076O00035O000E2O0001002C00010003000405012O002C00012O006701036O0023010300014O0094010200020001000405012O00300001000405012O000100012O00113O00017O00073O00028O00026O00F03F03063O00612O73657274027O004003053O0077F48346B003073O00BC1598EC25DBCC03133O00636F707909726566636F756E743A20252D3864021B3O00125C010200013O0026C60002000B00010002000405012O000B000100121F000300034O009D00045O000E940004000800010004000405012O000800012O006701046O0023010400014O0094010300020001000405012O001A00010026C60002000100010001000405012O000100012O009D00035O0020020003000300024O00038O000300016O000400023O00122O000500053O00122O000600066O00040006000200122O000500076O00068O00030006000100125C010200023O000405012O000100012O00113O00017O00153O0003043O007479706503063O004EFC3A0E45FB03043O006C20895703083O004E534E756D62657203103O006E756D62657257697468446F75626C6503063O00B9FC12AF21FE03083O0039CA8860C64F992B03083O004E2O537472696E6703143O00737472696E675769746855544638537472696E6703053O00BF22A8AB8803073O0098CB43CAC7EDC7028O0003133O004E534D757461626C6544696374696F6E617279030A3O0064696374696F6E61727903053O00706169727303103O007365744F626A6563745F666F724B6579026O00F03F030E3O004E534D757461626C65412O72617903053O00612O72617903063O0069706169727303093O00612O644F626A65637401703O0012C8000100016O00028O0001000200024O00025O00122O000300023O00122O000400036O00020004000200062O0001001000010002000405012O001000012O009D000100013O0020D600010001000400202O0001000100054O00038O000100036O00015O00044O006F000100121F000100014O003200028O0001000200024O00025O00122O000300063O00122O000400076O00020004000200062O0001002000010002000405012O002000012O009D000100013O0020D600010001000800202O0001000100094O00038O000100036O00015O00044O006F000100121F000100014O003200028O0001000200024O00025O00122O0003000A3O00122O0004000B6O00020004000200062O0001006300010002000405012O006300012O005F00015O0026C6000100490001000C000405012O0049000100125C2O01000C4O00B9000200023O0026C6000100440001000C000405012O004400012O009D000300013O00201000030003000D00202O00030003000E4O0003000200024O000200033O00122O0003000F6O00048O00030002000500044O0041000100201E0108000200102O0025000A00026O000B00076O000A000200024O000B00026O000C00066O000B000C6O00083O00010006D50003003900010002000405012O0039000100125C2O0100113O0026C60001002E00010011000405012O002E00012O000B000200023O000405012O002E0001000405012O006F000100125C2O01000C4O00B9000200023O0026C60001004E00010011000405012O004E00012O000B000200023O0026C60001004B0001000C000405012O004B00012O009D000300013O00201000030003001200202O0003000300134O0003000200024O000200033O00122O000300146O00048O00030002000500044O005E000100201E0108000200152O009D000A00024O0052000B00074O003B000A000B4O004C00083O00010006D50003005900010002000405012O0059000100125C2O0100113O000405012O004B0001000405012O006F00012O009D000100034O005200026O00272O01000200020006E50001006E00013O000405012O006E00012O009D000100044O00B0000200056O00038O000100036O00015O00044O006F00012O000B3O00024O00113O00017O00043O0003053O00636F756E7403043O007479706503083O00FC56AE0C0B7C76E803083O00869A23C06F7F151901113O00208500013O000100122O000200026O000300016O0002000200024O00035O00122O000400033O00122O000500046O00030005000200062O0002000F00010003000405012O000F00012O0052000200014O005200036O00AA010200034O008101025O000405012O001000012O000B000100024O00113O00017O00123O0003083O004E534E756D626572030B3O00646F75626C6556616C756503083O004E2O537472696E67030A3O0055544638537472696E67030C3O004E5344696374696F6E617279028O00027O004003123O006765744F626A656374735F616E644B657973026O00F03F026O0008402O033O006E657703053O00B12232551D03063O00B2D846696A4003053O00362F41A9F403083O00E05F4B1A96A9B5B403083O00746F6E756D62657203073O004E53412O726179030D3O006F626A6563744174496E646578017F4O009300018O00028O000300013O00202O0003000300014O00010003000200062O0001000B00013O000405012O000B000100201E2O013O00022O00AA2O0100024O00812O015O000405012O007E00012O009D00016O005B01028O000300013O00202O0003000300034O00010003000200062O0001001600013O000405012O0016000100201E2O013O00042O00AA2O0100024O00812O015O000405012O007E00012O009D00016O005B01028O000300013O00202O0003000300054O00010003000200062O0001005700013O000405012O0057000100125C2O0100064O00B9000200053O0026C60001003200010007000405012O0032000100201E01063O00082O0010010800046O000900056O00060009000100122O000600063O00202O00070003000900122O000800093O00042O0006003100012O009D000A00024O00CD000B000500094O000A000200024O000B00026O000C000400094O000B000200024O0002000A000B00041F01060029000100125C2O01000A3O0026C60001004700010009000405012O004700012O009D000600033O00208600060006000B4O000700043O00122O0008000C3O00122O0009000D6O0007000900024O000800036O0006000800024O000400066O000600033O00202O00060006000B2O0013010700043O00122O0008000E3O00122O0009000F6O0007000900024O000800034O00020106000800022O0052000500063O00125C2O0100073O0026C60001005200010006000405012O005200012O007700066O00D4000200063O00122O000600106O000700056O00088O000700086O00063O00024O000300063O00122O000100093O0026C60001001F0001000A000405012O001F00012O000B000200023O000405012O001F0001000405012O007E00012O009D00016O005B01028O000300013O00202O0003000300114O00010003000200062O0001007D00013O000405012O007D000100125C2O0100064O00B9000200023O0026C60001006300010009000405012O006300012O000B000200023O0026C60001006000010006000405012O006000012O007700036O0021010200033O00122O000300063O00122O000400106O000500056O00068O000500066O00043O000200202O00040004000900122O000500093O00042O0003007A00012O005F000700023O00206A01070007000900202O0007000700064O000800023O00202O00093O00124O000B00066O0009000B6O00083O00024O00020007000800041F01030070000100125C2O0100093O000405012O00600001000405012O007E00012O000B3O00024O00113O00017O00053O00028O0003043O007479706503083O000DCFD62B50A5790503073O00166BBAB84824CC03073O006973626C6F636B02293O00125C010200013O0026C60002000100010001000405012O0001000100121F000300024O0089010400016O0003000200024O00045O00122O000500033O00122O000600046O00040006000200062O0003000D00010004000405012O000D00012O000B000100023O00205901033O00050006E50003001600013O000405012O001600012O009D000300014O0065000400016O00058O000300056O00035O00044O0028000100125C010300014O00B9000400043O0026C60003001800010001000405012O001800012O009D000500024O000D00068O000700076O000800016O0005000800024O000400056O000500034O0065000600046O000700016O000500076O00055O00044O00180001000405012O00280001000405012O000100012O00113O00017O00053O00028O0003013O003A03013O002303013O004003023O006670032C3O00125C010300014O00B9000400043O0026C60003000200010001000405012O000200012O003C00043O00010026C60004000C00010002000405012O000C00012O009D00056O0052000600024O00AA010500064O008101055O000405012O002B00010026C60004001300010003000405012O001300012O009D000500014O0052000600024O00AA010500064O008101055O000405012O002B00010026C60004001A00010004000405012O001A00012O009D000500024O0052000600024O00AA010500064O008101055O000405012O002B000100205901053O00050006E50005002800013O000405012O0028000100205901053O00052O003C0005000500010006E50005002800013O000405012O002800012O009D000500033O0020BE00063O00054O0006000600014O000700026O000500076O00055O00044O002B00012O000B000200023O000405012O002B0001000405012O000200012O00113O00017O00053O00028O0003063O0073656C65637403013O0023026O00F03F027O0040021A3O00125C010300013O0026C60003000100010001000405012O0001000100121F000400023O00125C010500034O005A00066O004E00043O00020026C60004000A00010001000405012O000A00012O00113O00014O009D00046O005701058O000600016O00078O00043O00024O000500016O00065O00202O00070001000400122O000800023O00122O000900056O000A8O00088O00058O00045O00044O000100012O00113O00017O00023O00028O00026O00F03F04193O00125C010400014O00B9000500063O000ECF0002000A00010004000405012O000A00012O009D00076O00BA000800056O000900066O000A00036O0007000A6O00075O0026C60004000200010001000405012O000200012O009D000700014O005200086O00C4000900016O000A00066O0007000A00084O000600086O000500073O00062O0005001600010001000405012O001600012O00113O00013O00125C010400023O000405012O000200012O00113O00017O00084O0003063O0072657476616C03013O0042026O00F03F03013O002A03023O00F5F703053O006E87DD442E03063O00737472696E6702203O0026C60001000500010001000405012O000500012O00B9000200024O000B000200023O000405012O001F000100205901023O00020026C60002000E00010003000405012O000E00010026922O01000B00010004000405012O000B00012O006701026O0023010200014O000B000200023O000405012O001F000100205901023O00020026920102001800010005000405012O0018000100205901023O00022O003501035O00122O000400063O00122O000500076O00030005000200062O0002001E00010003000405012O001E00012O009D000200013O0020900102000200084O000300016O000200036O00025O00044O001F00012O000B000100024O00113O00017O00063O00028O00026O00F03F027O004003013O004003013O003A026O000840023D4O005F00025O0026C60002000900010001000405012O000900010006A800023O000100032O009D8O00528O00523O00014O000B000200023O000405012O003C00012O005F00025O0026C60002001300010002000405012O001300010006A800020001000100042O009D8O00528O00523O00014O009D3O00014O000B000200023O000405012O003C00012O005F00025O0026C60002002400010003000405012O0024000100205901023O00020026C60002002400010004000405012O0024000100205901023O00030026C60002002400010005000405012O002400010006A800020002000100052O009D8O00528O00523O00014O009D3O00024O009D3O00034O000B000200023O000405012O003C00012O005F00025O0026C60002003600010006000405012O0036000100205901023O00020026C60002003600010004000405012O0036000100205901023O00030026C60002003600010005000405012O003600010006A800020003000100062O009D8O00528O00523O00014O009D3O00024O009D3O00034O009D3O00014O000B000200023O000405012O003C00010006A800020004000100042O009D8O00528O00523O00014O009D3O00044O000B000200024O00113O00013O00058O00074O00369O00000100016O000200026O000200019O009O008O00017O00013O00026O00F03F010C4O006F00018O000200016O000300026O000400036O000500013O00122O000600016O00078O000400076O00038O00018O00019O0000019O002O00020D4O00DB00028O000300016O000400026O000500036O00068O0005000200024O000600046O000700016O000600076O00046O009B00026O008101026O00113O00017O00013O00026O00084003124O00A100038O000400016O000500026O000600036O00078O0006000200024O000700046O000800016O0007000200024O000800056O000900013O00122O000A00016O000B00026O0008000B6O00058O00038O00039O0000017O00013O00026O00F03F000C4O00A300018O000200016O000300026O000400036O000500013O00122O000600016O00078O00048O00038O00016O00812O016O00113O00017O00013O0003073O006973626C6F636B020D3O00205901023O00010006E50002000500013O000405012O000500012O000B000100023O000405012O000C00012O009D00026O009D000300014O005200046O00270103000200022O0052000400014O00AA010200044O008101026O00113O00017O00013O0003023O00667003103O00205901033O00010006E50003000E00013O000405012O000E000100205901033O00012O003C0003000300010006E50003000E00013O000405012O000E00012O009D00035O0020BE00043O00014O0004000400014O000500026O000300056O00035O00044O000F00012O000B000200024O00113O00017O00053O00028O0003063O0073656C65637403013O0023026O00F03F027O0040021A3O00125C010300013O0026C60003000100010001000405012O0001000100121F000400023O00125C010500034O005A00066O004E00043O00020026C60004000A00010001000405012O000A00012O00113O00014O009D00046O005701058O000600016O00078O00043O00024O000500016O00065O00202O00070001000400122O000800023O00122O000900056O000A8O00088O00058O00045O00044O000100012O00113O00017O00043O00028O0003023O00667003063O0072657476616C03013O004002173O00125C010200013O000ECF0001000100010002000405012O0001000100205901033O00020006500103000F00010001000405012O000F000100205901033O00030026C60003000E00010004000405012O000E00010006A800033O000100022O009D8O00523O00014O000B000300023O000405012O000F00012O000B000100023O0006A800030001000100042O00523O00014O009D3O00014O00528O009D8O000B000300023O000405012O000100012O00113O00013O00028O00074O00F100018O000200016O00038O00028O00018O00019O0000017O00043O00028O00026O00F03F03063O0072657476616C03013O004000193O00125C2O0100014O00B9000200023O000ECF0001000200010001000405012O000200012O009D00036O0097000400016O000500023O00122O000600026O00078O00048O00033O00024O000200036O000300023O00202O00030003000300262O0003001500010004000405012O001500012O009D000300034O0052000400024O00AA010300044O008101035O000405012O001800012O000B000200023O000405012O00180001000405012O000200012O00113O00017O00033O00028O00026O00F03F030D3O006F626A6563744174496E64657802113O00125C010200013O0026C60002000100010001000405012O000100012O009D00036O005200046O00270103000200020006A00103000900010001000405012O000900012O00113O00013O00206C01030001000200206C01030003000100201E01043O00032O0052000600014O0032010400064O008101035O000405012O000100012O00113O00017O00013O00028O0001054O00562O018O00025O00122O000300016O000100028O00019O002O00010B3O000650012O000600010001000405012O000600012O009D00016O004F2O0100014O00812O015O000405012O000A00012O009D000100014O005200026O00AA2O0100024O00812O016O00113O00017O00013O0003083O00746F737472696E6702144O004000028O000300016O00048O00030002000200122O000400016O000500016O000400056O00023O000200062O0002001200010001000405012O001200012O009D00026O009D000300024O005200046O002701030002000200121F000400014O0052000500014O003B000400054O004E00023O00022O000B000200024O00113O00017O00013O0003073O0072657175697265010E4O009D00016O003C000100013O0006E50001000C00013O000405012O000C000100121F000100014O009D00026O003C000200024O00272O01000200020006E50001000C00013O000405012O000C00012O009D000100014O003C000100014O000B000100024O00113O00019O002O00020F4O009D00026O0052000300014O00270102000200020006500102000D00010001000405012O000D00012O009D000200014O0052000300014O00270102000200020006500102000D00010001000405012O000D00012O009D000200024O0052000300014O00270102000200022O000B000200024O00113O00017O00", GetFEnv(), ...);
