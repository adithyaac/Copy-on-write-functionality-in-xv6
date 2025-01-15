// Physical memory allocator, for user processes,
// kernel stacks, page-table pages,
// and pipe buffers. Allocates whole 4096-byte pages.

#include "types.h"
#include "param.h"
#include "memlayout.h"
#include "spinlock.h"
#include "riscv.h"
#include "defs.h"

void freerange(void *pa_start, void *pa_end);

extern char end[]; // first address after kernel.
                   // defined by kernel.ld.

struct run
{
  struct run *next;
};

struct
{
  struct spinlock lock;
  struct run *freelist;
} kmem;

// Array to track reference counts for each physical page
int reference_counters[PHYSTOP / PGSIZE];

// Spinlock to protect the reference_counters array
struct spinlock ref_lock;

void kinit()
{
  initlock(&kmem.lock, "kmem");
  initlock(&ref_lock, "ref_lock"); // Initialize the reference counter lock
  freerange(end, (void *)PHYSTOP);
}

void freerange(void *pa_start, void *pa_end)
{
  char *p;
  p = (char *)PGROUNDUP((uint64)pa_start);
  for (; p + PGSIZE <= (char *)pa_end; p += PGSIZE)
  {

    acquire(&ref_lock);
    reference_counters[((uint64)p) / PGSIZE] = 0;
    // remember to change it to 1 if not working, Im assuming its a garbage value
    release(&ref_lock);

    kfree(p);
  }
}

// Free the page of physical memory pointed at by pa,
// which normally should have been returned by a
// call to kalloc().  (The exception is when
// initializing the allocator; see kinit above.)
void kfree(void *pa)
{
  struct run *r;

  if (((uint64)pa % PGSIZE) != 0 || (char *)pa < end || (uint64)pa >= PHYSTOP)
    panic("kfree");

  acquire(&ref_lock);

  // Decrement the reference count for the page

  // Only proceed to free if the reference count is zero
  if (reference_counters[(uint64)pa / PGSIZE] > 1)
  {
    reference_counters[(uint64)pa / PGSIZE]--;
    release(&ref_lock);
    return;
  }

  reference_counters[(uint64)pa / PGSIZE] = 0;
  release(&ref_lock);

  memset(pa, 1, PGSIZE);

  r = (struct run *)pa;

  acquire(&kmem.lock);
  r->next = kmem.freelist;
  kmem.freelist = r;
  release(&kmem.lock);
}

// Allocate one 4096-byte page of physical memory.
// Returns a pointer that the kernel can use.
// Returns 0 if the memory cannot be allocated.
void *
kalloc(void)
{
  struct run *r;

  acquire(&kmem.lock);
  r = kmem.freelist;
  if (r)
    kmem.freelist = r->next;
  release(&kmem.lock);

  if (r)
  {
    memset((char *)r, 5, PGSIZE); // fill with junk

    acquire(&ref_lock);                         // Acquire the lock for thread safety
    reference_counters[(uint64)r / PGSIZE] = 1; // Set the reference count to 1
    release(&ref_lock);                         // Release the lock
  }
  return (void *)r;
}
