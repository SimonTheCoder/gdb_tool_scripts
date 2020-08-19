
define lk
    target remote :1234

end
document lk
    Attache to remote 127.0.0.1:1234
end

define qr
    monitor system_reset
    tb *0x0
    c
end
document qr
    Reset QEMU and stop @0x00000000.
end

define xp
    monitor xp $arg0 $arg1
end
document xp
xp /fmt addr -- physical memory dump starting at 'addr'
end

python
import gdb

def get_phy_value():
    addr = gdb.convenience_variable("_SIMON_QEMU_PHY_ADDR")
    raw_phy_get = gdb.execute("monitor xp /x 0x%x" % (addr),True,True)
    #print(raw_phy_get)
    value = int(raw_phy_get.split(":")[1],16)
    gdb.set_convenience_variable("_SIMON_QEMU_PHY_VALUE",value)
    #print("addr:%x    value:%x"%(addr,value))
end
define get_phy_value
    set $addr = $arg0
    set $_SIMON_QEMU_PHY_ADDR = $addr
    py get_phy_value()
end
document get_phy_value
    get_phy_value PHY_ADDR ,value will be returned in $_SIMON_QEMU_PHY_VALUE
end

set $SIMON_QEMU_LOADED=1