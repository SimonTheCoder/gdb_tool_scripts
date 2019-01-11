
define u-boot_aarch64_load_sym_after_reloc
    symbol-file $arg0

    #ref:static inline gd_t *get_gd(void)
    set $relocaddr = ((struct global_data *)$x18)->relocaddr

    #drop symbol
    #symbol_file
    
    add-symbol-file $arg0 $relocaddr
end
document u-boot_aarch64_load_sym_after_reloc
#arg0 u-boot file with symbol info.
end

define u-boot_arm_load_sym_after_reloc
    symbol-file $arg0

    #ref:static inline gd_t *get_gd(void)
    set $relocaddr = ((struct global_data *)$r9)->relocaddr

    #drop symbol
    #symbol_file
    
    add-symbol-file $arg0 $relocaddr
end
document u-boot_aarch64_load_sym_after_reloc
#arg0 u-boot file with symbol info.
end
