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

define aarch64_human_read_sctlr_elx
    set $reg_vale = $arg0

    printf "ICache: %d\n",($reg_vale>>12) & 0x1
    printf "DCache: %d\n",$reg_vale & 0x3
    printf "Alignment check: %d\n",$reg_vale & 0x2
    printf "MMU: %d\n",$reg_vale & 0x1

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
    set $va = (unsigned long)$arg1
    set $page_dir = (unsigned long)$arg0
    printf "page dir=%x, VA=%x\n",$page_dir,$va 
    #lv0 
    set $lv0_pte_ptr = ($arg0 & 0xFFFFFFFFE000) + (($va >>39)*8) 
    set $lv0_pte = *(unsigned long *) $lv0_pte_ptr
    set $lv0_pte_type = $lv0_pte & 0x3
    printf "lv0 pagetable_dir = 0x%x,  pte_ptr = 0x%x, pte = 0x%llx type=%d(0,1:Invalid,3:Table)\n",$page_dir,$lv0_pte_ptr,$lv0_pte,$lv0_pte_type
    if($lv0_pte_type != 3)
        printf "Bad page dir gaven!!!\n"
        printf "%d\n",__GDB_EXCEPTION_RISE

    end
    set $lv1_page_dir = $lv0_pte & 0xFFFFFFFFF000
    set $lv1_pte_ptr = (unsigned long *) ($lv1_page_dir + (($va >> 30) * 8))
    set $lv1_pte =*(unsigned long *) ($lv1_pte_ptr)
    set $lv1_pte_type = $lv1_pte & 0x00000003
    printf "lv1 pagetable_dir = 0x%x,  pte_ptr = 0x%x, pte = 0x%llx type=%d(0:Invalid,1:Block,3:Table)\n",$lv1_page_dir,$lv1_pte_ptr,$lv1_pte,$lv1_pte_type

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
       set $lv2_pte = *(unsigned long *) ($lv2_page_dir + (( ($va & 0x3fffffff) >> 21) * 8))
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
          set $lv3_pte = *(unsigned long *) ($lv3_page_dir + (( ($va & 0x1fffff) >> 12) * 8))
          set $lv3_pte_type = $lv3_pte & 0x00000003
          printf "lv3 pagetable = 0x%x, pte_ptr = 0x%x ,pte = 0x%llx type=%d(0,1:Invalid,3:Valid)\n",$lv3_page_dir,$lv3_pte_ptr,$lv3_pte,$lv3_pte_type
          set $pa = ($lv3_pte & 0xfffffffffffff000) + ($va & 0x00000fff)
          printf "pa = 0x%x\n",$pa

      end

    end
end
document  aarch64_page_walk
arg0 ttbr_value , &def_ttbl for xvisor
arg1 va
end
