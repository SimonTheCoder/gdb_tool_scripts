define page_walk_lpae
#arg0 ttbr_value , &def_ttbl for xvisor
#arg1 va
#test case: page_walk &def_ttbl 0x80efc000
    set $va = (unsigned long)$arg1
    set $page_dir = (unsigned long)$arg0
    set $lv1_pte_ptr = (unsigned long *) ($page_dir + (($va >> 30) * 8))
    set $lv1_pte =*(unsigned long *) ($page_dir + (($va >> 30) * 8))

    printf "lv1 table ptr = 0x%x, va = 0x%x \n",$page_dir,$va

    set $lv1_pte_type = $lv1_pte & 0x00000003 
    printf "lv1 pte_ptr = 0x%x, pte = 0x%llx type=%d(0:Invalid,1:Block,3:Table)\n",$lv1_pte_ptr,$lv1_pte,$lv1_pte_type

    if ($lv1_pte_type != 3)
       printf "Walk end.\n"
        
    else
       #lv2 walk
       set $lv2_page_dir = $lv1_pte & 0xfffff000
       set $lv2_pte_ptr = (unsigned long *) ($lv2_page_dir + (( ($va & 0x3fffffff) >> 21) * 8))
       set $lv2_pte = *(unsigned long *) ($lv2_page_dir + (( ($va & 0x3fffffff) >> 21) * 8))
       set $lv2_pte_type = $lv2_pte & 0x00000003
       printf "lv2 pagetable = 0x%x, pte_ptr = 0x%x ,pte = 0x%llx type=%d(0,1:Invalid,3:Valid)\n",$lv2_page_dir,$lv2_pte_ptr,$lv2_pte,$lv2_pte_type

       
      if ($lv2_pte_type != 3)
          printf "Walk Failed!\n"

      else
          #lv3 walk

          set $lv3_page_dir = $lv2_pte & 0xfffff000
          set $lv3_pte_ptr = (unsigned long *) ($lv3_page_dir + (( ($va & 0x1fffff) >> 12) * 8))
          set $lv3_pte = *(unsigned long *) ($lv3_page_dir + (( ($va & 0x1fffff) >> 12) * 8))
          set $lv3_pte_type = $lv3_pte & 0x00000003
          printf "lv3 pagetable = 0x%x, pte_ptr = 0x%x ,pte = 0x%llx type=%d(0,1:Invalid,3:Valid)\n",$lv3_page_dir,$lv3_pte_ptr,$lv3_pte,$lv3_pte_type
          set $pa = ($lv3_pte & 0xfffff000) + ($va & 0x00000fff)
          printf "pa = 0x%x\n",$pa

      end

    end
end
document page_walk_lpae
#arg0 ttbr_value , &def_ttbl for xvisor
#arg1 va
end
