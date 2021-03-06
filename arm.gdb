define aarch64_mmu_off
    aarch64_get_sctlr_el3
    $result_sctlr_el3 = $result_sctlr_el3 & (~1)
    aarch64_set_sctlr_el3 $result_sctrl_el3
end

define aarch64_mmu_on
    aarch64_get_sctlr_el3
    $result_sctlr_el3 = $result_sctlr_el3 | (~1)
    aarch64_set_sctlr_el3 $result_sctlr_el3

end

define aarch64_get_sctlr_el3
    arm_run_one_op 64 0xd53e100f
    set $result_sctlr_el3 = $arm_run_one_op_result_1 
end

define aarch64_set_sctlr_el3
    set $reg_value = $arg0
    set $save_x15 = $x15
    #   0:	d51e100f 	msr	sctlr_el3, x15
    arm_run_one_op 64 0xd51e100f
    set $x15 = $save_x15
end


define arm_human_read_psr
    set $psr = $arg0
    set $is_aarch32 = 0
    if ( $psr & (1<<4)) 
        printf "AARCH32 "
        set $is_aarch32 = 1
    else
        printf "AARCH64 "
    end
    

    if ($is_aarch32 !=1)
        printf "Mode: EL%d",($psr>>2) & 0x3
        if ($psr & 0x1)
            printf "t (SP_EL0)\n"
        else 
            printf "h (SP_ELx)\n"
        end
    end
    if ($is_aarch32 ==1)
        set $mode_found = 0
        printf "Mode(0x%x): ",$mode
        set $mode = $psr & 0xf
        if ($mode == 0x0)
            printf "User\n"
            set $mode_found = 1
        end
        if ($mode == 0x1)
            printf "FIQ\n"
            set $mode_found = 1
        end
        if ($mode == 0x2)
            printf "IRQ\n"
            set $mode_found = 1
        end
        if ($mode == 0x3)
            printf "Supervisor\n"
            set $mode_found = 1
        end
        if ($mode == 0x6)
            printf "Monitor\n"
            set $mode_found = 1
        end
        if ($mode == 0x7)
            printf "Abort\n"
            set $mode_found = 1
        end
        if ($mode == 0xa)
            printf "Hyper\n"
            set $mode_found = 1
        end
        if ($mode == 0xb)
            printf "Undefined\n"
            set $mode_found = 1
        end
        if ($mode == 0xf)
            printf "System\n"
            set $mode_found = 1
        end
        if $mode_found == 0 
            printf "Unknown(0x%x)\n", $mode
        end
    end

    printf "SError Mask: %d\n", ($psr>>8) & 0x1
    printf "IRQ Mask: %d\n", ($psr>>7) & 0x1
    printf "FIQ Mask: %d\n", ($psr>>6) & 0x1
    if ($is_aarch32 !=1)
        printf "SS: %d    \t//The Software Step bit.\n", ($psr>>21) & 0x1
        printf "IL: %d    \t//Illegal Execution State bit.\n", ($psr>>20) & 0x1
        printf "D: %d    \t//Debug exception mask bit.\n", ($psr>>9) & 0x1
    end

    if ($is_aarch32 == 1)
        printf "T: %d\n", ($psr>>5) & 0x1
        printf "E: %d\n", ($psr>>9) & 0x1
        
    end
end


define aarch64_get_esr_el3
    arm_run_one_op 64 0xd53e520f
    printf "ESR_EL3: 0x%x\n",$arm_run_one_op_result_1
    aarch64_human_read_esr_elx $arm_run_one_op_result_1
end

define aarch64_human_read_esr_elx
    set $esr = $arg0

    printf "EC: 0x%x\n",$esr>>26
    printf "IL: %d\n",($esr>>25) & 0x1
    printf "ISS: 0x%x\n",($esr & (~0xFE000000))

end

define aarch64_get_far_el3
    arm_run_one_op 64 0xd53e600f
    printf "FAR_EL3: 0x%x\n",$arm_run_one_op_result_1

end


define aarch64_get_ttbr0_el1

    arm_run_one_op 64 0xd538200f
    printf "TTBR0_EL1: 0x%x\n",$arm_run_one_op_result_1
    printf "Table Addr: 0x%x\n",$arm_run_one_op_result_1 & 0xffffffffffff 
    printf "ASID: 0x%x\n", $arm_run_one_op_result_1 >> 48

end
define aarch64_get_ttbr1_el1

    arm_run_one_op 64 0xd538202f
    printf "TTBR1_EL1: 0x%x\n",$arm_run_one_op_result_1
    printf "Table Addr: 0x%x\n",$arm_run_one_op_result_1 & 0xffffffffffff 
    printf "ASID: 0x%x\n", $arm_run_one_op_result_1 >> 48

end


define aarch64_get_currentel
    arm_run_one_op 64 0xd538424f
    printf "Current EL: %d\n",$arm_run_one_op_result_1>>2

end
document aarch64_get_currentel
    Show current EL
end

define aarch64_get_sctlr_el1
    arm_run_one_op 64 0xd538100f 
    printf "SCTLR_EL1: 0x%llx\n",$arm_run_one_op_result_1
    aarch64_human_read_sctlr_elx $arm_run_one_op_result_1

end

define aarch64_va2pa
    set $temp_save_reg = $x15
    set $va = $arg1
    set $x15 = $va
    set $op_code = $aarch64_at_ins($arg0, "x15")
    arm_run_one_op 64 $op_code
    set $x15 = $temp_save_reg
    set $PAR = (unsigned long)$PAR_EL1

    if(($PAR & 0x1) == 0)
        printf "PAR_EL1: %lx\n",$PAR_EL1
        set $page_addr = $PAR & (((unsigned long)1<<48)-1) & ((-1UL)<<12) 
        printf "Page paddr:%lx\n",$page_addr
        printf "Paddr: %lx\n",($page_addr + ((unsigned long)$va & 0xfff))    

    else
        printf "Translation Failed.\n"
    end
end
document aarch64_va2pa
    arg0: AT instruction tag. e.g.:"S1E1W"
    arg1: VA
end

define aarch64_human_read_sctlr_elx
    set $reg_vale = $arg0

    printf "ICache: %d\n",($reg_vale>>12) & 0x1
    printf "DCache: %d\n",$reg_vale & 0x3
    printf "Alignment check: %d\n",$reg_vale & 0x2
    printf "MMU: %d\n",$reg_vale & 0x1

end

python
import gdb
class AARCH64_asm(gdb.Function):
    """assemble aarch64 instructions
    param: instruction, string
    """
    def __init__ (self):
        super (AARCH64_asm, self).__init__ ("aarch64_asm")

    def invoke (self, ins):
        #print("Instruction: %s" % ins)
        command = """echo %s | aarch64-linux-gnu-as -o /tmp/simon_asm.elf && aarch64-linux-gnu-objdump -d /tmp/simon_asm.elf|grep '0:'|awk '{print $2}'"""
        import subprocess
        raw_code = subprocess.check_output(command % (ins), shell=True)
        code = int(raw_code,16)
        #print("Code:        0x%x" % (code))
        return code 
aarch64_asm = AARCH64_asm()

class AARCH64_AT_instruction(gdb.Function):
    def __init__(self):
        super (AARCH64_AT_instruction, self).__init__("aarch64_at_ins")

    def invoke (self, tag, reg):
        return aarch64_asm.invoke("AT %s,%s" % (tag,reg))
AARCH64_AT_instruction()
end

define aarch64_asm
    printf "assemble: 0x%x\n",$aarch64_asm($arg0)
end

define aarch32_get_ttbr0
    #0:	ee125f10 	mrc	15, 0, r5, cr2, cr0, {0} 
    arm_run_one_op 32 0xee125f10
    printf "ttbr0: 0x%x\n",$arm_run_one_op_result_1
end
define aarch32_get_ttbr1
    #0:	ee125f30 	mrc	15, 0, r5, cr2, cr0, {1}
    arm_run_one_op 32 0xee125f30
    printf "ttbr1: 0x%x\n",$arm_run_one_op_result_1
end
define aarch32_get_ttbcr
    #0:	ee125f50 	mrc	15, 0, r5, cr2, cr0, {2}
    arm_run_one_op 32 0xee125f50
    printf "ttbcr: 0x%x\n",$arm_run_one_op_result_1
end

define aarch32_human_read_ttbrx
    set $ttbrx = $arg0

    printf "Level1 table: 0x%x\n", $ttbrx & 0xfffff000
    set $ttbrx_s = $ttbrx & (1<<1) && 1
    printf "S (Shareable bit): %d\n", $ttbrx_s
    printf "NOS (Not Outer Shareable bit): "
    if $ttbrx_s == 0
        printf "Ignored\n"
    else
        printf "%d\n",$ttbrx & (1<<5) && 1
    end


end

##################################################################
define arm_run_one_op
     
    #use current PC as run point
    set $TEMP_MEM = $pc
    set $OP_HEX = (unsigned int)$arg1
    
    #save current opcode
    set $save_op = *(unsigned int *)$TEMP_MEM

    set $save_reg_1 = 0
    set $save_reg_2 = 0

    #save regs
    if($arg0 == 32)
        set $save_reg_1 = $r5 
        set $save_reg_2 = $r6
    else
        set $save_reg_1 = $x15 
        set $save_reg_2 = $x16
    end

    #fill opcode into mem
    set *(unsigned int *)$TEMP_MEM = $OP_HEX
    
    #run code
    si

    #get results & restore the regs
    if($arg0 == 32)
        set $arm_run_one_op_result_1= $r5 
        set $arm_run_one_op_result_2= $r6
        set $r5 = $save_reg_1
        set $r6 = $save_reg_2
    else
        set $arm_run_one_op_result_1= $x15 
        set $arm_run_one_op_result_2= $x16
        set $x15 = $save_reg_1
        set $x16 = $save_reg_2
    end

    #restore pc
    set $pc = $TEMP_MEM

    #restore code
    set *(unsigned int *)$TEMP_MEM = $save_op
end
document arm_run_one_op
    arg0 bit [32|64]
    arg1 opcode
    r5,r6 or x15,x16 must be used as dst or src regs.
    use $arm_run_one_op_result_1,$arm_run_one_op_result_2 to receive result
end


##################################################################
define aarch64_page_walk
#need page table 1:1 mapped, granule size is 4KB
#arg0 ttbr_value , &def_ttbl for xvisor
#arg1 va
#arg2 which level to init walking from.

    set $init_form_lv1 = $arg2
    set $va = (unsigned long)$arg1
    set $page_dir = (unsigned long)$arg0 & 0xFFFFFFFFF000
    printf "page dir=%lx, VA=%lx\n",$page_dir,$va 
    set $SIMON_QEMU_LOADED= $SIMON_QEMU_LOADED && $SIMON_QEMU_LOADED
    #lv0 
    set $lv0_pte_ptr = ($arg0 & 0xFFFFFFFFF000) + ( ( ($va >>39) & 0x1ff )*8 ) 
    if $SIMON_QEMU_LOADED == 1
        set $lv0_pte = $dpa($lv0_pte_ptr)
    else
        set $lv0_pte = *(unsigned long *) $lv0_pte_ptr
    end
    set $lv0_pte_type = $lv0_pte & 0x3
    printf "lv0 pagetable_dir = 0x%lx,  pte_ptr = 0x%lx, pte = 0x%lx type=%d(0,1:Invalid,3:Table)\n",$page_dir,$lv0_pte_ptr,$lv0_pte,$lv0_pte_type
    if($lv0_pte_type != 3 || $init_form_lv1==1)
        #printf "Bad page dir gaven!!!\n"
        #printf "%d\n",__GDB_EXCEPTION_RISE
        printf "Try init walk from level 1 table.\n"
        set $lv0_pte = $arg0
    end
    set $lv1_page_dir = $lv0_pte & 0xFFFFFFFFF000
    set $lv1_pte_ptr = (unsigned long *) ($lv1_page_dir + ((($va >> 30)&0x1ff) * 8))

    if $SIMON_QEMU_LOADED == 1
        set $lv1_pte = $dpa($lv1_pte_ptr)
    else
        set $lv1_pte =*(unsigned long *) ($lv1_pte_ptr)
    end
    set $lv1_pte_type = $lv1_pte & 0x00000003
    printf "lv1 pagetable_dir = 0x%lx,  pte_ptr = 0x%lx, pte = 0x%llx type=%d(0:Invalid,1:Block,3:Table)\n",$lv1_page_dir,$lv1_pte_ptr,$lv1_pte,$lv1_pte_type

    if($lv1_pte_type == 0)
        #Block
        printf "Walk Failed\n"

    end

    if ($lv1_pte_type == 1)
        set $lv1_block_output_address = $lv1_pte & 0xFFFFC0000000
        printf "Block found: PA = 0x%llx\n",($lv1_block_output_address + ($va & 0x3FFFFFFF))
    end

    if ($lv1_pte_type == 3)
       #lv2 walk
       set $lv2_page_dir = $lv1_pte & 0xfffffffff000
       set $lv2_pte_ptr = (unsigned long *) ($lv2_page_dir + (( ($va & 0x3fffffff) >> 21) * 8))

       if $SIMON_QEMU_LOADED == 1
           set $lv2_pte = $dpa($lv2_pte_ptr)
       else
           set $lv2_pte = *(unsigned long *) $lv2_pte_ptr 
       end
       set $lv2_pte_type = $lv2_pte & 0x00000003
       printf "lv2 pagetable = 0x%x, pte_ptr = 0x%x ,pte = 0x%llx type=%d(0:Invalid,1:Block,3:Table)\n",$lv2_page_dir,$lv2_pte_ptr,$lv2_pte,$lv2_pte_type
       if($lv2_pte_type == 0)
           #Block
           printf "Walk Failed\n"

       end
       if($lv2_pte_type == 1)
           #Block
           set $lv2_block_output_address = $lv2_pte & 0xFFFFFFE00000
           printf "Block found: PA = 0x%llx\n",(($lv2_block_output_address) + ($va & 0x0FFFFF))

       end

       
      if ($lv2_pte_type == 3)
          #lv3 walk

          set $lv3_page_dir = $lv2_pte & 0xfffffffff000
          set $lv3_pte_ptr = (unsigned long *) ($lv3_page_dir + (( ($va & 0x1fffff) >> 12) * 8))
          if $SIMON_QEMU_LOADED == 1
              set $lv3_pte = $dpa($lv3_pte_ptr)
          else
              set $lv3_pte = *(unsigned long *) $lv3_pte_ptr 
          end
          set $lv3_pte_type = $lv3_pte & 0x00000003
          printf "lv3 pagetable = 0x%x, pte_ptr = 0x%x ,pte = 0x%llx type=%d(0,1:Invalid,3:Valid)\n",$lv3_page_dir,$lv3_pte_ptr,$lv3_pte,$lv3_pte_type
          set $pa = ($lv3_pte & 0xfffffffff000) + ($va & 0x00000fff)
          printf "pa = 0x%x\n",$pa

      end

    end
end
document  aarch64_page_walk
arg0 ttbr_value , &def_ttbl for xvisor
arg1 va
arg2 init walking table level , 0 or 1

If target is QEMU, with qemu.gdb , this command can read phy Addr.
end
