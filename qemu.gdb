
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
