pico-8 cartridge // http://www.pico-8.com
version 32
__lua__
-- px9 data compression v7
-- by zep
--
-- changelog:
-- 
-- v7:
--  smaller vlist_val by @felice
--  7b -> 254 tokens (fastest)
--  7a -> 247 tokens (smallest)
--  
-- 
-- v6:
--  smaller vlist_val by @p01
--  -> 258 tokens
-- 
-- v5:
--  fixed bug found by @icegoat
--  262 tokens (the bug was caused by otherwise redundant code!)
--
-- v4:
--  @catatafish
--  ★ smaller decomp
--
--  @felice
--  ★ fix bit flush at end
--  ★ use 0.2.0 functionality
--  ★ even smaller decomp
--  ★ some code simpler/cleaner
--  ★ hey look, a changelog!
--
-- v3:
--  @felice
--  ★ smaller decomp
--
-- v2:
--  @zep
--  ★ original release
--
--[[

  features:
  ★ 273 token decompress
  ★ handles any bit size data
  ★ no manual tuning required
  ★ decent compression ratios


  ██▒ how to use ▒██

  1. compress your data

    px9_comp(source_x, source_y,
      width, height,
      destination_memory_addr,
      read_function)
        
    e.g. to compress the whole
    spritesheet to the map:
    
    px9_comp(0,0,128,128,
      0x2000, sget)

  …………………………………
  2. decompress
  
    px9_decomp(dest_x, dest_y,
      source_memory_addr,
      read_function,
      write_function)

    e.g. to decompress from map
    memory space back to the
    screen:
    
    px8_decomp(0,0,0x2000,
      pget,pset)

    …………………………………

    (see example below)

    note: only the decompress
    code (tab 1) is needed in
    your release cart after
    storing compressed data.
    
]]

levels = {
    {
        offset = 0,
        width = 96,
        height = 16,
    camera_mode = 1,
    music = 38,
    },
    {
    offset = 343,
        width = 32,
        height = 32,
        camera_mode = 2,
    music = 36,
    fogmode = 1,
    clouds = 0,
    columns = 1
    },
    {
    offset = 679,
        width = 128,
        height = 22,
        camera_mode = 3,
        camera_barriers_x = { 38 },
        camera_barrier_y = 6,
        music = 2,
    title = "trailhead"
    },
    {
        offset = 1313,
        width = 128,
        height = 32,
        camera_mode = 4,
        music = 2,
    title = "glacial caves",
    pal = function() pal(2, 12) pal(5, 2) end,
    columns = 1
    },
    {
    offset = 2411,
        width = 128,
        height = 16,
        camera_mode = 5,
        music = 2,
    title = "golden valley",
    pal = function() pal(2, 14) pal(5, 2) end,
    bg = 13,
    clouds = 15,
    fogmode = 2
    },
    {
    offset = 2645,
        width = 128,
        height = 16,
        camera_mode = 6,
        camera_barriers_x = { 105 },
        music = 2,
    pal = function() pal(2, 14) pal(5, 2) end,
    bg = 13,
    clouds = 15,
    fogmode = 2
    },
    {
    offset = 2880,
        width = 128,
        height = 16,
        camera_mode = 7,
        music = 2,
    pal = function() pal(2, 12) pal(5, 2) end,
    bg = 13,
    clouds = 7,
    fogmode = 2,
    },
    {
    offset = 3079,
        width = 16,
    height = 62,
    title = "destination",
        camera_mode = 8,
        music = 2,
    pal = function() pal(2, 1) pal(7, 11) end,
    bg = 15,
    clouds = 7,
        fogmode = 2,
        right_edge = true
    },
    -- dummy level at the end for code reasons
    {
      offset = 4096
    },
}

function _init()

  idx = 8
  reload(0x0, 0x1000 + levels[idx].offset, levels[idx+1].offset, "celeste2.p8")

  memset(0x2000, 0, 0x2000)
  local function vget(x, y) return peek(0x2000 + x + y * 128) end
  local function vset(x, y, v) return poke(0x2000 + x + y * 128, v) end
  px9_decomp(0, 0, 0x0, vget, vset)

  cstore(0x2000, 0x2000, 0x1000, idx .. ".p8")
  cstore(0x1000, 0x3000, 0x1000, idx .. ".p8")

  return 0
end

  -- test: compress from
  -- spritesheet to map, and
  -- then decomp back to screen

--[[
  cls()
  print("compressing..",5)
  flip()

  w=128 h=128
  raw_size=(w*h+1)\2 -- bytes

  ctime=stat(1)

  -- compress spritesheet to map
  -- area (0x2000) and save cart

  clen = px9_comp(
    0,0,
    w,h,
    0x2000,
    sget)

  ctime=stat(1)-ctime

  --cstore() -- save to cart

  -- show compression stats
  print("                 "..(ctime/30).." seconds",0,0)
  print("")
  print("compressed spritesheet to map",6)
  ratio=tostr(clen/raw_size*100)
  print("bytes: "
    ..clen.." / "..raw_size
    .." ("..sub(ratio,1,4).."%)"
    ,12)
  print("")
  print("press ❎ to decompress",14)

  memcpy(0x7000,0x2000,0x1000)

  -- wait for user
  repeat until btn(❎)

  print("")
  print("decompressing..",5)
  flip()

  -- save stats screen
  local cx,cy=cursor()
  local sdata={}
  for a=0x6000,0x7ffc do
    sdata[a]=peek4(a)
  end

  dtime=stat(1)

  -- decompress data from map
  -- (0x2000) to screen

  px9_decomp(0,0,0x2000,pget,pset)

  dtime=stat(1)-dtime

  -- wait for user
  repeat until btn(❎)

  -- restore stats screen
  for a,v in pairs(sdata) do
    poke4(a,v)
  end

  -- add decompression stats
  print("                 "..(dtime/30).." seconds",cx,cy-6,5)
  print("")

end
]]

-->8
-- px9 decompress

-- x0,y0 where to draw to
-- src   compressed data address
-- vget  read function (x,y)
-- vset  write function (x,y,v)

function
  px9_decomp(x0,y0,src,vget,vset)

  local function vlist_val(l, val)
    -- find position and move
    -- to head of the list

--[ 2-3x faster than block below
    local v,i=l[1],1
    while v!=val do
      i+=1
      v,l[i]=l[i],v
    end
    l[1]=val
--]]

--[[ 7 tokens smaller than above
    for i,v in ipairs(l) do
      if v==val then
        add(l,deli(l,i),1)
        return
      end
    end
--]]
  end

  -- bit cache is between 16 and 
  -- 31 bits long with the next
  -- bit always aligned to the
  -- lsb of the fractional part
  local cache,cache_bits=0,0
  function getval(bits)
    if cache_bits<16 then
      -- cache next 16 bits
      cache+=%src>>>16-cache_bits
      cache_bits+=16
      src+=2
    end
    -- clip out the bits we want
    -- and shift to integer bits
    local val=cache<<32-bits>>>16-bits
    -- now shift those bits out
    -- of the cache
    cache=cache>>>bits
    cache_bits-=bits
    return val
  end

  -- get number plus n
  function gnp(n)
    local bits=0
    repeat
      bits+=1
      local vv=getval(bits)
      n+=vv
    until vv<(1<<bits)-1
    return n
  end

  -- header

  local 
    w,h_1,      -- w,h-1
    eb,el,pr,
    x,y,
    splen,
    predict
    =
    gnp"1",gnp"0",
    gnp"1",{},{},
    0,0,
    0
    --,nil

  for i=1,gnp"1" do
    add(el,getval(eb))
  end
  for y=y0,y0+h_1 do
    for x=x0,x0+w-1 do
      splen-=1

      if(splen<1) then
        splen,predict=gnp"1",not predict
      end

      local a=y>y0 and vget(x,y-1) or 0

      -- create vlist if needed
      local l=pr[a]
      if not l then
        l={}
        for e in all(el) do
          add(l,e)
        end
        pr[a]=l
      end

      -- grab index from stream
      -- iff predicted, always 1

      local v=l[predict and 1 or gnp"2"]

      -- update predictions
      vlist_val(l, v)
      vlist_val(el, v)

      -- set
      vset(x,y,v)

    end
  end
end

-->8
-- px9 compress

-- x0,y0 where to read from
-- w,h   image width,height
-- dest  address to store
-- vget  read function (x,y)

function 
px9_comp(x0,y0,w,h,dest,vget)

  local dest0=dest
  local bit=1 
  local byte=0

  local function vlist_val(l, val)
    -- find position and move
    -- to head of the list

--[ 2-3x faster than block below
    local v,i=l[1],1
    while v!=val do
      i+=1
      v,l[i]=l[i],v
    end
    l[1]=val
    return i
--]]

--[[ 8 tokens smaller than above
    for i,v in ipairs(l) do
      if v==val then
        add(l,deli(l,i),1)
        return i
      end
    end
--]]
  end

  function putbit(bval)
    if (bval) byte+=bit 
    poke(dest, byte) bit<<=1
    if (bit==256) then
      bit=1 byte=0
      dest += 1
    end
  end

  function putval(val, bits)
    for i=0,bits-1 do
      putbit(val&1<<i > 0)
    end
  end

  function putnum(val)
    local bits = 0
    repeat
      bits += 1
      local mx=(1<<bits)-1
      local vv=min(val,mx)
      putval(vv,bits)
      val -= vv
    until vv<mx
  end


  -- first_used

  local el={}
  local found={}
  local highest=0
  for y=y0,y0+h-1 do
    for x=x0,x0+w-1 do
      c=vget(x,y)
      if not found[c] then
        found[c]=true
        add(el,c)
        highest=max(highest,c)
      end
    end
  end

  -- header

  local bits=1
  while highest >= 1<<bits do
    bits+=1
  end

  putnum(w-1)
  putnum(h-1)
  putnum(bits-1)
  putnum(#el-1)
  for i=1,#el do
    putval(el[i],bits)
  end


  -- data

  local pr={} -- predictions

  local dat={}

  for y=y0,y0+h-1 do
    for x=x0,x0+w-1 do
      local v=vget(x,y)  

      local a=0
      if (y>y0) a+=vget(x,y-1)

      -- create vlist if needed
      local l=pr[a]
      if not l then
        l={}
        for i=1,#el do
          l[i]=el[i]
        end
        pr[a]=l
      end

      -- add to vlist
      add(dat,vlist_val(l,v))
      
      -- and to running list
      vlist_val(el, v)
    end
  end

  -- write
  -- store bit-0 as runtime len
  -- start of each run

  local nopredict
  local pos=1

  while pos <= #dat do
    -- count length
    local pos0=pos

    if nopredict then
      while dat[pos]!=1 and pos<=#dat do
        pos+=1
      end
    else
      while dat[pos]==1 and pos<=#dat do
        pos+=1
      end
    end

    local splen = pos-pos0
    putnum(splen-1)

    if nopredict then
      -- values will all be >= 2
      while pos0 < pos do
        putnum(dat[pos0]-2)
        pos0+=1
      end
    end

    nopredict=not nopredict
  end

  if (bit!=1) dest+=1 -- flush

  return dest-dest0
end

__gfx__
ccccccccccccccccccccccccccc11111111111111ccccccccccccc111111111111111111ccccccccc1111111cccc111111111111111111111111111111111111
ccccccccccccccccccc11cccccccc1111111111111111c1111111111111c111cc11ccc111ccccccccc1111111cccc11111111111111111111111111111111111
ccccccccccccccccccc111cc11cccc11cccc1111111111111111111111ccc11cc111ccc11ccccccccccc1111111ccc1111111111111111111111111111111111
cccccccccccccccccccc11cc111ccccc11111ccc11111111111111111ccccccccc11cccccccccccc11cccc1111111cc111111111111111111111111111111111
cccccccccccccccccccccc1cc11cccccc1cccc111111111111111111cccccccccccc11cccccccccc111cc111111111cc11111111111111111111111111111111
cccccccccccccccccccccc11111ccccccccc111111111111111111cccccccccccccc111cccccccccc11c11111111111cc1111111111111111111111111111111
ccccccccccccccccccccccc11111111111111111ccccc11111ccccccccccccccccccc11cccccccccccc11cccc111111111111111111111111111111111111111
ccccccccccccccccccccc11cccccc111111111cc11cccccccccccccccccccccccccccccccccccccccc11cccccc11111111111111111111111111111111111111
cccccccccccccccccccc111cccc11ccccccccc11111cccccccccccccccccccccccccccccccccccccc111ccccccc1111111111111111111111111111111111111
cccccccccccccccccccc11cccc111cccccccc111c11cccccccccccccccccccccccccccccccccccccc11ccccccccc111111111111111111111111111111111111
cccccccccccccccccccccccccc11ccccccccc11cccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccc11ccccccccccc1111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111cc111cccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cc11cccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111ccccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc1111cccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cc111ccc1111ccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccccccc111cc11c1111c111cccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111cc11cccc11cccc111ccccc11cccccccccc1111111111111111111111111111
ccccccccccccfffccccccccccccccccccccccccccccccccccccccccccccccccc11cc111ccccc11111ccc11111111ccccccccc111111111111111111111111111
ccccccccccffff77fccccccccccccccccccccccccccccccccccccccccccccccccc1cc11cccccc1cccc1111111111111111111111111111111111111111111111
cccccccccfff77777fcccccccccccccccccccccccccccccccccccccccccccccccc11111ccccccccc1111111cccc1111111111111111111111111111111111111
cccccccffff777777fccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111ccccccccc11111111111111111111111111111111111
ccccccffff7777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111cc11ccccccccc111111111111111111111111111111111
cccccffff777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccc11ccccccccc11111cccccccccc1111111111111111111111111111111
ccccffff7777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccc111cccccccc111c11ccccccccccccc1111111111111111111111111111
ccccffff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccc11ccccccccc11cccccccccccccccccc111111111111111111111111111
ccccffff77777777777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111
ccccffff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccfff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccffff777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccccfffffff77777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccccfffff7777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccccfffff777777777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccccffffff7777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccc11111111111111111111111111
ccccccfffffff7777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111ccc11111111111111111111111111
77777cffffffff777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc11111111111111111111111111
777777fffffffffffff7777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11c11111111111111111111111111
77777777ffffffff7fff77ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111
77777777ffffff7777fffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11c111111111111111111111111111
777777777777777777ffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111c111111111111111111111111111
777777777777777777fffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc11111111111111111111111111
777777777777777777fffcccf77777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111
7777777777777777777fffff77777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111
7777777777777777777fffff77777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
777777777777777777ffffff777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
7777777777777777777fffff7777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
77777777777777777777fffff77777777777fffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
7777777777777777777777fffffff77777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
777777777777777777777777ffffff77777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
fffff77777777777777777777fffff77777777777fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
ffffff7777777777777777777fffffff777777777fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
fffffff777777777777777777fffffffffffffff7fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc191111111111111111111111111
ffffffff77777777777777777cccccfffcccccccccccccccccccccccccccccccccccccccccccccccccccc9ccccccccccccccc199111111111111111111111111
fffffffff7777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9f9cccccccccccccc9ff911111111111111111111111
ffffffffff77777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccff99ccccccccccccc9ff911111111111111111111111
fffffffffff77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc999999999999999999999911111111111111111111111
fffffffffffffffff7777cccccccccccccccccccffffccccccccccccccccccccccccccccccccccccccc999999999999999999999991111111111111111111111
fffffffffffffff7f77777cccccccccccccffff77777ffcccccccccccccccccccccccccccccccccccc9999999999999999999999991111111111111111111111
ffffffffffffffff77777777ccccccccccffff77777777fcccccccccccccccccccccccccccccccccc99999999999999999999999999111111111111111111111
fffffffffffffffff77777777cccccccfffffff777777777cccccccccccccccccccccccccccccccc999999999999999999999999999111111111111111111111
fffffffffffffffffffff7777ffffffffffffffff7777777fccccccccccccccccccccccccccccccc999999999999999999999999999111111111111111111111
ffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999990099999999999009999999911111111111111111111
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999990099999999999009999999911111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999999999999999999999911111111111111111111
66666666666666666666666666666666666666666666666666666666666666666666666666666699999999999999999999999999999991111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc99999999999999999999999999999991111111111111111111
d6666666666666666666666666666666666666666666666666666666666666666666666666666699999999999999999999999999999999111111111111111111
df66666666666666666666666666666666666666dd66666666666666666666666666666666666999999999944444444449999999999999991111111111111111
ddff6666666666666666666666666666666666ddddf6666666666666666666666666666666666999999999999999999999999999999999999111111111111111
dddf666666666666666666666666666666666ddddddf666666666666666666666666666666669999999999999999999999999999999999999111111111111111
ddfff6666666666666ddd66666666666666ddddddddff66666666666666666666666666666699999999999999999999999999999999999999911111111111111
ddddfd66666666666ddddf666666666666ddddddddffff66666666666666666666666666669999999999ffffffffffffffffff99999999999911111111111111
dddddddd666666ddddddddf666666666dddddddddddffdd77777777777777777777777777799999999ffffffffffffffffffffff999999999911111111111111
dddddddddddddddddddddddfd66666ddddddddddddddddd6666666666666666666666666699999999ffffffffffffffffffffffff99999999991111111111111
dddddddfdddddddddddddddddddddddddddddddddddddddd77777777777777777777777779999999ffffffffffffffffffffffffff9999999991111111111111
dddddddffdddddddddddddddddddddddddddddddddddddddd7777777777777777777777779999999ffffffffffffffffffffffffff9999999991111111111111
ddddddddddddddddddddddddddddddddddddddddddddddddddd77dd7777777777777777777999999ffffffffffffffffffffffffff9999999911111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777779999ffffffffffffffffffffffffff9999991111111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777717177777777779999ffffffffffffffffffffffffff9999991111111111111111
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd717771777777777777999ffffffffffffffffffffffffff9999991111111111111111
ddddddddddddddddddddddddddddddddddddddddd9dddddddddddddddddd71717777777377777999fffffffffffffffffffffffff99999911111111111111111
dddddddddddddddddddddddddddddddddddddddd979ddddddddddddddd1dd1711771777377711999fffffffffffffffff5fffffff99999911111111111111111
ddddddddddddddddddddddddddddddddddedddddd9dddd1ddddddddddd1dd111117111773711199993fff3ffffffffff5fffffff999999111111111111111111
ddddddddddddddddddddddddddddddddde7edddddd3dddd1dddd1dddd1d3d131111111173111109993fff3ffffff5555fffffff9993999111111333111133311
ddddddddddddddddddddddddddddddddddeddddddd3d33d11dddd1d111d3313131111111313300999939933f3fff67ddfff3f999993333333313333333333331
dddddddddddddddddddddddddddddddddd3bdddddd333dddd1d3d1dd11113331311313111337700999393333333367dd39933933333333333311333333333333
ddddddddddddddddddddddddddddddddddbdddbddd3dddddd113301d11313331333333138877773333333333333367dd33333333333333333333333333333333
ddddddddddddddddddddddddddddddddbdbdddddd33dddd33010330333313333113333888777777888888888883367dd33333333333333333333333333333333
ddddddddddddddddddddddddddddddddbbbddddbd33ddddd30133b3333311333133333887733337788888998888867dd23333333333333333333333333333333
ddddddddddddddddddddddddbddddddbbdbdbddb33b33333d33bb333333333333338888877333377888893a9888867dd22888333333333333333333333333333
ddddddddddddddddddddddddbddddddbbdbbbbbb33b33bbbd33bb3333333333333888888873333722889999a9888555528838333333333333333333333333333
dddddddddddddddddddddbdddbdddbbbbdbbbbbbbbb33bbbbbbbbbb3333333333888888888888888888999999888888888883333333333333333333333333333
ddddddddaddddddddddddbbddbbdbbbbbbbbbbbbbbb3bbbbbbbbbbb3333333383888888888888888888899992288888888833333333333333333333333333333
ddddddda7addddddddddddbdbbbdbbbbebbbbbbbbbbbbbbbbbbbbbbbb333388888888888888888888888899228888888388333333333333333333333b3333333
ddddddddaddddddddddbbdbbbbbbbbbe7ebbbbbbbbbbbbbbbbbbbbbbbbb3888888888888888888888888888888888883883333333333333333333333b3333333
dddbdddd3ddddddbd333bdbbbbbbbbbbe3bbbbbbbbbbbbbbbbbbbbbbbbb888bb88888888888888888888888888888883833b3333333b3333b3333333b3333333
dddbdddbbbddddbbd3bbbdbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbb88888b8888888b88888888888888b888888b83333b33bb333b3333b3333333bbb3b333
dddbbdbbbddddbdbdbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8b88bbb8888888888888bb8888b8bbb3b3b33bb333b33333b33b333bbbb3333
dddbbddb3bdbdbddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8b88bbb888bbb8bbb888b88888b88bbbbbbbbbb333bbb333b33b33bbbbb3333
bbdbbbdb3bdbb33dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbb88888b8bbbbbbbbbbb3b3bbbbbbb33bb3bbbbb3333
bbbbbbbb3b3bbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbbbbbbb3bbbb3b333b3333
bbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3333b3333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbb3bbb3bb3333b3333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3bb3bb3333bb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b3bb3bb333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b3333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333bb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbb3333bbb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb33333bb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3b3333333b33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333b33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333bb3333333
bbbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b333bb3333333
bbbbbbbbbb979bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333b33b333bb3333333
bbbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b33b33b333333333
bbbbabbbbbb3bbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bb3b33b333333333
bbba7abbbbbbbbb979bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b33333bb33
bbbba3bbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b33b33bbb3
b3333333333bbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b33b3bbbb
b3bb3bb3bb3bbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbb
b33b3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3b33b33b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb
b3bb3bb3b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
__label__
ccccccccccccccccccccccccccc11111111111111ccccccccccccc111111111111111111ccccccccc1111111cccc111111111111111111111111111111111111
ccccccccccccccccccc11cccccccc1111111111111111c1111111111111c111cc11ccc111ccccccccc1111111cccc11111111111111111111111111111111111
ccccccccccccccccccc111cc11cccc11cccc1111111111111111111111ccc11cc111ccc11ccccccccccc1111111ccc1111111111111111111111111111111111
cccccccccccccccccccc11cc111ccccc11111ccc11111111111111111ccccccccc11cccccccccccc11cccc1111111cc111111111111111111111111111111111
cccccccccccccccccccccc1cc11cccccc1cccc111111111111111111cccccccccccc11cccccccccc111cc111111111cc11111111111111111111111111111111
cccccccccccccccccccccc11111ccccccccc111111111111111111cccccccccccccc111cccccccccc11c11111111111cc1111111111111111111111111111111
ccccccccccccccccccccccc11111111111111111ccccc11111ccccccccccccccccccc11cccccccccccc11cccc111111111111111111111111111111111111111
ccccccccccccccccccccc11cccccc111111111cc11cccccccccccccccccccccccccccccccccccccccc11cccccc11111111111111111111111111111111111111
cccccccccccccccccccc111cccc11ccccccccc11111cccccccccccccccccccccccccccccccccccccc111ccccccc1111111111111111111111111111111111111
cccccccccccccccccccc11cccc111cccccccc111c11cccccccccccccccccccccccccccccccccccccc11ccccccccc111111111111111111111111111111111111
cccccccccccccccccccccccccc11ccccccccc11cccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccc11ccccccccccc1111111111111111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111cc111cccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cc11cccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111ccccccccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc1111cccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cc111ccc1111ccccccccccc111111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccccccc111cc11c1111c111cccccccccc11111111111111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111cc11cccc11cccc111ccccc11cccccccccc1111111111111111111111111111
ccccccccccccfffccccccccccccccccccccccccccccccccccccccccccccccccc11cc111ccccc11111ccc11111111ccccccccc111111111111111111111111111
ccccccccccffff77fccccccccccccccccccccccccccccccccccccccccccccccccc1cc11cccccc1cccc1111111111111111111111111111111111111111111111
cccccccccfff77777fcccccccccccccccccccccccccccccccccccccccccccccccc11111ccccccccc1111111cccc1111111111111111111111111111111111111
cccccccffff777777fccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111ccccccccc11111111111111111111111111111111111
ccccccffff7777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111cc11ccccccccc111111111111111111111111111111111
cccccffff777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccc11ccccccccc11111cccccccccc1111111111111111111111111111111
ccccffff7777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccc111cccccccc111c11ccccccccccccc1111111111111111111111111111
ccccffff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccc11ccccccccc11cccccccccccccccccc111111111111111111111111111
ccccffff77777777777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111111
ccccffff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccfff77777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccffff777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccccfffffff77777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccccfffff7777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
ccccccccfffff777777777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
cccccccffffff7777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11cccc11111111111111111111111111
ccccccfffffff7777777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111ccc11111111111111111111111111
77777cffffffff777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc11111111111111111111111111
777777fffffffffffff7777fccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11c11111111111111111111111111
77777777ffffffff7fff77ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111111
77777777ffffff7777fffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11c111111111111111111111111111
777777777777777777ffffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111c111111111111111111111111111
777777777777777777fffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11ccc11111111111111111111111111
777777777777777777fffcccf77777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111
7777777777777777777fffff77777777fcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc1111111111111111111111111
7777777777777777777fffff77777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
777777777777777777ffffff777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc11111111111111111111111111
7777777777777777777fffff7777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
77777777777777777777fffff77777777777fffffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
7777777777777777777777fffffff77777777777ffccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
777777777777777777777777ffffff77777777777ffcccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
fffff77777777777777777777fffff77777777777fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
ffffff7777777777777777777fffffff777777777fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc111111111111111111111111111
fffffff777777777777777777fffffffffffffff7fffccccccccccccccccccccccccccccccccccccccccccccccccccccccccc191111111111111111111111111
ffffffff77777777777777777cccccfffcccccccccccccccccccccccccccccccccccccccccccccccccccc9ccccccccccccccc199111111111111111111111111
fffffffff7777777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9f9cccccccccccccc9ff911111111111111111111111
ffffffffff77777777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccff99ccccccccccccc9ff911111111111111111111111
fffffffffff77777777777ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc999999999999999999999911111111111111111111111
fffffffffffffffff7777cccccccccccccccccccffffccccccccccccccccccccccccccccccccccccccc999999999999999999999991111111111111111111111
fffffffffffffff7f77777cccccccccccccffff77777ffcccccccccccccccccccccccccccccccccccc9999999999999999999999991111111111111111111111
ffffffffffffffff77777777ccccccccccffff77777777fcccccccccccccccccccccccccccccccccc99999999999999999999999999111111111111111111111
fffffffffffffffff77777777cccccccfffffff777777777cccccccccccccccccccccccccccccccc999999999999999999999999999111111111111111111111
fffffffffffffffffffff7777ffffffffffffffff7777777fccccccccccccccccccccccccccccccc999999999999999999999999999111111111111111111111
ffffffffffff7fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff999990099999999999009999999911111111111111111111
fffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffffff9999990099999999999009999999911111111111111111111
ccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc9999999999999999999999999999911111111111111111111
66666666666666666666666666666666666666666666666666666666666666666666666666666699999999999999999999999999999991111111111111111111
cccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccccc99999999999999999999999999999991111111111111111111
d6666666666666666666666666666666666666666666666666666666666666666666666666666699999999999999999999999999999999111111111111111111
df66666666666666666666666666666666666666dd66666666666666666666666666666666666999999999944444444449999999999999991111111111111111
ddff6666666666666666666666666666666666ddddf6666666666666666666666666666666666999999999999999999999999999999999999111111111111111
dddf666666666666666666666666666666666ddddddf666666666666666666666666666666669999999999999999999999999999999999999111111111111111
ddfff6666666666666ddd66666666666666ddddddddff66666666666666666666666666666699999999999999999999999999999999999999911111111111111
ddddfd66666666666ddddf666666666666ddddddddffff66666666666666666666666666669999999999ffffffffffffffffff99999999999911111111111111
dddddddd666666ddddddddf666666666dddddddddddffdd77777777777777777777777777799999999ffffffffffffffffffffff999999999911111111111111
dddddddddddddddddddddddfd66666ddddddddddddddddd6666666666666666666666666699999999ffffffffffffffffffffffff99999999991111111111111
dddddddfdddddddddddddddddddddddddddddddddddddddd77777777777777777777777779999999ffffffffffffffffffffffffff9999999991111111111111
dddddddffdddddddddddddddddddddddddddddddddddddddd7777777777777777777777779999999ffffffffffffffffffffffffff9999999991111111111111
ddddddddddddddddddddddddddddddddddddddddddddddddddd77dd7777777777777777777999999ffffffffffffffffffffffffff9999999911111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddd777777777777777777779999ffffffffffffffffffffffffff9999991111111111111111
dddddddddddddddddddddddddddddddddddddddddddddddddddddddddd7777717177777777779999ffffffffffffffffffffffffff9999991111111111111111
ddddddddddddddddddddddddddddddddddddddddddddddddddddddddddd717771777777777777999ffffffffffffffffffffffffff9999991111111111111111
ddddddddddddddddddddddddddddddddddddddddd9dddddddddddddddddd71717777777377777999fffffffffffffffffffffffff99999911111111111111111
dddddddddddddddddddddddddddddddddddddddd979ddddddddddddddd1dd1711771777377711999fffffffffffffffff5fffffff99999911111111111111111
ddddddddddddddddddddddddddddddddddedddddd9dddd1ddddddddddd1dd111117111773711199993fff3ffffffffff5fffffff999999111111111111111111
ddddddddddddddddddddddddddddddddde7edddddd3dddd1dddd1dddd1d3d131111111173111109993fff3ffffff5555fffffff9993999111111333111133311
ddddddddddddddddddddddddddddddddddeddddddd3d33d11dddd1d111d3313131111111313300999939933f3fff67ddfff3f999993333333313333333333331
dddddddddddddddddddddddddddddddddd3bdddddd333dddd1d3d1dd11113331311313111337700999393333333367dd39933933333333333311333333333333
ddddddddddddddddddddddddddddddddddbdddbddd3dddddd113301d11313331333333138877773333333333333367dd33333333333333333333333333333333
ddddddddddddddddddddddddddddddddbdbdddddd33dddd33010330333313333113333888777777888888888883367dd33333333333333333333333333333333
ddddddddddddddddddddddddddddddddbbbddddbd33ddddd30133b3333311333133333887733337788888998888867dd23333333333333333333333333333333
ddddddddddddddddddddddddbddddddbbdbdbddb33b33333d33bb333333333333338888877333377888893a9888867dd22888333333333333333333333333333
ddddddddddddddddddddddddbddddddbbdbbbbbb33b33bbbd33bb3333333333333888888873333722889999a9888555528838333333333333333333333333333
dddddddddddddddddddddbdddbdddbbbbdbbbbbbbbb33bbbbbbbbbb3333333333888888888888888888999999888888888883333333333333333333333333333
ddddddddaddddddddddddbbddbbdbbbbbbbbbbbbbbb3bbbbbbbbbbb3333333383888888888888888888899992288888888833333333333333333333333333333
ddddddda7addddddddddddbdbbbdbbbbebbbbbbbbbbbbbbbbbbbbbbbb333388888888888888888888888899228888888388333333333333333333333b3333333
ddddddddaddddddddddbbdbbbbbbbbbe7ebbbbbbbbbbbbbbbbbbbbbbbbb3888888888888888888888888888888888883883333333333333333333333b3333333
dddbdddd3ddddddbd333bdbbbbbbbbbbe3bbbbbbbbbbbbbbbbbbbbbbbbb888bb88888888888888888888888888888883833b3333333b3333b3333333b3333333
dddbdddbbbddddbbd3bbbdbbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbb88888b8888888b88888888888888b888888b83333b33bb333b3333b3333333bbb3b333
dddbbdbbbddddbdbdbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8b88bbb8888888888888bb8888b8bbb3b3b33bb333b33333b33b333bbbb3333
dddbbddb3bdbdbddbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8b88bbb888bbb8bbb888b88888b88bbbbbbbbbb333bbb333b33b33bbbbb3333
bbdbbbdb3bdbb33dbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbb88888b8bbbbbbbbbbb3b3bbbbbbb33bb3bbbbb3333
bbbbbbbb3b3bbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb8bbbbbbbbbbbbbbbbbbbbbbb3bbbb3b333b3333
bbbbbbbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb3333b3333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bbbb3bbb3bb3333b3333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b3b3bb3bb3333bb333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b3b3bb3bb333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333b3333333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333bb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3b3bbb3333bbb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3bb33333bb33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bb3b3333333b33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333333333333b33333333
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33333333333bb3333333
bbbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333333b333bb3333333
bbbbbbbbbb979bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3333b33b333bb3333333
bbbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b33b33b333333333
bbbbabbbbbb3bbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33bb3b33b333333333
bbba7abbbbbbbbb979bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b33333bb33
bbbba3bbbbbbbbbb9bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb33b33b33bbb3
b3333333333bbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb333b33b3bbbb
b3bb3bb3bb3bbbbbb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbbbbb
b33b3bb3bb3bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3b33b33b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb3bbb
b3bb3bb3b33bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
b3333333333bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb
bbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbbb

__gff__
0081030301811303030301010000010003030101010103030101000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
0000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000000
__map__
fffffff0ffff0ffd89e32fc19aa67c51f47fc01ffcc05f7c3c8cff11bf818b9b851f420042b8c21112fee70148c0f8f821e008c20b0a84ff733842c042f8295c940f8c62f83f23e01906fe092f3811f00dff6fc641c03fe046f8427887ff73183f50caf8851bc3f87ff12338f818ffb342f9df13065ec2ff8a7084ff3fc0022e
12f03fe3e37fce013ef0bfe6ff2ff0ff57f8ffd360e003ff7f3a20bce1ff1f87833ff8ffc760fcc1ffbf0eff7f1f08c0cdff82ffbf03168484ff7f0bce4258085ff8ff8f0148180290e10bff3309ffd3702402168431aef07f927593ff2732788681ff215f0207ff5719070165fc9f780438c2ff344c7e201cfcdf643ce07fca
c107c1c7ff4ac617fec782977081ff8f8c13fc6f255c24e024fc2fc3ff990ffcc5ffdfe4ff007ee7ff8f12fe1789ffff6f08c0ffff178430feff7ea83c82ffffcd8df0ffafc31fe0ffdf08fe47899ff8ff3f89ff83952b9c99ff3f13fe47f2519af8ff3730e17f22e40a02feffd2f03b7f3090c4ffff41f89d4b4e59e2ffff10
fe9784ffff44f81f72642be4ff6f70f0ff4b207cfcff6ffe08ffffc4fe871c5c25f9ffd3e18fc2ffdf90ff6558f82095ffbf4c180f1bfeff3168380bff7f8df25bf82bfcffbdf02ff8ffafe1672efeff43ea7f127e92121ef93fa6fe59f8972bc98ffcaf63f883f12b5ff843feffc3f0bf4df2caff5f88fe0f79e59025fe92f1
ff17c2ff6963a91f648941fe47f6bfe497851a3933e1e37f633f871ff9273c591e3bc233c9ffc4fea7fcc498fd012ef9ff83e1e27fc0ffc881173ce1ff8fcae1f8ffd9ff5f73fcff3cffffc9fe17e137fbffff865cf9ffc7e1afede8ffca85ff8fe3f49dfc007eca35f2bfb125f9ff2be12ffbdf4827f99fd8ffba8fe4070b7f
8027c9ffc2fe57e11fccf2b22cb75c24c9ffc04efb8bbf198c1c5c593e7901d7ff07fcc7ff843f6a567ef2fcedb8c2af7ce1bff00b3fdbff24fcccff22fcbf72f5ffbff1bf03c05f791cfc6f1cff7f83f29790ff91fcff1bd03e38f9ffcf8d90c299f8fff07fcffc744402474eff173b12fff3087ed90c32421c83849ff2faff
17b9355f9bf885091c5442963709e7c66187fd7f930b5d5ed9350bc391385dc3f26c9c520e494e1f6184ff4f729f40220d04b2c44190cbd67110b2efb93a721096b8c3ff66d70f1eb19a6382a06982157ce8210924d22542867be2e5ff931f2493e8f1894d481cf4e08f3f8ec439f99ff0bfdc18310cdd6e2091c58365e569ea
95f1ff3f2258788e438207cd6152c006ea43f4c82ff97f87030788d0c31124f9411f4ef80707f63591ff2faf9c96f0931cfb83ee975f58f201d9fbc70f512bbff363c242001e0b0d07a75d76f2f9e30abf73e51f3f2432fc232fd7c25ff9c5f6cf7cf27fe049863790d09c4ef983097e4c62e109f831f1479e7f5e802b825f11
f9594e0cff0712e678466d9cfbe1cadf810fff0f88c41316fe4c6018fe083fe70fe34afc118e400ef0138667482a18c6ff499e05841fc0020c7f6c08214308f922c0c2ff949384302b022e063eca41c27158e2ffca4f213cdc618c845b2e09ffff28fc4a00c20f24fcff557280f00fff7f120ce0ffbf0f06e00affff39fc42f9
ffc724349cfcffe9d0808bff3f5c1046f8ffeb0316feff3f8087ffbfcecbff3f0f77f82b8fff3f1bfe8c0fff7f34fc9c7fbeffbf19be081e967f1c9e66feff6148f82909ca92e0ff7f7281ee49cec4ffdf0d0bece408ffff7430044110f0ff7f2938863ff8ffd70f20e0ff6f872308ff7f9d868fffffceffff2f000000000000
