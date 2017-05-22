# WHERE MODIFIED

##lab1:

- kdebug.c
  - print_stackframe
- trap.c
  - idt_init
  - trap_dispatch



##lab2:

- default_pmm.c
  - init_memmap
  - alloc_pages
  - free_pages
- pmm.c
  - get_pte
  - page_remove_pte



## lab3:

* vmm.c
  * do_pgfault
* swap_fifo.c
  * _fifo_map_swappable
  * _fifo_swap_out_victim
  * _extended_clock_swap_out_victim
  * _extended_clock_check_swap

## lab4:

* proc.c
  * alloc_proc
  * do_fork

## lab5:

* trap.c
  - idt_init
  - trap_dispatch
* proc.c
  * alloc_proc
  * do_fork
  * load_icode
* pmm.c
  * copy_range

## lab6:

* trap.c
  * trap_dispatch
* proc.c
  - alloc_proc

sched_class_proc_tick without static

* default_sched.c



## lab7:

* check_sync.c
* moniter.c